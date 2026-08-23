import 'store.dart';
import 'user_roles.dart';

/// Synthetic admin/CRM rows for B2B demo sessions.
///
/// Bound to **live published projects** (and their units) so a lead card
/// opens a real catalogue record instead of a fake `demo-project-1` that
/// 404s. Never persisted; [DemoOverlay] is the only caller, and it only
/// merges these in when [AuthContext.isDemo] is true.
///
/// NestOne (`prj-nestone`) placeholders are assigned to the residence demo
/// admin so the NestOne workspace CRM is fully populated.
class DemoSnapshot {
  DemoSnapshot._();

  static const ownerId = 'demo-user-b2b-platform';
  static const ownerName = 'Demo Reviewer (Admin)';

  static const residenceOwnerId = 'demo-user-b2b-residence';
  static const residenceOwnerName = 'NestOne Admin';
  static const nestOneProjectId = 'prj-nestone';
  static const nestOneDeveloperId = 'dev-nestone';

  static const idPrefix = 'demo-ov-';

  static String _ago({int minutes = 0, int hours = 0, int days = 0}) =>
      DateTime.now()
          .toUtc()
          .subtract(Duration(days: days, hours: hours, minutes: minutes))
          .toIso8601String();

  static String _ahead({int hours = 0, int days = 0}) => DateTime.now()
      .toUtc()
      .add(Duration(days: days, hours: hours))
      .toIso8601String();

  static Map<String, dynamic> mark(Map<String, dynamic> row) => {
    ...row,
    'isDemoPlaceholder': true,
  };

  static List<Map<String, dynamic>> _anchorProjects(Store store) {
    if (store.publishedProjects.isNotEmpty) return store.publishedProjects;
    return store.projects;
  }

  static Map<String, dynamic> _projectAt(Store store, int index) {
    final list = _anchorProjects(store);
    if (list.isEmpty) {
      return {'id': '${idPrefix}unbound-project', 'name': 'Yangi Hayot'};
    }
    return list[index % list.length];
  }

  static ({String? id, String? label}) _unitAt(
    Map<String, dynamic> project,
    int index,
  ) {
    final units = <Map<dynamic, dynamic>>[
      for (final b
          in (project['buildings'] as List? ?? const []).cast<Map>())
        ...(b['units'] as List? ?? const []).cast<Map>(),
    ];
    if (units.isEmpty) return (id: null, label: null);
    final unit = units[index % units.length];
    final kind = switch (unit['kind']) {
      'office' => 'Office',
      'retail' => 'Retail unit',
      _ => 'Apartment',
    };
    return (id: unit['id'] as String?, label: '$kind ${unit['number']}');
  }

  static Map<String, dynamic> _lead({
    required int index,
    required Map<String, dynamic> project,
    required String number,
    required String status,
    required String intent,
    required String phone,
    required String message,
    required int aiScore,
    required String aiBand,
    required List<String> aiReasons,
    String? subject,
    String? ownerUserId,
    String? assignedManager,
    String? lastContactAt,
    String? preferredAt,
    String? notes,
    required String createdAt,
  }) {
    final unit = _unitAt(project, index);
    return mark({
      'id': '${idPrefix}lead-${index.toString().padLeft(2, '0')}',
      'number': number,
      'projectId': project['id'],
      'projectName': project['name'] ?? 'Yangi Hayot',
      'unitId': unit.id,
      'unitLabel': unit.label,
      'intent': intent,
      'subject': subject,
      'status': status,
      'contactPhone': phone,
      'message': message,
      'preferredAt': preferredAt,
      'userId': null,
      'ownerUserId': ownerUserId,
      'assignedManager': assignedManager,
      'notes': notes,
      'createdAt': createdAt,
      'lastContactAt': lastContactAt,
      'aiScore': aiScore,
      'aiBand': aiBand,
      'aiReasons': aiReasons,
      'aiScoredAt': _ago(minutes: 5),
    });
  }

  /// Assignee for the "contacted" placeholder on a project: NestOne / the
  /// residence-demo developer's projects go to [residenceOwnerId], everything
  /// else to the platform demo reviewer.
  static ({String id, String name}) _assigneeForProject(
    Store store,
    Map<String, dynamic> project,
  ) {
    final developerId =
        (project['developer'] as Map?)?['id'] as String? ??
        project['developerId'] as String?;
    final reg = developerId == null ? null : store.developerById(developerId);
    final ownedByResidence = reg?['ownerUserId'] == residenceOwnerId ||
        project['id'] == nestOneProjectId ||
        developerId == nestOneDeveloperId;
    if (ownedByResidence) {
      return (id: residenceOwnerId, name: residenceOwnerName);
    }
    return (id: ownerId, name: ownerName);
  }

  /// Two placeholder leads per published ЖК — enough to demo the funnel
  /// without flooding project CRM screens.
  static List<Map<String, dynamic>> leads(Store store, {String? projectId}) {
    final projects = _anchorProjects(store);
    final anchors = projects.isEmpty
        ? <Map<String, dynamic>>[_projectAt(store, 0)]
        : projects;

    final items = <Map<String, dynamic>>[];
    var index = 1;
    for (var p = 0; p < anchors.length; p++) {
      final project = anchors[p];
      final assignee = _assigneeForProject(store, project);
      final phoneA = '+99890001${(40 + p * 2).toString().padLeft(4, '0')}';
      final phoneB = '+99890001${(41 + p * 2).toString().padLeft(4, '0')}';
      items.add(
        _lead(
          index: index++,
          project: project,
          number: 'L-${1040 + p * 2}',
          status: 'new',
          intent: 'buy_offplan',
          phone: phoneA,
          message:
              'Urgent: want the 2-room off-plan unit, ready to pay mortgage down payment this week.',
          aiScore: 88,
          aiBand: 'hot',
          aiReasons: const ['highIntent', 'offplanInterest', 'urgentKeyword'],
          subject: 'unit',
          createdAt: _ago(minutes: 38 + p),
        ),
      );
      items.add(
        _lead(
          index: index++,
          project: project,
          number: 'L-${1041 + p * 2}',
          status: 'contacted',
          intent: 'viewing',
          phone: phoneB,
          message:
              'Please schedule a viewing for apartment 101, family of four, evenings after 18:00.',
          aiScore: 76,
          aiBand: 'hot',
          aiReasons: const ['viewingRequested', 'specificUnit', 'funnelAdvanced'],
          subject: 'unit',
          ownerUserId: assignee.id,
          assignedManager: assignee.name,
          preferredAt: _ahead(hours: 22),
          lastContactAt: _ago(hours: 6),
          createdAt: _ago(hours: 3, minutes: 20 + p),
        ),
      );
    }

    if (projectId == null || projectId.isEmpty) return items;
    return items.where((l) => l['projectId'] == projectId).toList();
  }

  static Map<String, dynamic>? leadById(Store store, String id) {
    for (final lead in leads(store)) {
      if (lead['id'] == id) return lead;
    }
    return null;
  }

  static List<Map<String, dynamic>> leadEvents(String leadId) {
    if (!leadId.startsWith('${idPrefix}lead-')) return const [];
    final created = _ago(hours: 4);
    final items = <Map<String, dynamic>>[
      mark({
        'id': '$leadId-evt-created',
        'leadId': leadId,
        'actorUserId': null,
        'type': 'created',
        'fromUserId': null,
        'toUserId': null,
        'detail': 'Lead created (demo placeholder)',
        'createdAt': created,
      }),
    ];
    final leadNum = int.tryParse(
      RegExp(r'lead-(\d+)$').firstMatch(leadId)?.group(1) ?? '',
    );
    // Second placeholder per project is the assigned "contacted" card.
    if (leadNum != null && leadNum.isEven) {
      items.insert(
        0,
        mark({
          'id': '$leadId-evt-assigned',
          'leadId': leadId,
          'actorUserId': ownerId,
          'type': 'assigned',
          'fromUserId': null,
          'toUserId': ownerId,
          'detail': 'Assigned to $ownerName (demo)',
          'createdAt': _ago(hours: 3),
        }),
      );
    }
    if (leadId == '${idPrefix}lead-07' || leadId == '${idPrefix}lead-08') {
      items.insert(
        0,
        mark({
          'id': '$leadId-evt-note',
          'leadId': leadId,
          'actorUserId': ownerId,
          'type': 'note',
          'fromUserId': null,
          'toUserId': null,
          'detail': 'Follow-up scheduled after family discussion (demo).',
          'createdAt': _ago(hours: 8),
        }),
      );
    }
    return items;
  }

  static List<Map<String, dynamic>> extraUsers() => [
    mark({
      'id': '${idPrefix}user-buyer',
      'phone': '+998900001003',
      'name': 'Sample Buyer',
      'role': UserRole.ordinaryUser,
      'banned': false,
    }),
    mark({
      'id': '${idPrefix}user-residence',
      'phone': '+998900001002',
      'name': 'Sample Residence Admin',
      'role': UserRole.residenceAdmin,
      'banned': false,
    }),
    mark({
      'id': '${idPrefix}user-renter',
      'phone': '+998900001004',
      'name': 'Sample Renter',
      'role': UserRole.ordinaryUser,
      'banned': false,
    }),
  ];

  static List<Map<String, dynamic>> pendingDevelopers() => [
    mark({
      'id': '${idPrefix}developer-pending',
      'name': 'Nurli Qurilish',
      'legalName': 'Nurli Qurilish MCHJ',
      'inn': '309876543',
      'verificationStatus': 'pending',
      'accountKind': 'property_developer',
      'legalForm': 'LLC',
      'directorFullName': 'Aziza Karimova',
      'directorPinfl': '32109876543210',
      'directorPhone': '+998900001010',
      'directorEmail': 'aziza@nurli.example',
      'phone': '+998900001010',
      'email': 'hello@nurli.example',
      'legalAddress': 'Tashkent, Yunusabad, demo st. 12',
      'officeAddress': 'Tashkent, Yunusabad, demo st. 12',
      'region': 'Tashkent',
      'registrationNumber': 'REG-DEMO-441',
      'okedCode': '41201',
      'constructionLicense': 'LIC-DEMO-19',
      'uboDeclared': true,
      'uboFullName': 'Aziza Karimova',
      'ownerUserId': '${idPrefix}user-residence',
      'createdAt': _ago(days: 2, hours: 4),
    }),
    mark({
      'id': '${idPrefix}developer-review',
      'name': 'Sohil Residences',
      'legalName': 'Sohil Residences MCHJ',
      'inn': '308112233',
      'verificationStatus': 'in_review',
      'accountKind': 'property_developer',
      'legalForm': 'LLC',
      'directorFullName': 'Bekzod Tursunov',
      'directorPinfl': '30112233445566',
      'directorPhone': '+998900001011',
      'phone': '+998900001011',
      'email': 'kyc@sohil.example',
      'legalAddress': 'Tashkent, Mirabad, demo ave. 8',
      'region': 'Tashkent',
      'registrationNumber': 'REG-DEMO-228',
      'okedCode': '41201',
      'constructionLicense': 'LIC-DEMO-22',
      'uboDeclared': true,
      'uboFullName': 'Bekzod Tursunov',
      'createdAt': _ago(days: 6),
    }),
  ];

  static List<Map<String, dynamic>>? documentsForDeveloper(String developerId) {
    if (developerId == '${idPrefix}developer-pending') {
      return [
        for (final type in kRequiredDocumentTypes)
          mark({
            'id': '${idPrefix}doc-pending-$type',
            'developerId': developerId,
            'projectId': null,
            'type': type,
            'fileUrl': '/v1/documents/demo-placeholder.pdf',
            'status': 'pending',
            'rejectReason': null,
            'uploadedBy': '${idPrefix}user-residence',
            'createdAt': _ago(days: 2),
            'reviewedBy': null,
            'reviewedAt': null,
          }),
      ];
    }
    if (developerId == '${idPrefix}developer-review') {
      return [
        for (final type in kRequiredDocumentTypes)
          mark({
            'id': '${idPrefix}doc-review-$type',
            'developerId': developerId,
            'projectId': null,
            'type': type,
            'fileUrl': '/v1/documents/demo-placeholder.pdf',
            'status': type == 'project_declaration' ? 'pending' : 'accepted',
            'rejectReason': null,
            'uploadedBy': '${idPrefix}user-residence',
            'createdAt': _ago(days: 5),
            'reviewedBy': type == 'project_declaration' ? null : ownerId,
            'reviewedAt': type == 'project_declaration' ? null : _ago(days: 1),
          }),
      ];
    }
    return null;
  }

  static List<Map<String, dynamic>> businesses() => [
    mark({
      'id': '${idPrefix}developer-active',
      'name': 'Demo Builder Co.',
      'legalName': 'Demo Builder Co. MCHJ',
      'inn': '307654321',
      'verificationStatus': 'approved',
      'accountKind': 'property_developer',
      'directorFullName': 'Nilufar Rasulova',
      'paymentStatus': 'active',
      'canPublish': true,
      'subscription': {'planId': 'start', 'status': 'active'},
    }),
    mark({
      'id': '${idPrefix}developer-unpaid',
      'name': 'Chilonzor Heights',
      'legalName': 'Chilonzor Heights MCHJ',
      'inn': '306112299',
      'verificationStatus': 'approved',
      'accountKind': 'property_developer',
      'directorFullName': 'Jasur Aliyev',
      'paymentStatus': 'none',
      'canPublish': false,
      'subscription': {'planId': 'start', 'status': 'expired'},
    }),
  ];

  static List<Map<String, dynamic>> tickets({String? status}) {
    final items = [
      mark({
        'id': '${idPrefix}ticket-1',
        'userId': '${idPrefix}user-residence',
        'userName': 'Sample Residence Admin',
        'userPhone': '+998900001002',
        'subject': 'How do I publish a new building?',
        'category': 'moderation',
        'status': 'open',
        'assignedToName': null,
        'replies': [
          {
            'authorName': 'Sample Residence Admin',
            'isAdmin': false,
            'message':
                'Submitted Block C yesterday — still draft. What is missing for review?',
            'createdAt': _ago(hours: 5),
          },
        ],
        'createdAt': _ago(hours: 5),
        'updatedAt': _ago(hours: 5),
      }),
      mark({
        'id': '${idPrefix}ticket-2',
        'userId': '${idPrefix}user-buyer',
        'userName': 'Sample Buyer',
        'userPhone': '+998900001003',
        'subject': 'Invoice for Publisher plan',
        'category': 'billing',
        'status': 'in_progress',
        'assignedToName': ownerName,
        'replies': [
          {
            'authorName': 'Sample Buyer',
            'isAdmin': false,
            'message': 'Card charged twice for this month. Need a refund.',
            'createdAt': _ago(days: 1, hours: 3),
          },
          {
            'authorName': ownerName,
            'isAdmin': true,
            'message':
                'Looking at the payment log now — we will reverse the duplicate (demo).',
            'createdAt': _ago(hours: 20),
          },
        ],
        'createdAt': _ago(days: 1, hours: 3),
        'updatedAt': _ago(hours: 20),
      }),
      mark({
        'id': '${idPrefix}ticket-3',
        'userId': '${idPrefix}user-renter',
        'userName': 'Sample Renter',
        'userPhone': '+998900001004',
        'subject': 'Cannot upload listing photos',
        'category': 'technical',
        'status': 'resolved',
        'assignedToName': ownerName,
        'replies': [
          {
            'authorName': 'Sample Renter',
            'isAdmin': false,
            'message': 'Upload fails on HEIC from iPhone.',
            'createdAt': _ago(days: 3),
          },
          {
            'authorName': ownerName,
            'isAdmin': true,
            'message': 'Converted on our side — try JPEG. Closing as resolved.',
            'createdAt': _ago(days: 2, hours: 4),
          },
        ],
        'createdAt': _ago(days: 3),
        'updatedAt': _ago(days: 2, hours: 4),
      }),
      mark({
        'id': '${idPrefix}ticket-4',
        'userId': '${idPrefix}user-buyer',
        'userName': 'Sample Buyer',
        'userPhone': '+998900001003',
        'subject': 'Question about saved searches',
        'category': 'other',
        'status': 'closed',
        'assignedToName': ownerName,
        'replies': [
          {
            'authorName': 'Sample Buyer',
            'isAdmin': false,
            'message': 'Do alerts work for rent as well as sale?',
            'createdAt': _ago(days: 8),
          },
          {
            'authorName': ownerName,
            'isAdmin': true,
            'message': 'Yes — both deal types. Closing this thread.',
            'createdAt': _ago(days: 7),
          },
        ],
        'createdAt': _ago(days: 8),
        'updatedAt': _ago(days: 7),
      }),
    ];
    if (status == null || status.isEmpty) return items;
    return items.where((t) => t['status'] == status).toList();
  }

  static Map<String, dynamic>? ticketById(String id) {
    for (final ticket in tickets()) {
      if (ticket['id'] == id) return ticket;
    }
    return null;
  }

  static List<Map<String, dynamic>> notifications() => [
    mark({
      'id': '${idPrefix}notif-1',
      'type': 'developer_submitted',
      'title': 'KYC: Nurli Qurilish',
      'body': null,
      'payload': {'developerName': 'Nurli Qurilish'},
      'developerId': '${idPrefix}developer-pending',
      'projectId': null,
      'targetType': 'developer',
      'targetId': '${idPrefix}developer-pending',
      'actorUserId': '${idPrefix}user-residence',
      'severity': 'info',
      'isRead': false,
      'createdAt': _ago(hours: 2),
    }),
    mark({
      'id': '${idPrefix}notif-2',
      'type': 'document_uploaded',
      'title': 'Document: license',
      'body': null,
      'payload': {
        'developerName': 'Nurli Qurilish',
        'documentType': 'license',
      },
      'developerId': '${idPrefix}developer-pending',
      'severity': 'info',
      'isRead': false,
      'createdAt': _ago(hours: 3),
    }),
    mark({
      'id': '${idPrefix}notif-3',
      'type': 'project_submitted',
      'title': 'Project submitted',
      'body': null,
      'payload': {
        'projectName': 'Sohil Court',
        'developerName': 'Sohil Residences',
      },
      'severity': 'info',
      'isRead': false,
      'createdAt': _ago(hours: 8),
    }),
    mark({
      'id': '${idPrefix}notif-4',
      'type': 'progress_deviation',
      'title': 'Schedule slip',
      'body': null,
      'payload': {
        'projectName': 'Yangi Hayot',
        'actual': 42,
        'planned': 60,
        'gap': 18,
      },
      'severity': 'warning',
      'isRead': false,
      'createdAt': _ago(days: 1, hours: 2),
    }),
    mark({
      'id': '${idPrefix}notif-5',
      'type': 'project_updated',
      'title': 'Project updated',
      'body': null,
      'payload': {
        'projectName': 'Boulevard Park',
        'changedFields': ['priceMin', 'gallery'],
      },
      'severity': 'info',
      'isRead': true,
      'createdAt': _ago(days: 2),
    }),
  ];

  static int unreadNotificationCount() =>
      notifications().where((n) => n['isRead'] != true).length;

  static List<Map<String, dynamic>> pendingReviews(Store store) {
    final project = _projectAt(store, 0);
    return [
      mark({
        'id': '${idPrefix}review-1',
        'userId': '${idPrefix}user-buyer',
        'userName': 'Sample Buyer',
        'projectId': project['id'],
        'projectName': project['name'],
        'developerId': (project['developer'] as Map?)?['id'],
        'ratingOverall': 2,
        'ratingLocation': 4,
        'ratingQuality': 2,
        'ratingValue': 1,
        'body':
            'Photos look finished but the site visit showed raw concrete. Flagging this.',
        'status': 'flagged',
        'createdAt': _ago(hours: 14),
      }),
      mark({
        'id': '${idPrefix}review-2',
        'userId': '${idPrefix}user-renter',
        'userName': 'Sample Renter',
        'projectId': project['id'],
        'projectName': project['name'],
        'developerId': (project['developer'] as Map?)?['id'],
        'ratingOverall': 5,
        'ratingLocation': 5,
        'ratingQuality': 4,
        'ratingValue': 5,
        'body': 'Great location near metro — but the comment looks like spam.',
        'status': 'flagged',
        'createdAt': _ago(days: 1, hours: 6),
      }),
    ];
  }

  static List<Map<String, dynamic>> pendingRentalListings() => [
    mark({
      'id': '${idPrefix}rental-1',
      'ownerUserId': '${idPrefix}user-renter',
      'title': '2-room near metro, Mirabad',
      'description': 'Furnished, 6th floor, family only. Demo listing.',
      'district': 'Mirabad',
      'address': 'Mirabad, demo street 4',
      'lat': 41.30,
      'lng': 69.28,
      'propertyKind': 'apartment',
      'dealType': 'rent',
      'areaTotal': 64.0,
      'rooms': 2,
      'rentMonthly': 650.0,
      'minLeaseMonths': 12,
      'contactPhone': '+998900003001',
      'photos': const <String>[],
      'isSecondary': true,
      'moderationStatus': 'pending',
      'moderationNote': null,
      'isFeatured': false,
      'createdAt': _ago(hours: 11),
    }),
    mark({
      'id': '${idPrefix}rental-2',
      'ownerUserId': '${idPrefix}user-renter',
      'title': 'Office 48 m², business centre',
      'description': 'Open space, two parking spots. Demo listing.',
      'district': 'Yunusabad',
      'address': 'Yunusabad, demo ave. 19',
      'lat': 41.33,
      'lng': 69.29,
      'propertyKind': 'office',
      'dealType': 'rent',
      'areaTotal': 48.0,
      'rooms': null,
      'rentMonthly': 980.0,
      'minLeaseMonths': 24,
      'contactPhone': '+998900003002',
      'photos': const <String>[],
      'isSecondary': true,
      'moderationStatus': 'pending',
      'moderationNote': null,
      'isFeatured': false,
      'createdAt': _ago(days: 1, hours: 3),
    }),
  ];

  static List<Map<String, dynamic>> auditLog() => [
    mark({
      'id': '${idPrefix}audit-1',
      'actorUserId': ownerId,
      'action': 'developer.status',
      'targetType': 'developer',
      'targetId': '${idPrefix}developer-review',
      'detail': 'in_review (demo)',
      'createdAt': _ago(hours: 4),
    }),
    mark({
      'id': '${idPrefix}audit-2',
      'actorUserId': ownerId,
      'action': 'review.keep',
      'targetType': 'review',
      'targetId': '${idPrefix}review-2',
      'detail': null,
      'createdAt': _ago(hours: 9),
    }),
    mark({
      'id': '${idPrefix}audit-3',
      'actorUserId': ownerId,
      'action': 'rental_listing.approve',
      'targetType': 'rental_listing',
      'targetId': '${idPrefix}rental-legacy',
      'detail': 'Approved after photo check (demo)',
      'createdAt': _ago(days: 1, hours: 2),
    }),
    mark({
      'id': '${idPrefix}audit-4',
      'actorUserId': ownerId,
      'action': 'project.approve',
      'targetType': 'project',
      'targetId': '${idPrefix}unbound-project',
      'detail': 'Demo moderation event',
      'createdAt': _ago(days: 2),
    }),
    mark({
      'id': '${idPrefix}audit-5',
      'actorUserId': ownerId,
      'action': 'ticket.update',
      'targetType': 'ticket',
      'targetId': '${idPrefix}ticket-3',
      'detail': 'resolved',
      'createdAt': _ago(days: 2, hours: 4),
    }),
    mark({
      'id': '${idPrefix}audit-6',
      'actorUserId': ownerId,
      'action': 'user.role',
      'targetType': 'user',
      'targetId': '${idPrefix}user-residence',
      'detail': 'residence_admin',
      'createdAt': _ago(days: 5),
    }),
  ];

  /// Count bumps only — live project/catalogue totals stay real.
  static Map<String, int> analyticsDeltas(Store store) => {
    'leadsTotal': leads(store).length,
    'developersPending': pendingDevelopers().length,
    'usersTotal': extraUsers().length,
    'reviewsPendingModeration': pendingReviews(store).length,
    'reviewsTotal': pendingReviews(store).length,
    'rentalListingsPending': pendingRentalListings().length,
  };
}
