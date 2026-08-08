import 'package:ibuild_core/ibuild_core.dart';

/// NestOne + Hills Blue for offline/mock mode (`Env.useMockData`).
abstract class MockData {
  static const _nestonePhoto = '/v1/static/residences/nestone.png';
  static const _hillsPhoto = '/v1/static/residences/hillsblue.jpg';

  static const nestoneDeveloper = Developer(
    id: 'dev-nestone',
    name: 'NestOne Development',
    rating: 4.8,
    projectsCount: 1,
    phone: '+998 78 150 10 10',
    agentName: 'Madina Rakhimova',
    agentPhone: '+998 90 150 10 10',
  );

  static const hillsDeveloper = Developer(
    id: 'dev-hills-group',
    name: 'Hills Group',
    rating: 4.9,
    projectsCount: 1,
    phone: '+998 78 120 64 64',
    agentName: 'Dilshod Karimov',
    agentPhone: '+998 90 120 64 64',
  );

  static final developers = <Developer>[nestoneDeveloper, hillsDeveloper];

  static List<Unit> _hillsUnits(String buildingId) {
    const statuses = [
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
      final rooms = 1 + (i % 4);
      final area = 42.0 + (rooms - 1) * 19;
      final price = 46000.0 + rooms * 14000.0;
      return Unit(
        id: '$buildingId-u$floor$col',
        buildingId: buildingId,
        number: '$floor${(col + 1).toString().padLeft(2, '0')}',
        kind: UnitKind.apartment,
        dealType: DealType.sale,
        status: statuses[i % statuses.length],
        floor: floor,
        isOffplan: true,
        areaTotal: area,
        areaLiving: area * 0.86,
        rooms: rooms,
        price: price,
        priceM2: price / area,
        finishing: 'Pre-finish',
        view: const ['City', 'Courtyard', 'Park', 'Street'][col % 4],
        planColumn: col,
        planRow: floor - 1,
      );
    });
  }

  static List<Unit> _livingUnits() {
    const statuses = [
      UnitStatus.available,
      UnitStatus.reserved,
      UnitStatus.sold,
      UnitStatus.available,
    ];
    final units = <Unit>[];
    var i = 0;
    for (var floor = 1; floor <= 10; floor++) {
      for (var col = 0; col < 4; col++) {
        final rooms = 1 + (i % 4);
        final isRent = col == 3;
        final area = 44.0 + (rooms - 1) * 19;
        units.add(
          Unit(
            id: 'bld-nestone-living-u$floor$col',
            buildingId: 'bld-nestone-living',
            number: '$floor${(col + 1).toString().padLeft(2, '0')}',
            kind: UnitKind.apartment,
            dealType: isRent ? DealType.rent : DealType.sale,
            status: statuses[i % statuses.length],
            floor: floor,
            isOffplan: false,
            areaTotal: area,
            areaLiving: area * 0.86,
            rooms: rooms,
            price: isRent ? null : 52000 + rooms * 12000,
            priceM2: isRent ? null : (52000 + rooms * 12000) / area,
            rentMonthly: isRent ? 480 + rooms * 85 : null,
            rentM2: isRent ? (480 + rooms * 85) / area : null,
            minLeaseMonths: isRent ? 12 : null,
            finishing: isRent ? 'Turnkey' : 'Pre-finish',
            view: const ['City', 'Courtyard', 'Park', 'Street'][col % 4],
            planColumn: col,
            planRow: floor - 1,
          ),
        );
        i++;
      }
    }
    return units;
  }

  static List<Unit> _officeUnits() {
    const layouts = ['open-plan', 'cabinet', 'corner-suite'];
    const areas = [42.0, 68.0, 95.0];
    const statuses = [
      UnitStatus.available,
      UnitStatus.available,
      UnitStatus.reserved,
      UnitStatus.rented,
    ];
    final units = <Unit>[];
    var i = 0;
    for (var floor = 1; floor <= 8; floor++) {
      for (var col = 0; col < 3; col++) {
        final area = areas[col];
        final rent = 950 + area * 4.2;
        units.add(
          Unit(
            id: 'bld-nestone-office-u$floor$col',
            buildingId: 'bld-nestone-office',
            number: 'O$floor${(col + 1).toString().padLeft(2, '0')}',
            kind: UnitKind.office,
            dealType: DealType.rent,
            status: statuses[i % statuses.length],
            floor: floor,
            isOffplan: false,
            areaTotal: area,
            layout: layouts[col],
            rentMonthly: rent,
            rentM2: rent / area,
            minLeaseMonths: 12,
            finishing: 'Turnkey',
            view: 'City',
            planColumn: col,
            planRow: floor - 1,
          ),
        );
        i++;
      }
    }
    return units;
  }

  static final projects = <Project>[
    Project(
      id: 'prj-nestone',
      name: 'NestOne',
      type: ProjectType.residentialComplex,
      status: ProjectStatus.ready,
      district: 'Shayxontohur',
      address: 'Amir Temur shoh ko\'chasi, Shayxontohur, Tashkent',
      lat: 41.31215655652716,
      lng: 69.25275117116448,
      developer: nestoneDeveloper,
      description:
          'NestOne is a completed mixed-use complex in Shayxontohur: sale and rent '
          'apartments in a 10-storey living tower plus Class-A offices with live '
          'availability on an interactive floor grid.',
      amenities: const [
        'Underground parking',
        'Gym',
        'Concierge',
        'Coworking lounge',
        'Landscaped courtyard',
        '24/7 security',
        'High-speed elevators',
      ],
      tags: const [
        'Premium',
        'Ready to move',
        'Apartments',
        'Offices',
        'Rent',
        'Installments',
      ],
      priceMin: 64000,
      priceMax: 100000,
      rentMin: 565,
      rentMax: 1350,
      constructionProgress: 100,
      plannedProgress: 100,
      completionDate: DateTime(2024, 12),
      rating: 4.8,
      availableUnits: 30,
      totalUnits: 64,
      isFeatured: true,
      gallery: const [
        MediaItem(
          id: 'med-nestone-cover',
          type: MediaType.photo,
          url: _nestonePhoto,
          isCover: true,
        ),
      ],
      buildings: [
        Building(
          id: 'bld-nestone-living',
          projectId: 'prj-nestone',
          name: 'Living Tower',
          floors: 10,
          constructionProgress: 100,
          completionDate: DateTime(2024, 12),
          units: _livingUnits(),
        ),
        Building(
          id: 'bld-nestone-office',
          projectId: 'prj-nestone',
          name: 'Office Wing',
          floors: 8,
          constructionProgress: 100,
          completionDate: DateTime(2024, 12),
          units: _officeUnits(),
        ),
      ],
      offers: [
        Offer(
          id: 'off-nestone-installment',
          projectId: 'prj-nestone',
          type: OfferType.installment,
          title: 'Flexible installment plan',
          description: '25% down payment, balance in equal monthly payments.',
          endsAt: null,
          downPaymentPercent: 0.25,
          termMonths: 30,
          interestRate: 0.0,
        ),
      ],
    ),
    Project(
      id: 'prj-hills-blue',
      name: 'Hills Blue',
      type: ProjectType.residentialComplex,
      status: ProjectStatus.underConstruction,
      district: 'Yunusabad',
      address: 'Chingiz Aitmatov ko\'chasi 37B, Badamzar, Tashkent',
      lat: 41.3528,
      lng: 69.3012,
      developer: hillsDeveloper,
      description:
          'Premium residential complex by Hills Group in Yunusabad\'s Badamzar '
          'district: twin 22-storey towers with asymmetric facades, underground '
          'parking and white-box handover. Completion Q1 2027.',
      amenities: const [
        'Underground parking',
        'Landscaped courtyard',
        'Gym',
        '24/7 security',
        'High-speed elevators',
        'Concierge',
        'Smart home systems',
      ],
      tags: const ['Premium', 'New build', 'Installments'],
      priceMin: 60000,
      priceMax: 102000,
      constructionProgress: 38,
      plannedProgress: 42,
      completionDate: DateTime(2027, 3),
      rating: 4.9,
      availableUnits: 28,
      totalUnits: 48,
      isFeatured: true,
      gallery: const [
        MediaItem(
          id: 'med-hills-cover',
          type: MediaType.photo,
          url: _hillsPhoto,
          isCover: true,
        ),
        MediaItem(
          id: 'med-hills-banner',
          type: MediaType.photo,
          url: '/v1/static/residences/hills-blue-banner.webp',
          sortOrder: 1,
        ),
      ],
      buildings: [
        Building(
          id: 'bld-hills-t1',
          projectId: 'prj-hills-blue',
          name: 'Tower 1',
          floors: 22,
          constructionProgress: 42,
          completionDate: DateTime(2027, 3),
          units: _hillsUnits('bld-hills-t1'),
        ),
        Building(
          id: 'bld-hills-t2',
          projectId: 'prj-hills-blue',
          name: 'Tower 2',
          floors: 22,
          constructionProgress: 35,
          completionDate: DateTime(2027, 3),
          units: _hillsUnits('bld-hills-t2'),
        ),
      ],
      offers: [
        Offer(
          id: 'off-hills-installment',
          projectId: 'prj-hills-blue',
          type: OfferType.installment,
          title: 'Flexible installment until handover',
          description: '30% down payment, balance split monthly until Q1 2027.',
          endsAt: DateTime(2027, 1),
          downPaymentPercent: 0.3,
          termMonths: 24,
          interestRate: 0.0,
        ),
      ],
    ),
  ];

  static Project projectById(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    throw StateError('Project not found: $id');
  }

  static final documentsByDeveloper = <String, List<Document>>{};
  static final photoReportsByProject = <String, List<PhotoReport>>{};
  static final leads = <Lead>[];
}
