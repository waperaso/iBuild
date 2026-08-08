import 'package:ibuild_core/ibuild_core.dart';

/// Bundled sample data so every screen renders end-to-end before the NestJS
/// backend exists. Swap out by flipping `Env.useMockData` once the API is live.
abstract class MockData {
  static const _photo1 =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/20230606_Tashkent019.jpg/1280px-20230606_Tashkent019.jpg';
  static const _photo2 =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Apartment_building_in_Tashkent_(Uzbekistan).jpg/1280px-Apartment_building_in_Tashkent_(Uzbekistan).jpg';
  static const _photo3 =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Sky_builds.jpg/1280px-Sky_builds.jpg';
  static const _photo4 =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Immeubles_r%C3%A9sidentiels_%C3%A0_Tchilanzar.JPG/1280px-Immeubles_r%C3%A9sidentiels_%C3%A0_Tchilanzar.JPG';

  static final developers = <Developer>[
    const Developer(
      id: 'dev-1',
      name: 'Aaradhya Group',
      rating: 4.7,
      projectsCount: 6,
      phone: '+998 71 200 10 10',
      agentName: 'Aziz Karimov',
      agentPhone: '+998 90 123 45 67',
    ),
    const Developer(
      id: 'dev-2',
      name: 'Nova Estates',
      rating: 4.5,
      projectsCount: 4,
      phone: '+998 71 200 20 20',
      agentName: 'Dilnoza Yusupova',
      agentPhone: '+998 90 234 56 78',
    ),
    const Developer(
      id: 'dev-3',
      name: 'Tashkent City Group',
      rating: 4.9,
      projectsCount: 3,
      phone: '+998 71 200 30 30',
      agentName: 'Sardor Rashidov',
      agentPhone: '+998 90 345 67 89',
    ),
    const Developer(
      id: 'dev-4',
      name: 'Skyline Development',
      rating: 4.2,
      projectsCount: 2,
      phone: '+998 71 200 40 40',
      agentName: 'Malika Tosheva',
      agentPhone: '+998 90 456 78 90',
    ),
  ];

  static List<Unit> _units(String buildingId, {required DealType dealType}) {
    final statuses = [
      UnitStatus.available,
      UnitStatus.reserved,
      UnitStatus.sold,
      UnitStatus.available,
      UnitStatus.blocked,
      UnitStatus.available,
    ];
    return List.generate(24, (i) {
      final floor = (i ~/ 4) + 1;
      final col = i % 4;
      return Unit(
        id: '$buildingId-u$i',
        buildingId: buildingId,
        number: '${floor}0${col + 1}',
        kind: dealType == DealType.rent ? UnitKind.office : UnitKind.apartment,
        dealType: dealType,
        status: statuses[i % statuses.length],
        floor: floor,
        isOffplan: i.isEven,
        areaTotal: 48 + (i % 5) * 18,
        areaLiving: 40 + (i % 5) * 15,
        rooms: dealType == DealType.rent ? null : 1 + (i % 4),
        layout: dealType == DealType.rent ? 'Open plan' : null,
        price: dealType == DealType.sale ? 32000 + (i % 6) * 8500 : null,
        priceM2: dealType == DealType.sale ? 620 + (i % 6) * 40 : null,
        rentMonthly: dealType == DealType.rent ? 900 + (i % 6) * 220 : null,
        rentM2: dealType == DealType.rent ? 14 + (i % 6) * 2 : null,
        minLeaseMonths: dealType == DealType.rent ? 12 : null,
        finishing: const ['Turnkey', 'Pre-finish', 'None'][i % 3],
        view: const ['City', 'Park', 'Courtyard'][i % 3],
        planColumn: col,
        planRow: floor - 1,
      );
    });
  }

  static final projects = <Project>[
    Project(
      id: 'prj-1',
      name: 'Aaradhya Homes',
      type: ProjectType.residentialComplex,
      status: ProjectStatus.underConstruction,
      district: 'Yunusabad',
      address: 'Amir Temur Ave 12, Tashkent',
      lat: 41.3379,
      lng: 69.3348,
      developer: developers[0],
      description:
          'A modern residential complex with landscaped courtyards, '
          'underground parking and a rooftop terrace.',
      amenities: const ['Parking', 'Security', 'Elevators', 'Playground'],
      tags: const ['New build', 'Installments'],
      priceMin: 32000,
      priceMax: 120000,
      constructionProgress: 62,
      plannedProgress: 74,
      completionDate: DateTime(2027, 6),
      rating: 4.6,
      availableUnits: 14,
      totalUnits: 24,
      isFeatured: true,
      gallery: const [
        MediaItem(id: 'm1', type: MediaType.photo, url: _photo1, isCover: true),
        MediaItem(id: 'm2', type: MediaType.render, url: _photo3),
        MediaItem(id: 'm3', type: MediaType.photo, url: _photo4),
      ],
      buildings: [
        Building(
          id: 'prj-1-b1',
          projectId: 'prj-1',
          name: 'Block A',
          floors: 6,
          constructionProgress: 62,
          completionDate: DateTime(2027, 6),
          units: _units('prj-1-b1', dealType: DealType.sale),
        ),
      ],
      offers: [
        Offer(
          id: 'of-1',
          projectId: 'prj-1',
          type: OfferType.installment,
          title: '0% installment for 24 months',
          description: '30% down payment, the rest split monthly.',
          endsAt: DateTime(2026, 12, 31),
          downPaymentPercent: 0.3,
          termMonths: 24,
          interestRate: 0.0,
        ),
      ],
    ),
    Project(
      id: 'prj-2',
      name: 'Nova Residence',
      type: ProjectType.residentialComplex,
      status: ProjectStatus.ready,
      district: 'Mirzo Ulugbek',
      address: 'Buyuk Ipak Yuli 45, Tashkent',
      lat: 41.3251,
      lng: 69.3436,
      developer: developers[1],
      description: 'Ready-to-move apartments with premium finishing.',
      amenities: const ['Parking', 'Gym', 'Concierge'],
      tags: const ['Ready', 'Premium'],
      priceMin: 58000,
      priceMax: 210000,
      rating: 4.8,
      availableUnits: 9,
      totalUnits: 24,
      gallery: const [
        MediaItem(id: 'm4', type: MediaType.photo, url: _photo2, isCover: true),
        MediaItem(id: 'm5', type: MediaType.photo, url: _photo3),
      ],
      buildings: [
        Building(
          id: 'prj-2-b1',
          projectId: 'prj-2',
          name: 'Tower 1',
          floors: 6,
          units: _units('prj-2-b1', dealType: DealType.sale),
        ),
      ],
    ),
    Project(
      id: 'prj-3',
      name: 'Victoria Business Centre',
      type: ProjectType.businessCentre,
      status: ProjectStatus.ready,
      district: 'Shayxontohur',
      address: 'Navoi St 2, Tashkent',
      lat: 41.3111,
      lng: 69.2401,
      developer: developers[1],
      description: 'Class-A offices for rent in the city core.',
      amenities: const ['Parking', 'Security', 'Fiber internet'],
      tags: const ['Office rent', 'Class A'],
      rentMin: 900,
      rentMax: 3200,
      rating: 4.4,
      availableUnits: 12,
      totalUnits: 24,
      gallery: const [
        MediaItem(id: 'm6', type: MediaType.photo, url: _photo4, isCover: true),
      ],
      buildings: [
        Building(
          id: 'prj-3-b1',
          projectId: 'prj-3',
          name: 'Section A',
          floors: 6,
          units: _units('prj-3-b1', dealType: DealType.rent),
        ),
      ],
    ),
    Project(
      id: 'prj-4',
      name: 'City Gardens',
      type: ProjectType.residentialComplex,
      status: ProjectStatus.underConstruction,
      district: 'Chilanzar',
      address: 'Bunyodkor Ave 78, Tashkent',
      lat: 41.2856,
      lng: 69.2034,
      developer: developers[2],
      description:
          'An off-plan garden-courtyard complex with flexible installments '
          'and a kindergarten on-site.',
      amenities: const [
        'Parking',
        'Playground',
        'Kindergarten',
        'Courtyard',
      ],
      tags: const ['New build', 'Installments'],
      priceMin: 28000,
      priceMax: 95000,
      constructionProgress: 34,
      plannedProgress: 41,
      completionDate: DateTime(2027, 11),
      rating: 4.9,
      availableUnits: 18,
      totalUnits: 24,
      isFeatured: true,
      gallery: const [
        MediaItem(id: 'm7', type: MediaType.render, url: _photo3, isCover: true),
        MediaItem(id: 'm8', type: MediaType.photo, url: _photo1),
      ],
      buildings: [
        Building(
          id: 'prj-4-b1',
          projectId: 'prj-4',
          name: 'Block C',
          floors: 6,
          constructionProgress: 34,
          completionDate: DateTime(2027, 11),
          units: _units('prj-4-b1', dealType: DealType.sale),
        ),
      ],
      offers: [
        Offer(
          id: 'of-2',
          projectId: 'prj-4',
          type: OfferType.installment,
          title: '0% installment for 18 months',
          description: '40% down payment, the rest split monthly.',
          endsAt: DateTime(2026, 10, 31),
          downPaymentPercent: 0.4,
          termMonths: 18,
          interestRate: 0.0,
        ),
      ],
    ),
    Project(
      id: 'prj-5',
      name: 'Skyline Offices',
      type: ProjectType.businessCentre,
      status: ProjectStatus.planned,
      district: 'Yakkasaray',
      address: 'Shota Rustaveli St 9, Tashkent',
      lat: 41.2967,
      lng: 69.2721,
      developer: developers[3],
      description:
          'A planned Class-B business centre with flexible cabinet and '
          'open-plan office shells.',
      amenities: const ['Parking', 'Security', 'Coworking'],
      tags: const ['Office rent'],
      rentMin: 650,
      rentMax: 2100,
      constructionProgress: 8,
      plannedProgress: 27,
      completionDate: DateTime(2028, 3),
      rating: 4.2,
      availableUnits: 20,
      totalUnits: 24,
      gallery: const [
        MediaItem(id: 'm9', type: MediaType.render, url: _photo2, isCover: true),
      ],
      buildings: [
        Building(
          id: 'prj-5-b1',
          projectId: 'prj-5',
          name: 'Tower B',
          floors: 6,
          constructionProgress: 8,
          completionDate: DateTime(2028, 3),
          units: _units('prj-5-b1', dealType: DealType.rent),
        ),
      ],
    ),
  ];

  static Project projectById(String id) =>
      projects.firstWhere((p) => p.id == id, orElse: () => projects.first);

  /// Developer verification documents, keyed by developer id (plan section
  /// 11) — demoes all 3 states the disclaimer + per-document badge can be
  /// in: fully verified (`dev-1`), still under review (`dev-2`), and no
  /// documents uploaded yet (`dev-3`/`dev-4` are absent from this map, so the
  /// UI falls back to just the badge + disclaimer).
  static final documentsByDeveloper = <String, List<Document>>{
    'dev-1': [
      Document(
        id: 'doc-1',
        developerId: 'dev-1',
        type: DocumentType.license,
        fileUrl: '/uploads/dev-1-license.pdf',
        status: DocumentStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 110)),
      ),
      Document(
        id: 'doc-2',
        developerId: 'dev-1',
        type: DocumentType.constructionPermit,
        fileUrl: '/uploads/dev-1-permit.pdf',
        status: DocumentStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 118)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 108)),
      ),
      Document(
        id: 'doc-3',
        developerId: 'dev-1',
        type: DocumentType.landRights,
        fileUrl: '/uploads/dev-1-land.pdf',
        status: DocumentStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 118)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 105)),
      ),
      Document(
        id: 'doc-4',
        developerId: 'dev-1',
        type: DocumentType.projectDeclaration,
        fileUrl: '/uploads/dev-1-declaration.pdf',
        status: DocumentStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 115)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 100)),
      ),
    ],
    'dev-2': [
      Document(
        id: 'doc-5',
        developerId: 'dev-2',
        type: DocumentType.license,
        fileUrl: '/uploads/dev-2-license.pdf',
        status: DocumentStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
      Document(
        id: 'doc-6',
        developerId: 'dev-2',
        type: DocumentType.constructionPermit,
        fileUrl: '/uploads/dev-2-permit.pdf',
        status: DocumentStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ],
  };

  /// Construction-progress photo reports, keyed by project id (plan section
  /// 11) — only the two under-construction projects have entries, so the
  /// timeline's empty state also gets exercised (e.g. `prj-2`, `prj-3`).
  static final photoReportsByProject = <String, List<PhotoReport>>{
    'prj-1': [
      PhotoReport(
        id: 'pr-1',
        projectId: 'prj-1',
        buildingId: 'prj-1-b1',
        photoUrl: _photo1,
        takenAt: DateTime.now().subtract(const Duration(days: 150)),
        progressPercent: 20,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
      PhotoReport(
        id: 'pr-2',
        projectId: 'prj-1',
        buildingId: 'prj-1-b1',
        photoUrl: _photo3,
        takenAt: DateTime.now().subtract(const Duration(days: 95)),
        progressPercent: 38,
        createdAt: DateTime.now().subtract(const Duration(days: 95)),
      ),
      PhotoReport(
        id: 'pr-3',
        projectId: 'prj-1',
        buildingId: 'prj-1-b1',
        photoUrl: _photo4,
        takenAt: DateTime.now().subtract(const Duration(days: 60)),
        progressPercent: 50,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      PhotoReport(
        id: 'pr-4',
        projectId: 'prj-1',
        buildingId: 'prj-1-b1',
        photoUrl: _photo2,
        takenAt: DateTime.now().subtract(const Duration(days: 12)),
        progressPercent: 62,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ],
    'prj-4': [
      PhotoReport(
        id: 'pr-5',
        projectId: 'prj-4',
        buildingId: 'prj-4-b1',
        photoUrl: _photo3,
        takenAt: DateTime.now().subtract(const Duration(days: 70)),
        progressPercent: 15,
        createdAt: DateTime.now().subtract(const Duration(days: 70)),
      ),
      PhotoReport(
        id: 'pr-6',
        projectId: 'prj-4',
        buildingId: 'prj-4-b1',
        photoUrl: _photo1,
        takenAt: DateTime.now().subtract(const Duration(days: 8)),
        progressPercent: 34,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ],
  };

  static final leads = <Lead>[
    Lead(
      id: 'lead-1',
      number: 'LD-100241',
      projectId: 'prj-1',
      projectName: 'Aaradhya Homes',
      unitId: 'prj-1-b1-u2',
      unitLabel: 'Apartment 103',
      intent: LeadIntent.viewing,
      status: LeadStatus.scheduled,
      contactPhone: '+998 90 123 45 67',
      message: 'Prefer a weekend viewing.',
      preferredAt: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Lead(
      id: 'lead-2',
      number: 'LD-100238',
      projectId: 'prj-2',
      projectName: 'Nova Residence',
      intent: LeadIntent.callback,
      status: LeadStatus.contacted,
      contactPhone: '+998 90 123 45 67',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Lead(
      id: 'lead-3',
      number: 'LD-100201',
      projectId: 'prj-3',
      projectName: 'Victoria Business Centre',
      unitId: 'prj-3-b1-u5',
      unitLabel: 'Office 205',
      intent: LeadIntent.rent,
      status: LeadStatus.won,
      contactPhone: '+998 90 123 45 67',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];
}
