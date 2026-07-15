import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../user_roles.dart';
import 'database.dart';

/// Reads/writes the normalized PostgreSQL schema (`migrations/0001_init.sql`)
/// on behalf of [Store], reconstructing/flattening the exact nested JSON
/// shape produced by `buildProjectsSeed()` so the in-memory `Store` model
/// (`List<Map<String, dynamic>> projects`/`leads`) never has to change
/// shape depending on whether persistence is active.
class PgPersistence {
  PgPersistence(this._db);

  final Database _db;

  /// Runs [fn] inside a transaction whose RLS context is the `service`
  /// role, scoped to that transaction only (`set_config(..., true)`).
  ///
  /// Write-through calls are fire-and-forget (`unawaited` in [Store]), so by
  /// the time they hit the shared connection the per-request context set by
  /// `authMiddleware` may already belong to a different caller — which made
  /// FORCE-RLS tables (users, sessions, developers, subscriptions,
  /// favorites, saved_searches, audit_log) reject writes intermittently.
  /// Every such write mirrors an in-memory mutation that was already
  /// authorized by the route layer, so `service` is the correct identity
  /// here; the transaction-local scope means the ambient request context is
  /// untouched.
  Future<T> _asService<T>(Future<T> Function(Session session) fn) =>
      _db.runTx((tx) async {
        await tx.execute(
          "SELECT set_config('app.role', 'service', true), "
          "set_config('app.user_id', '', true)",
        );
        return fn(tx);
      });

  // --- Read path ----------------------------------------------------------

  /// Whether the projects table has zero rows (runs as `service` so FORCE RLS
  /// cannot hide unpublished rows and fake an "empty" database).
  Future<bool> isEmpty() => _asService((s) async {
    final result = await s.execute('SELECT COUNT(*) FROM projects');
    final count = result.first.first;
    return (count as int) == 0;
  });

  /// First-boot catalogue seed gate. Unlike [isEmpty], this stays false after
  /// an admin wipes every complex — see migration
  /// `0014_rls_write_isolation_and_seed_guard.sql` (`app_meta.catalogue_seeded`).
  Future<bool> needsCatalogueSeed() => _asService((s) async {
    final flagged = await s.execute(
      Sql.named("SELECT value FROM app_meta WHERE key = 'catalogue_seeded'"),
    );
    if (flagged.isNotEmpty) return false;
    final result = await s.execute('SELECT COUNT(*) FROM projects');
    return (result.first.first as int) == 0;
  });

  Future<void> markCatalogueSeeded() => _asService(
    (s) => s.execute(
      Sql.named('''
        INSERT INTO app_meta (key, value, updated_at)
        VALUES ('catalogue_seeded', 'true', now())
        ON CONFLICT (key) DO UPDATE SET
          value = EXCLUDED.value,
          updated_at = now()
      '''),
    ),
  );

  /// Loads every project (including unpublished). Caller must have set
  /// `app.role=service` (or `system_admin`) — typically [Store.create] via
  /// [setRequestContext] — because FORCE RLS would otherwise hide drafts.
  Future<List<Map<String, dynamic>>> loadAllProjects() async {
    final projectRows = await _db.execute('''
      SELECT p.*,
             d.id AS dev_id, d.name AS dev_name, d.logo_url AS dev_logo_url,
             d.rating AS dev_rating, d.projects_count AS dev_projects_count,
             d.phone AS dev_phone, d.agent_name AS dev_agent_name,
             d.agent_phone AS dev_agent_phone,
             d.agent_avatar_url AS dev_agent_avatar_url
      FROM projects p
      LEFT JOIN developers d ON d.id = p.developer_id
      ORDER BY p.sort_order
    ''');

    final galleryByProject = await _mediaByOwner('project_id');
    final unitMediaByUnit = await _mediaByOwner('unit_id');
    final offersByProject = <String, List<Map<String, dynamic>>>{};
    for (final row in await _db.execute(
      'SELECT * FROM offers ORDER BY project_id, id',
    )) {
      final offer = _offerFromRow(row.toColumnMap());
      (offersByProject[offer['projectId'] as String] ??= []).add(offer);
    }

    final unitsByBuilding = <String, List<Map<String, dynamic>>>{};
    for (final row in await _db.execute(
      'SELECT * FROM units ORDER BY building_id, sort_order',
    )) {
      final unitRow = row.toColumnMap();
      final unit = _unitFromRow(
        unitRow,
        unitMediaByUnit[unitRow['id'] as String] ?? const [],
      );
      (unitsByBuilding[unitRow['building_id'] as String] ??= []).add(unit);
    }

    final buildingsByProject = <String, List<Map<String, dynamic>>>{};
    for (final row in await _db.execute(
      'SELECT * FROM buildings ORDER BY project_id, sort_order',
    )) {
      final buildingRow = row.toColumnMap();
      final building = _buildingFromRow(
        buildingRow,
        unitsByBuilding[buildingRow['id'] as String] ?? const [],
      );
      (buildingsByProject[buildingRow['project_id'] as String] ??= []).add(
        building,
      );
    }

    return projectRows.map((row) {
      final map = row.toColumnMap();
      final projectId = map['id'] as String;
      return _projectFromRow(
        map,
        developer: _developerFromRow(map),
        gallery: galleryByProject[projectId] ?? const [],
        buildings: buildingsByProject[projectId] ?? const [],
        offers: offersByProject[projectId] ?? const [],
      );
    }).toList();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _mediaByOwner(
    String ownerColumn,
  ) async {
    final rows = await _db.execute(
      'SELECT * FROM media WHERE $ownerColumn IS NOT NULL '
      'ORDER BY $ownerColumn, sort_order',
    );
    final byOwner = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final map = row.toColumnMap();
      final ownerId = map[ownerColumn] as String;
      (byOwner[ownerId] ??= []).add(_mediaFromRow(map));
    }
    return byOwner;
  }

  Future<List<Map<String, dynamic>>> loadAllLeads() async {
    final rows = await _db.execute(
      'SELECT * FROM leads ORDER BY created_at DESC',
    );
    return rows.map((r) => _leadFromRow(r.toColumnMap())).toList();
  }

  // --- Write path (seeding) ------------------------------------------------

  /// Inserts the full seeded dataset (as built by `buildProjectsSeed()`)
  /// into the normalized tables inside a single transaction, then marks the
  /// catalogue as seeded so a later wipe is not undone on restart.
  Future<void> seedFrom(List<Map<String, dynamic>> projects) async {
    await _db.runTx((tx) async {
      await tx.execute(
        "SELECT set_config('app.role', 'service', true), "
        "set_config('app.user_id', '', true)",
      );
      for (var pIndex = 0; pIndex < projects.length; pIndex++) {
        final project = projects[pIndex];
        final developer = project['developer'] as Map<String, dynamic>;
        await _upsertCatalogueDeveloper(tx, developer);
        await _upsertProject(tx, project, pIndex);

        final gallery = (project['gallery'] as List)
            .cast<Map<String, dynamic>>();
        for (final media in gallery) {
          await _upsertMedia(tx, media, projectId: project['id'] as String);
        }

        final offers = (project['offers'] as List).cast<Map<String, dynamic>>();
        for (final offer in offers) {
          await _upsertOffer(tx, offer);
        }

        final buildings = (project['buildings'] as List)
            .cast<Map<String, dynamic>>();
        for (var bIndex = 0; bIndex < buildings.length; bIndex++) {
          final building = buildings[bIndex];
          await _upsertBuilding(tx, building, bIndex);

          final units = (building['units'] as List)
              .cast<Map<String, dynamic>>();
          for (var uIndex = 0; uIndex < units.length; uIndex++) {
            final unit = units[uIndex];
            await _upsertUnit(
              tx,
              unit,
              projectId: project['id'] as String,
              sortOrder: uIndex,
            );
            final unitMedia = (unit['media'] as List)
                .cast<Map<String, dynamic>>();
            for (final media in unitMedia) {
              await _upsertMedia(tx, media, unitId: unit['id'] as String);
            }
          }
        }
      }
      await tx.execute(
        Sql.named('''
          INSERT INTO app_meta (key, value, updated_at)
          VALUES ('catalogue_seeded', 'true', now())
          ON CONFLICT (key) DO UPDATE SET
            value = EXCLUDED.value,
            updated_at = now()
        '''),
      );
    });
  }

  /// First-boot seeding for the demo reviews and rental listings. Their
  /// `user_id`/`owner_user_id` FKs require user rows, so placeholder users
  /// (with synthetic, non-routable phone numbers) are created first.
  Future<void> seedAuxiliary({
    required List<Map<String, dynamic>> reviews,
    required List<Map<String, dynamic>> rentalListings,
  }) async {
    final nameByUserId = <String, String?>{
      for (final l in rentalListings) l['ownerUserId'] as String: null,
      for (final r in reviews) r['userId'] as String: r['userName'] as String?,
    };
    var counter = 0;
    for (final entry in nameByUserId.entries) {
      counter++;
      await upsertUser({
        'id': entry.key,
        'phone': '+998000000${counter.toString().padLeft(3, '0')}',
        'name': entry.value,
        'role': UserRole.ordinaryUser,
      });
    }
    for (final review in reviews) {
      await saveReview(review);
    }
    for (final listing in rentalListings) {
      await saveRentalListing(listing);
    }
  }

  // --- Write-through path (project inventory mutations) --------------------

  /// Sort order used for user-created projects: negative seconds-since-epoch
  /// so `ORDER BY sort_order` puts the newest first, before the seed
  /// catalogue (0..N) — matching the in-memory `projects.insert(0, ...)`.
  static int _newestFirstSortOrder() =>
      -(DateTime.now().millisecondsSinceEpoch ~/ 1000);

  /// Upserts one project row (not its nested buildings/units/media/offers —
  /// those have their own save methods called by their own mutations).
  ///
  /// Runs as the `service` role (see [_asService]): `projects` is FORCE-RLS
  /// (migration `0012_rls_core_tables.sql`) and this write-through is
  /// fire-and-forget, so the ambient per-request context set by
  /// `authMiddleware` may belong to a different caller by the time this
  /// executes — same rationale as the other FORCE-RLS tables above.
  Future<void> saveProject(Map<String, dynamic> project) =>
      _asService((s) => _upsertProject(s, project, _newestFirstSortOrder()));

  /// Hard-deletes a project row (and cascaded inventory / favorites / leads).
  /// Runs as `service` so FORCE-RLS write policies cannot silently no-op the
  /// DELETE (0 rows, no error) the way a stale per-request `app.role` would.
  Future<void> deleteProject(String projectId) => _asService((s) async {
    // Pre-FK cleanup is still useful if migration 0014 has not applied yet.
    await s.execute(
      Sql.named('DELETE FROM favorites WHERE project_id = @id'),
      parameters: {'id': TypedValue(Type.text, projectId)},
    );
    await s.execute(
      Sql.named('DELETE FROM leads WHERE project_id = @id'),
      parameters: {'id': TypedValue(Type.text, projectId)},
    );
    final deleted = await s.execute(
      Sql.named('DELETE FROM projects WHERE id = @id'),
      parameters: {'id': TypedValue(Type.text, projectId)},
    );
    if (deleted.affectedRows == 0) {
      final still = await s.execute(
        Sql.named('SELECT 1 FROM projects WHERE id = @id'),
        parameters: {'id': TypedValue(Type.text, projectId)},
      );
      if (still.isNotEmpty) {
        throw StateError(
          'RLS blocked DELETE for project $projectId '
          '(row still present after DELETE)',
        );
      }
    }
  });

  Future<void> saveBuilding(
    Map<String, dynamic> building, {
    required int sortOrder,
  }) => _asService((s) => _upsertBuilding(s, building, sortOrder));

  Future<void> saveUnit(
    Map<String, dynamic> unit, {
    required String projectId,
    required int sortOrder,
  }) => _asService(
    (s) => _upsertUnit(s, unit, projectId: projectId, sortOrder: sortOrder),
  );

  Future<void> saveUnitMedia(
    Map<String, dynamic> media, {
    required String unitId,
  }) => _asService((s) => _upsertMedia(s, media, unitId: unitId));

  /// `PUT` semantics matching `Store.setProjectOffers`: replaces the
  /// project's offers wholesale.
  Future<void> replaceProjectOffers(
    String projectId,
    List<Map<String, dynamic>> offers,
  ) => _asService((tx) async {
    await tx.execute(
      Sql.named('DELETE FROM offers WHERE project_id = @projectId'),
      parameters: {'projectId': TypedValue(Type.text, projectId)},
    );
    for (final offer in offers) {
      await _upsertOffer(tx, offer);
    }
  });

  // --- Reviews --------------------------------------------------------------

  Future<List<Map<String, dynamic>>> loadAllReviews() async {
    final rows = await _db.execute(
      'SELECT * FROM reviews ORDER BY created_at DESC',
    );
    return rows.map((r) {
      final m = r.toColumnMap();
      return <String, dynamic>{
        'id': m['id'],
        'userId': m['user_id'],
        'userName': m['user_name'],
        'projectId': m['project_id'],
        'developerId': m['developer_id'],
        'ratingOverall': m['rating_overall'],
        'ratingLocation': m['rating_location'],
        'ratingQuality': m['rating_quality'],
        'ratingValue': m['rating_value'],
        'body': m['body'],
        'status': m['status'],
        'createdAt': (m['created_at'] as DateTime).toIso8601String(),
      };
    }).toList();
  }

  Future<void> saveReview(Map<String, dynamic> review) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO reviews (
          id, user_id, user_name, project_id, developer_id, rating_overall,
          rating_location, rating_quality, rating_value, body, status,
          created_at
        ) VALUES (
          @id, @userId, @userName, @projectId, @developerId, @ratingOverall,
          @ratingLocation, @ratingQuality, @ratingValue, @body, @status,
          COALESCE(@createdAt::timestamptz, now())
        )
        ON CONFLICT (id) DO UPDATE SET
          user_name = EXCLUDED.user_name,
          rating_overall = EXCLUDED.rating_overall,
          rating_location = EXCLUDED.rating_location,
          rating_quality = EXCLUDED.rating_quality,
          rating_value = EXCLUDED.rating_value,
          body = EXCLUDED.body,
          status = EXCLUDED.status
      '''),
      parameters: {
        'id': TypedValue(Type.text, review['id'] as String),
        'userId': TypedValue(Type.text, review['userId'] as String),
        'userName': TypedValue(Type.text, review['userName'] as String?),
        'projectId': TypedValue(Type.text, review['projectId'] as String),
        'developerId': TypedValue(Type.text, review['developerId'] as String?),
        'ratingOverall': TypedValue(
          Type.integer,
          review['ratingOverall'] as int? ?? 5,
        ),
        'ratingLocation': TypedValue(
          Type.integer,
          review['ratingLocation'] as int?,
        ),
        'ratingQuality': TypedValue(
          Type.integer,
          review['ratingQuality'] as int?,
        ),
        'ratingValue': TypedValue(Type.integer, review['ratingValue'] as int?),
        'body': TypedValue(Type.text, review['body'] as String? ?? ''),
        'status': TypedValue(
          Type.text,
          review['status'] as String? ?? 'published',
        ),
        'createdAt': TypedValue(Type.text, review['createdAt'] as String?),
      },
    );
  }

  // --- Rental listings -------------------------------------------------------

  Future<List<Map<String, dynamic>>> loadAllRentalListings() async {
    final photosByListing = <String, List<String>>{};
    for (final row in await _db.execute(
      'SELECT rental_listing_id, url FROM rental_listing_photos '
      'ORDER BY rental_listing_id, sort_order',
    )) {
      final m = row.toColumnMap();
      (photosByListing[m['rental_listing_id'] as String] ??= []).add(
        m['url'] as String,
      );
    }
    final rows = await _db.execute(
      'SELECT * FROM rental_listings ORDER BY created_at DESC',
    );
    return rows.map((r) {
      final m = r.toColumnMap();
      return <String, dynamic>{
        'id': m['id'],
        'ownerUserId': m['owner_user_id'],
        'title': m['title'],
        'description': m['description'],
        'district': m['district'],
        'address': m['address'],
        'lat': m['lat'],
        'lng': m['lng'],
        'propertyKind': m['property_kind'],
        'dealType': m['deal_type'],
        'areaTotal': m['area_total'],
        'rooms': m['rooms'],
        'rentMonthly': m['rent_monthly'],
        'minLeaseMonths': m['min_lease_months'],
        'contactPhone': m['contact_phone'],
        'photos': photosByListing[m['id'] as String] ?? const <String>[],
        'isSecondary': m['is_secondary'],
        'isFeatured': m['is_featured'],
        'moderationStatus': m['moderation_status'],
        'moderationNote': m['moderation_note'],
        'createdAt': (m['created_at'] as DateTime).toIso8601String(),
      };
    }).toList();
  }

  Future<void> saveRentalListing(Map<String, dynamic> listing) async {
    final id = listing['id'] as String;
    await _db.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          INSERT INTO rental_listings (
            id, owner_user_id, title, description, district, address, lat,
            lng, property_kind, deal_type, area_total, rooms, rent_monthly,
            min_lease_months, contact_phone, is_secondary, is_featured,
            moderation_status, moderation_note, created_at
          ) VALUES (
            @id, @ownerUserId, @title, @description, @district, @address,
            @lat, @lng, @propertyKind, 'rent', @areaTotal, @rooms,
            @rentMonthly, @minLeaseMonths, @contactPhone, @isSecondary,
            @isFeatured, @moderationStatus, @moderationNote,
            COALESCE(@createdAt::timestamptz, now())
          )
          ON CONFLICT (id) DO UPDATE SET
            title = EXCLUDED.title,
            description = EXCLUDED.description,
            district = EXCLUDED.district,
            address = EXCLUDED.address,
            lat = EXCLUDED.lat,
            lng = EXCLUDED.lng,
            property_kind = EXCLUDED.property_kind,
            area_total = EXCLUDED.area_total,
            rooms = EXCLUDED.rooms,
            rent_monthly = EXCLUDED.rent_monthly,
            min_lease_months = EXCLUDED.min_lease_months,
            contact_phone = EXCLUDED.contact_phone,
            is_secondary = EXCLUDED.is_secondary,
            is_featured = EXCLUDED.is_featured,
            moderation_status = EXCLUDED.moderation_status,
            moderation_note = EXCLUDED.moderation_note
        '''),
        parameters: {
          'id': TypedValue(Type.text, id),
          'ownerUserId': TypedValue(
            Type.text,
            listing['ownerUserId'] as String,
          ),
          'title': TypedValue(Type.text, listing['title'] as String? ?? ''),
          'description': TypedValue(
            Type.text,
            listing['description'] as String?,
          ),
          'district': TypedValue(
            Type.text,
            listing['district'] as String? ?? '',
          ),
          'address': TypedValue(Type.text, listing['address'] as String? ?? ''),
          'lat': TypedValue(Type.double, (listing['lat'] as num?)?.toDouble()),
          'lng': TypedValue(Type.double, (listing['lng'] as num?)?.toDouble()),
          'propertyKind': TypedValue(
            Type.text,
            listing['propertyKind'] as String? ?? 'apartment',
          ),
          'areaTotal': TypedValue(
            Type.double,
            (listing['areaTotal'] as num?)?.toDouble() ?? 0,
          ),
          'rooms': TypedValue(Type.integer, listing['rooms'] as int?),
          'rentMonthly': TypedValue(
            Type.double,
            (listing['rentMonthly'] as num?)?.toDouble() ?? 0,
          ),
          'minLeaseMonths': TypedValue(
            Type.integer,
            listing['minLeaseMonths'] as int? ?? 12,
          ),
          'contactPhone': TypedValue(
            Type.text,
            listing['contactPhone'] as String? ?? '',
          ),
          'isSecondary': TypedValue(
            Type.boolean,
            listing['isSecondary'] as bool? ?? true,
          ),
          'isFeatured': TypedValue(
            Type.boolean,
            listing['isFeatured'] as bool? ?? false,
          ),
          'moderationStatus': TypedValue(
            Type.text,
            listing['moderationStatus'] as String? ?? 'pending',
          ),
          'moderationNote': TypedValue(
            Type.text,
            listing['moderationNote'] as String?,
          ),
          'createdAt': TypedValue(Type.text, listing['createdAt'] as String?),
        },
      );
      await tx.execute(
        Sql.named(
          'DELETE FROM rental_listing_photos WHERE rental_listing_id = @id',
        ),
        parameters: {'id': TypedValue(Type.text, id)},
      );
      final photos = (listing['photos'] as List?)?.cast<String>() ?? const [];
      for (var i = 0; i < photos.length; i++) {
        await tx.execute(
          Sql.named('''
            INSERT INTO rental_listing_photos (id, rental_listing_id, url, sort_order)
            VALUES (@photoId, @listingId, @url, @sortOrder)
          '''),
          parameters: {
            'photoId': TypedValue(Type.text, '$id-photo-$i'),
            'listingId': TypedValue(Type.text, id),
            'url': TypedValue(Type.text, photos[i]),
            'sortOrder': TypedValue(Type.integer, i),
          },
        );
      }
    });
  }

  // --- Favorites / saved searches -------------------------------------------

  Future<Map<String, Set<String>>> loadAllFavorites() async {
    final rows = await _db.execute('SELECT user_id, project_id FROM favorites');
    final byUser = <String, Set<String>>{};
    for (final row in rows) {
      final m = row.toColumnMap();
      (byUser[m['user_id'] as String] ??= {}).add(m['project_id'] as String);
    }
    return byUser;
  }

  Future<void> saveFavorite(String userId, String projectId) async {
    await _asService(
      (s) => s.execute(
        Sql.named('''
          INSERT INTO favorites (user_id, project_id)
          VALUES (@userId, @projectId)
          ON CONFLICT (user_id, project_id) DO NOTHING
        '''),
        parameters: {
          'userId': TypedValue(Type.text, userId),
          'projectId': TypedValue(Type.text, projectId),
        },
      ),
    );
  }

  Future<void> deleteFavorite(String userId, String projectId) async {
    await _asService(
      (s) => s.execute(
        Sql.named(
          'DELETE FROM favorites '
          'WHERE user_id = @userId AND project_id = @projectId',
        ),
        parameters: {
          'userId': TypedValue(Type.text, userId),
          'projectId': TypedValue(Type.text, projectId),
        },
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> loadAllSavedSearches() async {
    final rows = await _db.execute(
      'SELECT * FROM saved_searches ORDER BY created_at DESC',
    );
    final byUser = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final m = row.toColumnMap();
      Map<String, dynamic> filters;
      try {
        filters =
            jsonDecode(m['filters_json'] as String? ?? '{}')
                as Map<String, dynamic>;
      } on FormatException {
        filters = <String, dynamic>{};
      }
      (byUser[m['user_id'] as String] ??= []).add({
        'id': m['id'],
        'label': m['label'],
        'filters': filters,
        'notifyOnMatch': m['notify_on_match'],
        'createdAt': (m['created_at'] as DateTime).toIso8601String(),
      });
    }
    return byUser;
  }

  Future<void> saveSavedSearch(
    String userId,
    Map<String, dynamic> search,
  ) async {
    await _asService(
      (s) => s.execute(
        Sql.named('''
          INSERT INTO saved_searches (
            id, user_id, label, filters_json, notify_on_match, created_at
          ) VALUES (
            @id, @userId, @label, @filtersJson, @notifyOnMatch,
            COALESCE(@createdAt::timestamptz, now())
          )
          ON CONFLICT (id) DO UPDATE SET
            label = EXCLUDED.label,
            filters_json = EXCLUDED.filters_json,
            notify_on_match = EXCLUDED.notify_on_match
        '''),
        parameters: {
          'id': TypedValue(Type.text, search['id'] as String),
          'userId': TypedValue(Type.text, userId),
          'label': TypedValue(Type.text, search['label'] as String? ?? ''),
          'filtersJson': TypedValue(
            Type.text,
            jsonEncode(search['filters'] ?? const <String, dynamic>{}),
          ),
          'notifyOnMatch': TypedValue(
            Type.boolean,
            search['notifyOnMatch'] as bool? ?? false,
          ),
          'createdAt': TypedValue(Type.text, search['createdAt'] as String?),
        },
      ),
    );
  }

  Future<void> deleteSavedSearch(String userId, String id) async {
    await _asService(
      (s) => s.execute(
        Sql.named(
          'DELETE FROM saved_searches WHERE id = @id AND user_id = @userId',
        ),
        parameters: {
          'id': TypedValue(Type.text, id),
          'userId': TypedValue(Type.text, userId),
        },
      ),
    );
  }

  // --- Audit log --------------------------------------------------------------

  Future<List<Map<String, dynamic>>> loadAuditLog({int limit = 1000}) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT * FROM audit_log ORDER BY created_at DESC LIMIT @limit',
      ),
      parameters: {'limit': TypedValue(Type.integer, limit)},
    );
    return rows.map((r) {
      final m = r.toColumnMap();
      return <String, dynamic>{
        'id': m['id'],
        'actorUserId': m['actor_user_id'],
        'action': m['action'],
        'targetType': m['target_type'],
        'targetId': m['target_id'],
        'detail': m['detail'],
        'createdAt': (m['created_at'] as DateTime).toIso8601String(),
      };
    }).toList();
  }

  Future<void> saveAuditEntry(Map<String, dynamic> entry) async {
    await _asService(
      (s) => s.execute(
        Sql.named('''
          INSERT INTO audit_log (
            id, actor_user_id, action, target_type, target_id, detail,
            created_at
          ) VALUES (
            @id, @actorUserId, @action, @targetType, @targetId, @detail,
            COALESCE(@createdAt::timestamptz, now())
          )
          ON CONFLICT (id) DO NOTHING
        '''),
        parameters: {
          'id': TypedValue(Type.text, entry['id'] as String),
          'actorUserId': TypedValue(Type.text, entry['actorUserId'] as String?),
          'action': TypedValue(Type.text, entry['action'] as String? ?? ''),
          'targetType': TypedValue(Type.text, entry['targetType'] as String?),
          'targetId': TypedValue(Type.text, entry['targetId'] as String?),
          'detail': TypedValue(Type.text, entry['detail'] as String?),
          'createdAt': TypedValue(Type.text, entry['createdAt'] as String?),
        },
      ),
    );
  }

  // --- Write-through path (mutations) --------------------------------------

  Future<List<Map<String, dynamic>>> loadAllTickets() async {
    final rows = await _db.execute(
      'SELECT * FROM tickets ORDER BY updated_at DESC',
    );
    return rows.map((r) => _ticketFromRow(r.toColumnMap())).toList();
  }

  Map<String, dynamic> _ticketFromRow(Map<String, dynamic> m) {
    List<dynamic> replies;
    try {
      replies = jsonDecode(m['replies_json'] as String? ?? '[]') as List;
    } on FormatException {
      replies = const [];
    }
    return <String, dynamic>{
      'id': m['id'],
      'userId': m['user_id'],
      'userName': m['user_name'],
      'userPhone': m['user_phone'],
      'subject': m['subject'],
      'category': m['category'],
      'status': m['status'],
      'assignedToName': m['assigned_to_name'],
      'replies': replies.cast<Map<String, dynamic>>(),
      'createdAt': (m['created_at'] as DateTime).toIso8601String(),
      'updatedAt': (m['updated_at'] as DateTime).toIso8601String(),
    };
  }

  Future<void> saveTicket(Map<String, dynamic> ticket) async {
    await _asService(
      (s) => s.execute(
        Sql.named('''
          INSERT INTO tickets (
            id, user_id, user_name, user_phone, subject, category, status,
            assigned_to_name, replies_json, created_at, updated_at
          ) VALUES (
            @id, @userId, @userName, @userPhone, @subject, @category, @status,
            @assignedToName, @repliesJson,
            COALESCE(@createdAt::timestamptz, now()), now()
          )
          ON CONFLICT (id) DO UPDATE SET
            status = EXCLUDED.status,
            assigned_to_name = EXCLUDED.assigned_to_name,
            replies_json = EXCLUDED.replies_json,
            updated_at = now()
        '''),
        parameters: {
          'id': TypedValue(Type.text, ticket['id'] as String),
          'userId': TypedValue(Type.text, ticket['userId'] as String),
          'userName': TypedValue(Type.text, ticket['userName'] as String?),
          'userPhone': TypedValue(Type.text, ticket['userPhone'] as String?),
          'subject': TypedValue(Type.text, ticket['subject'] as String? ?? ''),
          'category': TypedValue(
            Type.text,
            ticket['category'] as String? ?? 'other',
          ),
          'status': TypedValue(Type.text, ticket['status'] as String? ?? 'open'),
          'assignedToName': TypedValue(
            Type.text,
            ticket['assignedToName'] as String?,
          ),
          'repliesJson': TypedValue(
            Type.text,
            jsonEncode(ticket['replies'] ?? const <Map<String, dynamic>>[]),
          ),
          'createdAt': TypedValue(Type.text, ticket['createdAt'] as String?),
        },
      ),
    );
  }

  // --- Write-through path (mutations) --------------------------------------

  /// `leads` is FORCE-RLS as of migration `0012_rls_core_tables.sql`; see
  /// [saveProject] for why write-throughs run as `service`.
  Future<void> saveLead(Map<String, dynamic> lead) => _asService(
    (s) => s.execute(
      Sql.named('''
        INSERT INTO leads (
          id, number, project_id, project_name, unit_id, unit_label, intent,
          status, contact_phone, message, preferred_at, created_at,
          user_id, owner_user_id, assigned_manager, notes, tags, score,
          last_contact_at
        ) VALUES (
          @id, @number, @projectId, @projectName, @unitId, @unitLabel, @intent,
          @status, @contactPhone, @message, @preferredAt, @createdAt,
          @userId, @ownerUserId, @assignedManager, @notes, @tags, @score,
          @lastContactAt
        )
        ON CONFLICT (id) DO UPDATE SET
          number = EXCLUDED.number,
          project_id = EXCLUDED.project_id,
          project_name = EXCLUDED.project_name,
          unit_id = EXCLUDED.unit_id,
          unit_label = EXCLUDED.unit_label,
          intent = EXCLUDED.intent,
          status = EXCLUDED.status,
          contact_phone = EXCLUDED.contact_phone,
          message = EXCLUDED.message,
          preferred_at = EXCLUDED.preferred_at,
          created_at = EXCLUDED.created_at,
          user_id = EXCLUDED.user_id,
          owner_user_id = EXCLUDED.owner_user_id,
          assigned_manager = EXCLUDED.assigned_manager,
          notes = EXCLUDED.notes,
          tags = EXCLUDED.tags,
          score = EXCLUDED.score,
          last_contact_at = EXCLUDED.last_contact_at
      '''),
      parameters: {
        'id': TypedValue(Type.text, lead['id'] as String),
        'number': TypedValue(Type.text, lead['number'] as String),
        'projectId': TypedValue(Type.text, lead['projectId'] as String? ?? ''),
        'projectName': TypedValue(Type.text, lead['projectName'] as String?),
        'unitId': TypedValue(Type.text, lead['unitId'] as String?),
        'unitLabel': TypedValue(Type.text, lead['unitLabel'] as String?),
        'intent': TypedValue(Type.text, lead['intent'] as String? ?? ''),
        'status': TypedValue(Type.text, lead['status'] as String? ?? 'new'),
        'contactPhone': TypedValue(Type.text, lead['contactPhone'] as String?),
        'message': TypedValue(Type.text, lead['message'] as String?),
        'preferredAt': TypedValue(
          Type.timestampTz,
          _parseDate(lead['preferredAt']),
        ),
        'createdAt': TypedValue(
          Type.timestampTz,
          _parseDate(lead['createdAt']) ?? DateTime.now(),
        ),
        'userId': TypedValue(Type.text, lead['userId'] as String?),
        'ownerUserId': TypedValue(Type.text, lead['ownerUserId'] as String?),
        'assignedManager': TypedValue(
          Type.text,
          lead['assignedManager'] as String?,
        ),
        'notes': TypedValue(Type.text, lead['notes'] as String?),
        'tags': TypedValue(
          Type.textArray,
          (lead['tags'] as List?)?.cast<String>() ?? const <String>[],
        ),
        'score': TypedValue(Type.text, lead['score'] as String?),
        'lastContactAt': TypedValue(
          Type.timestampTz,
          _parseDate(lead['lastContactAt']),
        ),
      },
    ),
  );

  Future<void> saveLeadEvent(Map<String, dynamic> event) => _asService(
    (s) => s.execute(
      Sql.named('''
        INSERT INTO lead_events (
          id, lead_id, actor_user_id, type, from_user_id, to_user_id, detail,
          created_at
        ) VALUES (
          @id, @leadId, @actorUserId, @type, @fromUserId, @toUserId, @detail,
          @createdAt
        )
        ON CONFLICT (id) DO NOTHING
      '''),
      parameters: {
        'id': TypedValue(Type.text, event['id'] as String),
        'leadId': TypedValue(Type.text, event['leadId'] as String),
        'actorUserId': TypedValue(Type.text, event['actorUserId'] as String?),
        'type': TypedValue(Type.text, event['type'] as String),
        'fromUserId': TypedValue(Type.text, event['fromUserId'] as String?),
        'toUserId': TypedValue(Type.text, event['toUserId'] as String?),
        'detail': TypedValue(Type.text, event['detail'] as String?),
        'createdAt': TypedValue(
          Type.timestampTz,
          _parseDate(event['createdAt']) ?? DateTime.now(),
        ),
      },
    ),
  );

  Future<List<Map<String, dynamic>>> loadLeadEvents(String leadId) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT * FROM lead_events WHERE lead_id = @leadId ORDER BY created_at DESC',
      ),
      parameters: {'leadId': TypedValue(Type.text, leadId)},
    );
    return rows.map((r) => _leadEventFromRow(r.toColumnMap())).toList();
  }

  Map<String, dynamic> _leadEventFromRow(Map<String, dynamic> row) => {
    'id': row['id'],
    'leadId': row['lead_id'],
    'actorUserId': row['actor_user_id'],
    'type': row['type'],
    'fromUserId': row['from_user_id'],
    'toUserId': row['to_user_id'],
    'detail': row['detail'],
    'createdAt': (row['created_at'] as DateTime).toIso8601String(),
  };

  Future<void> updateLeadStatus(String id, String status) => _asService(
    (s) => s.execute(
      Sql.named('UPDATE leads SET status = @status WHERE id = @id'),
      parameters: {
        'status': TypedValue(Type.text, status),
        'id': TypedValue(Type.text, id),
      },
    ),
  );

  /// `units` is FORCE-RLS as of migration `0012_rls_core_tables.sql`; see
  /// [saveProject] for why write-throughs run as `service`.
  Future<void> saveUnitStatus(String unitId, String status) => _asService(
    (s) => s.execute(
      Sql.named('UPDATE units SET status = @status WHERE id = @id'),
      parameters: {
        'status': TypedValue(Type.text, status),
        'id': TypedValue(Type.text, unitId),
      },
    ),
  );

  // --- Documents (developer verification / trust layer) -------------------

  Future<List<Map<String, dynamic>>> loadAllDocuments() async {
    final rows = await _db.execute(
      'SELECT * FROM documents ORDER BY created_at DESC',
    );
    return rows.map((r) => _documentFromRow(r.toColumnMap())).toList();
  }

  Map<String, dynamic> _documentFromRow(Map<String, dynamic> m) => {
    'id': m['id'],
    'developerId': m['developer_id'],
    'projectId': m['project_id'],
    'type': m['type'],
    'fileUrl': m['file_url'],
    'status': m['status'],
    'rejectReason': m['reject_reason'],
    'uploadedBy': m['uploaded_by'],
    'createdAt': (m['created_at'] as DateTime).toIso8601String(),
    'reviewedBy': m['reviewed_by'],
    'reviewedAt': (m['reviewed_at'] as DateTime?)?.toIso8601String(),
  };

  Future<void> saveDocument(Map<String, dynamic> doc) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO documents (
          id, developer_id, project_id, type, file_url, status,
          reject_reason, uploaded_by, created_at, reviewed_by, reviewed_at
        ) VALUES (
          @id, @developerId, @projectId, @type, @fileUrl, @status,
          @rejectReason, @uploadedBy, COALESCE(@createdAt::timestamptz, now()),
          @reviewedBy, @reviewedAt::timestamptz
        )
        ON CONFLICT (id) DO UPDATE SET
          status = EXCLUDED.status,
          reject_reason = EXCLUDED.reject_reason,
          reviewed_by = EXCLUDED.reviewed_by,
          reviewed_at = EXCLUDED.reviewed_at
      '''),
      parameters: {
        'id': TypedValue(Type.text, doc['id'] as String),
        'developerId': TypedValue(Type.text, doc['developerId'] as String),
        'projectId': TypedValue(Type.text, doc['projectId'] as String?),
        'type': TypedValue(Type.text, doc['type'] as String),
        'fileUrl': TypedValue(Type.text, doc['fileUrl'] as String),
        'status': TypedValue(Type.text, doc['status'] as String? ?? 'pending'),
        'rejectReason': TypedValue(Type.text, doc['rejectReason'] as String?),
        'uploadedBy': TypedValue(Type.text, doc['uploadedBy'] as String?),
        'createdAt': TypedValue(Type.text, doc['createdAt'] as String?),
        'reviewedBy': TypedValue(Type.text, doc['reviewedBy'] as String?),
        'reviewedAt': TypedValue(Type.text, doc['reviewedAt'] as String?),
      },
    );
  }

  // --- Notifications (admin inbox) -----------------------------------------

  Future<List<Map<String, dynamic>>> loadAllNotifications() async {
    final rows = await _db.execute(
      'SELECT * FROM notifications ORDER BY created_at DESC LIMIT 1000',
    );
    return rows.map((r) => _notificationFromRow(r.toColumnMap())).toList();
  }

  Map<String, dynamic> _notificationFromRow(Map<String, dynamic> m) => {
    'id': m['id'],
    'type': m['type'],
    'title': m['title'],
    'body': m['body'],
    'developerId': m['developer_id'],
    'projectId': m['project_id'],
    'targetType': m['target_type'],
    'targetId': m['target_id'],
    'actorUserId': m['actor_user_id'],
    'isRead': m['is_read'] ?? false,
    'createdAt': (m['created_at'] as DateTime).toIso8601String(),
  };

  Future<void> saveNotification(Map<String, dynamic> n) => _asService(
    (s) => s.execute(
      Sql.named('''
        INSERT INTO notifications (
          id, type, title, body, developer_id, project_id, target_type,
          target_id, actor_user_id, is_read, created_at
        ) VALUES (
          @id, @type, @title, @body, @developerId, @projectId, @targetType,
          @targetId, @actorUserId, @isRead, COALESCE(@createdAt::timestamptz, now())
        )
        ON CONFLICT (id) DO UPDATE SET
          is_read = EXCLUDED.is_read
      '''),
      parameters: {
        'id': TypedValue(Type.text, n['id'] as String),
        'type': TypedValue(Type.text, n['type'] as String? ?? ''),
        'title': TypedValue(Type.text, n['title'] as String? ?? ''),
        'body': TypedValue(Type.text, n['body'] as String?),
        'developerId': TypedValue(Type.text, n['developerId'] as String?),
        'projectId': TypedValue(Type.text, n['projectId'] as String?),
        'targetType': TypedValue(Type.text, n['targetType'] as String?),
        'targetId': TypedValue(Type.text, n['targetId'] as String?),
        'actorUserId': TypedValue(Type.text, n['actorUserId'] as String?),
        'isRead': TypedValue(Type.boolean, n['isRead'] as bool? ?? false),
        'createdAt': TypedValue(Type.text, n['createdAt'] as String?),
      },
    ),
  );

  // --- Photo reports (construction progress) -------------------------------

  Future<List<Map<String, dynamic>>> loadAllPhotoReports() async {
    final rows = await _db.execute(
      'SELECT * FROM photo_reports ORDER BY taken_at DESC, created_at DESC',
    );
    return rows.map((r) => _photoReportFromRow(r.toColumnMap())).toList();
  }

  Map<String, dynamic> _photoReportFromRow(Map<String, dynamic> m) => {
    'id': m['id'],
    'projectId': m['project_id'],
    'buildingId': m['building_id'],
    'photoUrl': m['photo_url'],
    'takenAt': (m['taken_at'] as DateTime).toIso8601String().split('T').first,
    'takenAtIsManual': m['taken_at_is_manual'] ?? false,
    'progressPercent': m['progress_percent'],
    'uploadedBy': m['uploaded_by'],
    'createdAt': (m['created_at'] as DateTime).toIso8601String(),
  };

  Future<void> savePhotoReport(Map<String, dynamic> report) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO photo_reports (
          id, project_id, building_id, photo_url, taken_at,
          taken_at_is_manual, progress_percent, uploaded_by, created_at
        ) VALUES (
          @id, @projectId, @buildingId, @photoUrl, @takenAt::date,
          @takenAtIsManual, @progressPercent, @uploadedBy,
          COALESCE(@createdAt::timestamptz, now())
        )
        ON CONFLICT (id) DO NOTHING
      '''),
      parameters: {
        'id': TypedValue(Type.text, report['id'] as String),
        'projectId': TypedValue(Type.text, report['projectId'] as String),
        'buildingId': TypedValue(Type.text, report['buildingId'] as String?),
        'photoUrl': TypedValue(Type.text, report['photoUrl'] as String),
        'takenAt': TypedValue(Type.text, report['takenAt'] as String),
        'takenAtIsManual': TypedValue(
          Type.boolean,
          report['takenAtIsManual'] as bool? ?? false,
        ),
        'progressPercent': TypedValue(
          Type.integer,
          report['progressPercent'] as int?,
        ),
        'uploadedBy': TypedValue(Type.text, report['uploadedBy'] as String?),
        'createdAt': TypedValue(Type.text, report['createdAt'] as String?),
      },
    );
  }

  Future<void> deletePhotoReport(String id) async {
    await _db.execute(
      Sql.named('DELETE FROM photo_reports WHERE id = @id'),
      parameters: {'id': TypedValue(Type.text, id)},
    );
  }

  // --- Row <-> JSON-shaped map helpers -------------------------------------

  Map<String, dynamic> _developerFromRow(Map<String, dynamic> row) => {
    'id': row['dev_id'],
    'name': row['dev_name'],
    'logoUrl': row['dev_logo_url'],
    'rating': row['dev_rating'],
    'projectsCount': row['dev_projects_count'],
    'phone': row['dev_phone'],
    'agentName': row['dev_agent_name'],
    'agentPhone': row['dev_agent_phone'],
    'agentAvatarUrl': row['dev_agent_avatar_url'],
  };

  Map<String, dynamic> _mediaFromRow(Map<String, dynamic> row) => {
    'id': row['id'],
    'type': row['type'],
    'url': row['url'],
    'sortOrder': row['sort_order'],
    'isCover': row['is_cover'],
  };

  Map<String, dynamic> _offerFromRow(Map<String, dynamic> row) => {
    'id': row['id'],
    'projectId': row['project_id'],
    'type': row['type'],
    'title': row['title'],
    'description': row['description'],
    'startsAt': (row['starts_at'] as DateTime?)?.toIso8601String(),
    'endsAt': (row['ends_at'] as DateTime?)?.toIso8601String(),
    'downPaymentPercent': row['down_payment_percent'],
    'termMonths': row['term_months'],
    'interestRate': row['interest_rate'],
  };

  Map<String, dynamic> _unitFromRow(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> media,
  ) => {
    'id': row['id'],
    'buildingId': row['building_id'],
    'number': row['number'],
    'kind': row['kind'],
    'dealType': row['deal_type'],
    'status': row['status'],
    'floor': row['floor'],
    'isOffplan': row['is_offplan'],
    'areaTotal': row['area_total'],
    'areaLiving': row['area_living'],
    'rooms': row['rooms'],
    'layout': row['layout'],
    'price': row['price'],
    'priceM2': row['price_m2'],
    'rentMonthly': row['rent_monthly'],
    'rentM2': row['rent_m2'],
    'minLeaseMonths': row['min_lease_months'],
    'finishing': row['finishing'],
    'view': row['view'],
    'planColumn': row['plan_column'],
    'planRow': row['plan_row'],
    'version': row['version'] ?? 1,
    'media': media,
  };

  Map<String, dynamic> _buildingFromRow(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> units,
  ) => {
    'id': row['id'],
    'projectId': row['project_id'],
    'name': row['name'],
    'floors': row['floors'],
    'constructionProgress': row['construction_progress'],
    'completionDate': (row['completion_date'] as DateTime?)?.toIso8601String(),
    'units': units,
  };

  Map<String, dynamic> _projectFromRow(
    Map<String, dynamic> row, {
    required Map<String, dynamic> developer,
    required List<Map<String, dynamic>> gallery,
    required List<Map<String, dynamic>> buildings,
    required List<Map<String, dynamic>> offers,
  }) => {
    'id': row['id'],
    'name': row['name'],
    'type': row['type'],
    'status': row['status'],
    'district': row['district'],
    'address': row['address'],
    'lat': row['lat'],
    'lng': row['lng'],
    'developer': developer,
    'description': row['description'],
    'amenities': (row['amenities'] as List).cast<String>(),
    'tags': (row['tags'] as List).cast<String>(),
    'priceMin': row['price_min'],
    'priceMax': row['price_max'],
    'rentMin': row['rent_min'],
    'rentMax': row['rent_max'],
    'constructionProgress': row['construction_progress'],
    'completionDate': (row['completion_date'] as DateTime?)?.toIso8601String(),
    'rating': row['rating'],
    'availableUnits': row['available_units'],
    'totalUnits': row['total_units'],
    'isFeatured': row['is_featured'],
    'isPublished': row['is_published'] ?? true,
    'moderationStatus': row['moderation_status'] ?? 'approved',
    'moderationNote': row['moderation_note'],
    'gallery': gallery,
    'buildings': buildings,
    'offers': offers,
  };

  Map<String, dynamic> _leadFromRow(Map<String, dynamic> row) => {
    'id': row['id'],
    'number': row['number'],
    'projectId': row['project_id'],
    'projectName': row['project_name'],
    'unitId': row['unit_id'],
    'unitLabel': row['unit_label'],
    'intent': row['intent'],
    'status': row['status'],
    'contactPhone': row['contact_phone'],
    'message': row['message'],
    'preferredAt': (row['preferred_at'] as DateTime?)?.toIso8601String(),
    'createdAt': (row['created_at'] as DateTime).toIso8601String(),
    'userId': row['user_id'],
    'ownerUserId': row['owner_user_id'],
    'assignedManager': row['assigned_manager'],
    'notes': row['notes'],
    'tags': (row['tags'] as List?)?.cast<String>() ?? const <String>[],
    'score': row['score'],
    'lastContactAt': (row['last_contact_at'] as DateTime?)?.toIso8601String(),
  };

  // --- Upsert helpers shared by seedFrom and the write-through methods -----

  Future<void> _upsertCatalogueDeveloper(
    Session session,
    Map<String, dynamic> dev,
  ) async {
    await session.execute(
      Sql.named('''
        INSERT INTO developers (
          id, name, logo_url, rating, projects_count, phone, agent_name,
          agent_phone, agent_avatar_url
        ) VALUES (
          @id, @name, @logoUrl, @rating, @projectsCount, @phone, @agentName,
          @agentPhone, @agentAvatarUrl
        )
        ON CONFLICT (id) DO NOTHING
      '''),
      parameters: {
        'id': TypedValue(Type.text, dev['id'] as String),
        'name': TypedValue(Type.text, dev['name'] as String),
        'logoUrl': TypedValue(Type.text, dev['logoUrl'] as String?),
        'rating': TypedValue(Type.double, (dev['rating'] as num).toDouble()),
        'projectsCount': TypedValue(Type.integer, dev['projectsCount'] as int),
        'phone': TypedValue(Type.text, dev['phone'] as String),
        'agentName': TypedValue(Type.text, dev['agentName'] as String),
        'agentPhone': TypedValue(Type.text, dev['agentPhone'] as String),
        'agentAvatarUrl': TypedValue(
          Type.text,
          dev['agentAvatarUrl'] as String?,
        ),
      },
    );
  }

  Future<void> _upsertProject(
    Session session,
    Map<String, dynamic> project,
    int sortOrder,
  ) async {
    final developer = project['developer'] as Map<String, dynamic>;
    await session.execute(
      Sql.named('''
        INSERT INTO projects (
          id, name, type, status, district, address, lat, lng, developer_id,
          description, amenities, tags, price_min, price_max, rent_min,
          rent_max, construction_progress, completion_date, rating,
          available_units, total_units, is_featured, sort_order,
          is_published, moderation_status, moderation_note
        ) VALUES (
          @id, @name, @type, @status, @district, @address, @lat, @lng,
          @developerId, @description, @amenities, @tags, @priceMin,
          @priceMax, @rentMin, @rentMax, @constructionProgress,
          @completionDate, @rating, @availableUnits, @totalUnits,
          @isFeatured, @sortOrder, @isPublished, @moderationStatus,
          @moderationNote
        )
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          type = EXCLUDED.type,
          status = EXCLUDED.status,
          district = EXCLUDED.district,
          address = EXCLUDED.address,
          lat = EXCLUDED.lat,
          lng = EXCLUDED.lng,
          description = EXCLUDED.description,
          amenities = EXCLUDED.amenities,
          tags = EXCLUDED.tags,
          price_min = EXCLUDED.price_min,
          price_max = EXCLUDED.price_max,
          rent_min = EXCLUDED.rent_min,
          rent_max = EXCLUDED.rent_max,
          construction_progress = EXCLUDED.construction_progress,
          completion_date = EXCLUDED.completion_date,
          rating = EXCLUDED.rating,
          available_units = EXCLUDED.available_units,
          total_units = EXCLUDED.total_units,
          is_featured = EXCLUDED.is_featured,
          is_published = EXCLUDED.is_published,
          moderation_status = EXCLUDED.moderation_status,
          moderation_note = EXCLUDED.moderation_note
      '''),
      parameters: {
        'id': TypedValue(Type.text, project['id'] as String),
        'name': TypedValue(Type.text, project['name'] as String),
        'type': TypedValue(Type.text, project['type'] as String),
        'status': TypedValue(Type.text, project['status'] as String),
        'district': TypedValue(Type.text, project['district'] as String),
        'address': TypedValue(Type.text, project['address'] as String),
        'lat': TypedValue(Type.double, (project['lat'] as num).toDouble()),
        'lng': TypedValue(Type.double, (project['lng'] as num).toDouble()),
        'developerId': TypedValue(Type.text, developer['id'] as String),
        'description': TypedValue(Type.text, project['description'] as String),
        'amenities': TypedValue(
          Type.textArray,
          (project['amenities'] as List).cast<String>(),
        ),
        'tags': TypedValue(
          Type.textArray,
          (project['tags'] as List).cast<String>(),
        ),
        'priceMin': TypedValue(
          Type.double,
          (project['priceMin'] as num?)?.toDouble(),
        ),
        'priceMax': TypedValue(
          Type.double,
          (project['priceMax'] as num?)?.toDouble(),
        ),
        'rentMin': TypedValue(
          Type.double,
          (project['rentMin'] as num?)?.toDouble(),
        ),
        'rentMax': TypedValue(
          Type.double,
          (project['rentMax'] as num?)?.toDouble(),
        ),
        'constructionProgress': TypedValue(
          Type.integer,
          project['constructionProgress'] as int?,
        ),
        'completionDate': TypedValue(
          Type.timestampTz,
          _parseDate(project['completionDate']),
        ),
        'rating': TypedValue(
          Type.double,
          (project['rating'] as num).toDouble(),
        ),
        'availableUnits': TypedValue(
          Type.integer,
          project['availableUnits'] as int,
        ),
        'totalUnits': TypedValue(Type.integer, project['totalUnits'] as int),
        'isFeatured': TypedValue(Type.boolean, project['isFeatured'] as bool),
        'sortOrder': TypedValue(Type.integer, sortOrder),
        'isPublished': TypedValue(
          Type.boolean,
          project['isPublished'] as bool? ?? true,
        ),
        'moderationStatus': TypedValue(
          Type.text,
          project['moderationStatus'] as String? ?? 'approved',
        ),
        'moderationNote': TypedValue(
          Type.text,
          project['moderationNote'] as String?,
        ),
      },
    );
  }

  Future<void> _upsertBuilding(
    Session session,
    Map<String, dynamic> building,
    int sortOrder,
  ) async {
    await session.execute(
      Sql.named('''
        INSERT INTO buildings (
          id, project_id, name, floors, construction_progress,
          completion_date, sort_order
        ) VALUES (
          @id, @projectId, @name, @floors, @constructionProgress,
          @completionDate, @sortOrder
        )
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          floors = EXCLUDED.floors,
          construction_progress = EXCLUDED.construction_progress,
          completion_date = EXCLUDED.completion_date
      '''),
      parameters: {
        'id': TypedValue(Type.text, building['id'] as String),
        'projectId': TypedValue(Type.text, building['projectId'] as String),
        'name': TypedValue(Type.text, building['name'] as String),
        'floors': TypedValue(Type.integer, (building['floors'] as num).toInt()),
        'constructionProgress': TypedValue(
          Type.integer,
          (building['constructionProgress'] as num?)?.toInt(),
        ),
        'completionDate': TypedValue(
          Type.timestampTz,
          _parseDate(building['completionDate']),
        ),
        'sortOrder': TypedValue(Type.integer, sortOrder),
      },
    );
  }

  Future<void> _upsertUnit(
    Session session,
    Map<String, dynamic> unit, {
    required String projectId,
    required int sortOrder,
  }) async {
    await session.execute(
      Sql.named('''
        INSERT INTO units (
          id, building_id, project_id, number, kind, deal_type, status,
          floor, is_offplan, area_total, area_living, rooms, layout, price,
          price_m2, rent_monthly, rent_m2, min_lease_months, finishing, view,
          plan_column, plan_row, version, sort_order
        ) VALUES (
          @id, @buildingId, @projectId, @number, @kind, @dealType, @status,
          @floor, @isOffplan, @areaTotal, @areaLiving, @rooms, @layout,
          @price, @priceM2, @rentMonthly, @rentM2, @minLeaseMonths,
          @finishing, @view, @planColumn, @planRow, @version, @sortOrder
        )
        ON CONFLICT (id) DO UPDATE SET
          number = EXCLUDED.number,
          kind = EXCLUDED.kind,
          deal_type = EXCLUDED.deal_type,
          status = EXCLUDED.status,
          floor = EXCLUDED.floor,
          is_offplan = EXCLUDED.is_offplan,
          area_total = EXCLUDED.area_total,
          area_living = EXCLUDED.area_living,
          rooms = EXCLUDED.rooms,
          layout = EXCLUDED.layout,
          price = EXCLUDED.price,
          price_m2 = EXCLUDED.price_m2,
          rent_monthly = EXCLUDED.rent_monthly,
          rent_m2 = EXCLUDED.rent_m2,
          min_lease_months = EXCLUDED.min_lease_months,
          finishing = EXCLUDED.finishing,
          view = EXCLUDED.view,
          plan_column = EXCLUDED.plan_column,
          plan_row = EXCLUDED.plan_row,
          version = EXCLUDED.version
      '''),
      parameters: {
        'id': TypedValue(Type.text, unit['id'] as String),
        'buildingId': TypedValue(Type.text, unit['buildingId'] as String),
        'projectId': TypedValue(Type.text, projectId),
        'number': TypedValue(Type.text, unit['number'] as String),
        'kind': TypedValue(Type.text, unit['kind'] as String),
        'dealType': TypedValue(Type.text, unit['dealType'] as String),
        'status': TypedValue(Type.text, unit['status'] as String),
        'floor': TypedValue(Type.integer, (unit['floor'] as num).toInt()),
        'isOffplan': TypedValue(Type.boolean, unit['isOffplan'] as bool),
        'areaTotal': TypedValue(
          Type.double,
          (unit['areaTotal'] as num).toDouble(),
        ),
        'areaLiving': TypedValue(
          Type.double,
          (unit['areaLiving'] as num?)?.toDouble(),
        ),
        'rooms': TypedValue(Type.integer, (unit['rooms'] as num?)?.toInt()),
        'layout': TypedValue(Type.text, unit['layout'] as String?),
        'price': TypedValue(Type.double, (unit['price'] as num?)?.toDouble()),
        'priceM2': TypedValue(
          Type.double,
          (unit['priceM2'] as num?)?.toDouble(),
        ),
        'rentMonthly': TypedValue(
          Type.double,
          (unit['rentMonthly'] as num?)?.toDouble(),
        ),
        'rentM2': TypedValue(Type.double, (unit['rentM2'] as num?)?.toDouble()),
        'minLeaseMonths': TypedValue(
          Type.integer,
          (unit['minLeaseMonths'] as num?)?.toInt(),
        ),
        'finishing': TypedValue(Type.text, unit['finishing'] as String?),
        'view': TypedValue(Type.text, unit['view'] as String?),
        'planColumn': TypedValue(
          Type.integer,
          (unit['planColumn'] as num?)?.toInt(),
        ),
        'planRow': TypedValue(Type.integer, (unit['planRow'] as num?)?.toInt()),
        'version': TypedValue(Type.integer, (unit['version'] as num?)?.toInt() ?? 1),
        'sortOrder': TypedValue(Type.integer, sortOrder),
      },
    );
  }

  Future<void> _upsertMedia(
    Session session,
    Map<String, dynamic> media, {
    String? projectId,
    String? unitId,
  }) async {
    await session.execute(
      Sql.named('''
        INSERT INTO media (id, type, url, sort_order, is_cover, project_id, unit_id)
        VALUES (@id, @type, @url, @sortOrder, @isCover, @projectId, @unitId)
        ON CONFLICT (id) DO UPDATE SET
          type = EXCLUDED.type,
          url = EXCLUDED.url,
          sort_order = EXCLUDED.sort_order,
          is_cover = EXCLUDED.is_cover
      '''),
      parameters: {
        'id': TypedValue(Type.text, media['id'] as String),
        'type': TypedValue(Type.text, media['type'] as String),
        'url': TypedValue(Type.text, media['url'] as String),
        'sortOrder': TypedValue(
          Type.integer,
          (media['sortOrder'] as num).toInt(),
        ),
        'isCover': TypedValue(Type.boolean, media['isCover'] as bool),
        'projectId': TypedValue(Type.text, projectId),
        'unitId': TypedValue(Type.text, unitId),
      },
    );
  }

  Future<void> _upsertOffer(Session session, Map<String, dynamic> offer) async {
    await session.execute(
      Sql.named('''
        INSERT INTO offers (
          id, project_id, type, title, description, starts_at, ends_at,
          down_payment_percent, term_months, interest_rate
        ) VALUES (
          @id, @projectId, @type, @title, @description, @startsAt, @endsAt,
          @downPaymentPercent, @termMonths, @interestRate
        )
        ON CONFLICT (id) DO UPDATE SET
          type = EXCLUDED.type,
          title = EXCLUDED.title,
          description = EXCLUDED.description,
          starts_at = EXCLUDED.starts_at,
          ends_at = EXCLUDED.ends_at,
          down_payment_percent = EXCLUDED.down_payment_percent,
          term_months = EXCLUDED.term_months,
          interest_rate = EXCLUDED.interest_rate
      '''),
      parameters: {
        'id': TypedValue(Type.text, offer['id'] as String),
        'projectId': TypedValue(Type.text, offer['projectId'] as String),
        'type': TypedValue(Type.text, offer['type'] as String),
        'title': TypedValue(Type.text, offer['title'] as String),
        'description': TypedValue(Type.text, offer['description'] as String?),
        'startsAt': TypedValue(Type.timestampTz, _parseDate(offer['startsAt'])),
        'endsAt': TypedValue(Type.timestampTz, _parseDate(offer['endsAt'])),
        'downPaymentPercent': TypedValue(
          Type.double,
          (offer['downPaymentPercent'] as num?)?.toDouble(),
        ),
        'termMonths': TypedValue(
          Type.integer,
          (offer['termMonths'] as num?)?.toInt(),
        ),
        'interestRate': TypedValue(
          Type.double,
          (offer['interestRate'] as num?)?.toDouble(),
        ),
      },
    );
  }

  DateTime? _parseDate(Object? v) =>
      v == null ? null : DateTime.parse(v as String);

  // --- Auth (phone OTP users + sessions) ----------------------------------

  /// Loads every persisted B2C/B2B user into the in-memory auth cache on
  /// startup so repeat sign-ins reuse the same `id`/`role`.
  Future<Map<String, Map<String, dynamic>>> loadAllUsers() async {
    final result = await _db.execute(
      'SELECT id, phone, name, role, banned, ban_reason, banned_by_name, '
      'banned_at FROM users',
    );
    final users = <String, Map<String, dynamic>>{};
    for (final row in result) {
      final map = row.toColumnMap();
      final phone = map['phone'] as String;
      users[phone] = {
        'id': map['id'] as String,
        'phone': phone,
        'name': map['name'] as String?,
        'role': map['role'] as String? ?? UserRole.ordinaryUser,
        'banned': map['banned'] as bool? ?? false,
        'banReason': map['ban_reason'] as String?,
        'bannedByName': map['banned_by_name'] as String?,
        'bannedAt': (map['banned_at'] as DateTime?)?.toIso8601String(),
      };
    }
    return users;
  }

  /// Creates or updates a user row keyed by [phone].
  Future<void> upsertUser(Map<String, dynamic> user) async {
    await _asService(
      (s) => s.execute(
        Sql.named('''
        INSERT INTO users (id, phone, name, role, banned, ban_reason, banned_by_name, banned_at)
        VALUES (@id, @phone, @name, @role, @banned, @banReason, @bannedByName, @bannedAt)
        ON CONFLICT (phone) DO UPDATE SET
          name = EXCLUDED.name,
          role = EXCLUDED.role,
          banned = EXCLUDED.banned,
          ban_reason = EXCLUDED.ban_reason,
          banned_by_name = EXCLUDED.banned_by_name,
          banned_at = EXCLUDED.banned_at
      '''),
        parameters: {
          'id': TypedValue(Type.text, user['id'] as String),
          'phone': TypedValue(Type.text, user['phone'] as String),
          'name': TypedValue(Type.text, user['name'] as String?),
          'role': TypedValue(
            Type.text,
            user['role'] as String? ?? UserRole.ordinaryUser,
          ),
          'banned': TypedValue(Type.boolean, user['banned'] as bool? ?? false),
          'banReason': TypedValue(Type.text, user['banReason'] as String?),
          'bannedByName': TypedValue(
            Type.text,
            user['bannedByName'] as String?,
          ),
          'bannedAt': TypedValue(
            Type.timestampTz,
            user['bannedAt'] != null
                ? DateTime.parse(user['bannedAt'] as String)
                : null,
          ),
        },
      ),
    );
  }

  /// Loads every persisted session (with expiry) into the in-memory auth
  /// caches on startup so Bearer tokens survive server restarts — while
  /// still honoring their TTL.
  Future<
    List<
      ({
        String accessToken,
        String? refreshToken,
        String phone,
        DateTime? expiresAt,
        DateTime? refreshExpiresAt,
      })
    >
  >
  loadAllSessions() async {
    final result = await _db.execute(
      'SELECT access_token, refresh_token, phone, expires_at, '
      'refresh_expires_at FROM sessions',
    );
    return result.map((row) {
      final map = row.toColumnMap();
      return (
        accessToken: map['access_token'] as String,
        refreshToken: map['refresh_token'] as String?,
        phone: map['phone'] as String,
        expiresAt: map['expires_at'] as DateTime?,
        refreshExpiresAt: map['refresh_expires_at'] as DateTime?,
      );
    }).toList();
  }

  /// Persists the opaque token pair minted by [Store.verifyOtp] /
  /// [Store.refreshSession], including their absolute expiry timestamps.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String phone,
    DateTime? expiresAt,
    DateTime? refreshExpiresAt,
  }) async {
    await _asService(
      (s) => s.execute(
        Sql.named('''
          INSERT INTO sessions (
            access_token, refresh_token, phone, expires_at, refresh_expires_at
          )
          VALUES (
            @accessToken, @refreshToken, @phone, @expiresAt, @refreshExpiresAt
          )
          ON CONFLICT (access_token) DO UPDATE SET
            refresh_token = EXCLUDED.refresh_token,
            phone = EXCLUDED.phone,
            expires_at = EXCLUDED.expires_at,
            refresh_expires_at = EXCLUDED.refresh_expires_at
        '''),
        parameters: {
          'accessToken': TypedValue(Type.text, accessToken),
          'refreshToken': TypedValue(Type.text, refreshToken),
          'phone': TypedValue(Type.text, phone),
          'expiresAt': TypedValue(Type.timestampTz, expiresAt),
          'refreshExpiresAt': TypedValue(Type.timestampTz, refreshExpiresAt),
        },
      ),
    );
  }

  Future<void> deleteSessionByAccessToken(String accessToken) async {
    await _asService(
      (s) => s.execute(
        Sql.named('DELETE FROM sessions WHERE access_token = @accessToken'),
        parameters: {'accessToken': TypedValue(Type.text, accessToken)},
      ),
    );
  }

  Future<void> deleteSessionByRefreshToken(String refreshToken) async {
    await _asService(
      (s) => s.execute(
        Sql.named('DELETE FROM sessions WHERE refresh_token = @refreshToken'),
        parameters: {'refreshToken': TypedValue(Type.text, refreshToken)},
      ),
    );
  }

  // --- RLS request context (parameterized set_config — never string-concat) -

  /// Sets `app.user_id` / `app.role` for FORCE RLS policies. Use role
  /// `service` for startup/seed and `system_admin` for platform ops.
  Future<void> setRequestContext({String? userId, String? role}) async {
    await _db.execute(
      Sql.named("SELECT set_config('app.user_id', @userId, false)"),
      parameters: {'userId': TypedValue(Type.text, userId ?? '')},
    );
    await _db.execute(
      Sql.named("SELECT set_config('app.role', @role, false)"),
      parameters: {'role': TypedValue(Type.text, role ?? 'service')},
    );
  }

  // --- Developers + subscriptions ----------------------------------------

  Future<List<Map<String, dynamic>>> loadAllDevelopers() async {
    final result = await _db.execute(
      'SELECT * FROM developers ORDER BY created_at NULLS LAST, id',
    );
    return result
        .map((row) => _developerRecordFromRow(row.toColumnMap()))
        .toList();
  }

  Future<Map<String, Map<String, dynamic>>> loadAllSubscriptions() async {
    final result = await _db.execute('SELECT * FROM subscriptions');
    final out = <String, Map<String, dynamic>>{};
    for (final row in result) {
      final map = row.toColumnMap();
      final sub = _subscriptionFromRow(map);
      out[sub['developerId'] as String] = sub;
    }
    return out;
  }

  Future<void> upsertDeveloper(Map<String, dynamic> d) async {
    await _asService(
      (s) => s.execute(
        Sql.named('''
        INSERT INTO developers (
          id, name, logo_url, rating, projects_count, phone,
          agent_name, agent_phone, agent_avatar_url,
          legal_name, inn, website, verification_status, rejection_reason,
          owner_user_id, created_at,
          account_kind, legal_form, registration_number, oked_code,
          legal_address, office_address, region, email, description,
          brand_color, cover_image_url,
          director_full_name, director_pinfl, director_passport,
          director_phone, director_email,
          ubo_declared, ubo_full_name, construction_license,
          profile_complete, updated_at
        ) VALUES (
          @id, @name, @logoUrl, @rating, @projectsCount, @phone,
          @agentName, @agentPhone, @agentAvatarUrl,
          @legalName, @inn, @website, @verificationStatus, @rejectionReason,
          @ownerUserId, COALESCE(@createdAt::timestamptz, now()),
          @accountKind, @legalForm, @registrationNumber, @okedCode,
          @legalAddress, @officeAddress, @region, @email, @description,
          @brandColor, @coverImageUrl,
          @directorFullName, @directorPinfl, @directorPassport,
          @directorPhone, @directorEmail,
          @uboDeclared, @uboFullName, @constructionLicense,
          @profileComplete, now()
        )
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          logo_url = EXCLUDED.logo_url,
          rating = EXCLUDED.rating,
          projects_count = EXCLUDED.projects_count,
          phone = EXCLUDED.phone,
          agent_name = EXCLUDED.agent_name,
          agent_phone = EXCLUDED.agent_phone,
          agent_avatar_url = EXCLUDED.agent_avatar_url,
          legal_name = EXCLUDED.legal_name,
          inn = EXCLUDED.inn,
          website = EXCLUDED.website,
          verification_status = EXCLUDED.verification_status,
          rejection_reason = EXCLUDED.rejection_reason,
          owner_user_id = EXCLUDED.owner_user_id,
          account_kind = EXCLUDED.account_kind,
          legal_form = EXCLUDED.legal_form,
          registration_number = EXCLUDED.registration_number,
          oked_code = EXCLUDED.oked_code,
          legal_address = EXCLUDED.legal_address,
          office_address = EXCLUDED.office_address,
          region = EXCLUDED.region,
          email = EXCLUDED.email,
          description = EXCLUDED.description,
          brand_color = EXCLUDED.brand_color,
          cover_image_url = EXCLUDED.cover_image_url,
          director_full_name = EXCLUDED.director_full_name,
          director_pinfl = EXCLUDED.director_pinfl,
          director_passport = EXCLUDED.director_passport,
          director_phone = EXCLUDED.director_phone,
          director_email = EXCLUDED.director_email,
          ubo_declared = EXCLUDED.ubo_declared,
          ubo_full_name = EXCLUDED.ubo_full_name,
          construction_license = EXCLUDED.construction_license,
          profile_complete = EXCLUDED.profile_complete,
          updated_at = now()
      '''),
        parameters: {
          'id': TypedValue(Type.text, d['id'] as String),
          'name': TypedValue(Type.text, d['name'] as String?),
          'logoUrl': TypedValue(Type.text, d['logoUrl'] as String?),
          'rating': TypedValue(
            Type.double,
            (d['rating'] as num?)?.toDouble() ?? 0,
          ),
          'projectsCount': TypedValue(
            Type.integer,
            d['projectsCount'] as int? ?? 0,
          ),
          'phone': TypedValue(Type.text, d['phone'] as String?),
          'agentName': TypedValue(Type.text, d['agentName'] as String?),
          'agentPhone': TypedValue(Type.text, d['agentPhone'] as String?),
          'agentAvatarUrl': TypedValue(
            Type.text,
            d['agentAvatarUrl'] as String?,
          ),
          'legalName': TypedValue(Type.text, d['legalName'] as String?),
          'inn': TypedValue(Type.text, d['inn'] as String?),
          'website': TypedValue(Type.text, d['website'] as String?),
          'verificationStatus': TypedValue(
            Type.text,
            d['verificationStatus'] as String? ?? 'pending',
          ),
          'rejectionReason': TypedValue(
            Type.text,
            d['rejectionReason'] as String?,
          ),
          'ownerUserId': TypedValue(Type.text, d['ownerUserId'] as String?),
          'createdAt': TypedValue(Type.text, d['createdAt'] as String?),
          'accountKind': TypedValue(Type.text, d['accountKind'] as String?),
          'legalForm': TypedValue(Type.text, d['legalForm'] as String?),
          'registrationNumber': TypedValue(
            Type.text,
            d['registrationNumber'] as String?,
          ),
          'okedCode': TypedValue(Type.text, d['okedCode'] as String?),
          'legalAddress': TypedValue(Type.text, d['legalAddress'] as String?),
          'officeAddress': TypedValue(Type.text, d['officeAddress'] as String?),
          'region': TypedValue(Type.text, d['region'] as String?),
          'email': TypedValue(Type.text, d['email'] as String?),
          'description': TypedValue(Type.text, d['description'] as String?),
          'brandColor': TypedValue(Type.text, d['brandColor'] as String?),
          'coverImageUrl': TypedValue(Type.text, d['coverImageUrl'] as String?),
          'directorFullName': TypedValue(
            Type.text,
            d['directorFullName'] as String?,
          ),
          'directorPinfl': TypedValue(Type.text, d['directorPinfl'] as String?),
          'directorPassport': TypedValue(
            Type.text,
            d['directorPassport'] as String?,
          ),
          'directorPhone': TypedValue(Type.text, d['directorPhone'] as String?),
          'directorEmail': TypedValue(Type.text, d['directorEmail'] as String?),
          'uboDeclared': TypedValue(
            Type.boolean,
            d['uboDeclared'] as bool? ?? false,
          ),
          'uboFullName': TypedValue(Type.text, d['uboFullName'] as String?),
          'constructionLicense': TypedValue(
            Type.text,
            d['constructionLicense'] as String?,
          ),
          'profileComplete': TypedValue(
            Type.boolean,
            d['profileComplete'] as bool? ?? false,
          ),
        },
      ),
    );
  }

  Future<void> upsertSubscription(Map<String, dynamic> sub) async {
    await _asService(
      (s) => s.execute(
        Sql.named('''
        INSERT INTO subscriptions (
          id, developer_id, plan_id, amount_usd, currency, status,
          provider, provider_ref, current_period_start, current_period_end,
          last_payment_at, created_at, updated_at
        ) VALUES (
          @id, @developerId, @planId, @amountUsd, @currency, @status,
          @provider, @providerRef,
          @periodStart::timestamptz, @periodEnd::timestamptz,
          @lastPaymentAt::timestamptz,
          COALESCE(@createdAt::timestamptz, now()), now()
        )
        ON CONFLICT (developer_id) DO UPDATE SET
          plan_id = EXCLUDED.plan_id,
          amount_usd = EXCLUDED.amount_usd,
          currency = EXCLUDED.currency,
          status = EXCLUDED.status,
          provider = EXCLUDED.provider,
          provider_ref = EXCLUDED.provider_ref,
          current_period_start = EXCLUDED.current_period_start,
          current_period_end = EXCLUDED.current_period_end,
          last_payment_at = EXCLUDED.last_payment_at,
          updated_at = now()
      '''),
        parameters: {
          'id': TypedValue(Type.text, sub['id'] as String),
          'developerId': TypedValue(Type.text, sub['developerId'] as String),
          'planId': TypedValue(
            Type.text,
            sub['planId'] as String? ?? 'business_monthly',
          ),
          'amountUsd': TypedValue(
            Type.double,
            (sub['amountUsd'] as num?)?.toDouble() ?? 299.0,
          ),
          'currency': TypedValue(
            Type.text,
            sub['currency'] as String? ?? 'USD',
          ),
          'status': TypedValue(Type.text, sub['status'] as String? ?? 'none'),
          'provider': TypedValue(
            Type.text,
            sub['provider'] as String? ?? 'manual',
          ),
          'providerRef': TypedValue(Type.text, sub['providerRef'] as String?),
          'periodStart': TypedValue(
            Type.text,
            sub['currentPeriodStart'] as String?,
          ),
          'periodEnd': TypedValue(
            Type.text,
            sub['currentPeriodEnd'] as String?,
          ),
          'lastPaymentAt': TypedValue(
            Type.text,
            sub['lastPaymentAt'] as String?,
          ),
          'createdAt': TypedValue(Type.text, sub['createdAt'] as String?),
        },
      ),
    );
  }

  Map<String, dynamic> _developerRecordFromRow(Map<String, dynamic> m) => {
    'id': m['id'],
    'name': m['name'],
    'logoUrl': m['logo_url'],
    'rating': (m['rating'] as num?)?.toDouble() ?? 0.0,
    'projectsCount': m['projects_count'] ?? 0,
    'phone': m['phone'],
    'agentName': m['agent_name'],
    'agentPhone': m['agent_phone'],
    'agentAvatarUrl': m['agent_avatar_url'],
    'legalName': m['legal_name'],
    'inn': m['inn'],
    'website': m['website'],
    'verificationStatus': m['verification_status'] ?? 'pending',
    'rejectionReason': m['rejection_reason'],
    'ownerUserId': m['owner_user_id'],
    'createdAt': m['created_at']?.toString(),
    'accountKind': m['account_kind'],
    'legalForm': m['legal_form'],
    'registrationNumber': m['registration_number'],
    'okedCode': m['oked_code'],
    'legalAddress': m['legal_address'],
    'officeAddress': m['office_address'],
    'region': m['region'],
    'email': m['email'],
    'description': m['description'],
    'brandColor': m['brand_color'],
    'coverImageUrl': m['cover_image_url'],
    'directorFullName': m['director_full_name'],
    'directorPinfl': m['director_pinfl'],
    'directorPassport': m['director_passport'],
    'directorPhone': m['director_phone'],
    'directorEmail': m['director_email'],
    'uboDeclared': m['ubo_declared'] ?? false,
    'uboFullName': m['ubo_full_name'],
    'constructionLicense': m['construction_license'],
    'profileComplete': m['profile_complete'] ?? false,
  };

  /// NUMERIC columns come back from the `postgres` driver as [String];
  /// DOUBLE PRECISION comes back as [double]. Accept both.
  num? _asNum(Object? v) => switch (v) {
    null => null,
    final num n => n,
    final String s => num.tryParse(s),
    _ => null,
  };

  Map<String, dynamic> _subscriptionFromRow(Map<String, dynamic> m) => {
    'id': m['id'],
    'developerId': m['developer_id'],
    'planId': m['plan_id'] ?? 'business_monthly',
    'amountUsd': _asNum(m['amount_usd'])?.toDouble() ?? 299.0,
    'currency': m['currency'] ?? 'USD',
    'status': m['status'] ?? 'none',
    'provider': m['provider'] ?? 'manual',
    'providerRef': m['provider_ref'],
    'currentPeriodStart': m['current_period_start']?.toString(),
    'currentPeriodEnd': m['current_period_end']?.toString(),
    'lastPaymentAt': m['last_payment_at']?.toString(),
    'createdAt': m['created_at']?.toString(),
    'updatedAt': m['updated_at']?.toString(),
  };
}
