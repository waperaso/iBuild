import 'user_roles.dart';

/// Synthetic admin/CRM payloads for awards demo sessions — no real phones,
/// INN/PINFL, leads, or user records from production.
class DemoSnapshot {
  DemoSnapshot._();

  static Map<String, dynamic> listMeta(int total) => {
    'total': total,
    'demo': true,
  };

  static List<Map<String, dynamic>> users() => [
    {
      'id': 'demo-user-b2b-platform',
      'phone': '+998900000001',
      'name': 'Demo Reviewer (Admin)',
      'role': UserRole.systemAdmin,
      'isDemo': true,
    },
    {
      'id': 'demo-user-sample-residence',
      'phone': '+998900001002',
      'name': 'Sample Residence Admin',
      'role': UserRole.residenceAdmin,
    },
    {
      'id': 'demo-user-sample-buyer',
      'phone': '+998900001003',
      'name': 'Sample Buyer',
      'role': UserRole.ordinaryUser,
    },
  ];

  static Map<String, dynamic> analytics() => {
    'usersTotal': 128,
    'projectsTotal': 12,
    'publishedProjects': 8,
    'leadsTotal': 34,
    'developersPending': 2,
    'projectsPending': 1,
    'developersTotal': 6,
    'subscriptionsActive': 4,
    'subscriptionsByPlan': {'growth': 3, 'starter': 1},
    'businessesUnpaid': 2,
    'subscriptionPriceUsd': 99,
    'reviewsPendingModeration': 1,
    'reviewsTotal': 18,
    'rentalListingsPending': 1,
    'rentalListingsApproved': 5,
    'demo': true,
  };

  static List<Map<String, dynamic>> leads({String? projectId}) => [
    {
      'id': 'demo-lead-1',
      'number': 'LD-DEMO-1',
      'projectId': projectId ?? 'demo-project-1',
      'projectName': 'Demo Towers',
      'intent': 'viewing',
      'status': 'new',
      'contactPhone': '+998900002001',
      'message': 'Interested in a 2-room apartment (demo).',
      'createdAt': '2026-01-15T10:00:00.000Z',
    },
    {
      'id': 'demo-lead-2',
      'number': 'LD-DEMO-2',
      'projectId': projectId ?? 'demo-project-1',
      'projectName': 'Demo Towers',
      'intent': 'call',
      'status': 'contacted',
      'contactPhone': '+998900002002',
      'message': 'Please call back after 18:00 (demo).',
      'createdAt': '2026-01-14T14:30:00.000Z',
    },
  ];

  static List<Map<String, dynamic>> crmAssignees() => [
    {
      'id': 'demo-user-b2b-platform',
      'name': 'Demo Reviewer (Admin)',
      'phone': '+998900000001',
      'role': UserRole.systemAdmin,
    },
    {
      'id': 'demo-user-sample-residence',
      'name': 'Sample Residence Admin',
      'phone': '+998900001002',
      'role': UserRole.residenceAdmin,
    },
  ];

  static List<Map<String, dynamic>> leadEvents(String leadId) => [
    {
      'id': 'demo-event-1',
      'leadId': leadId,
      'type': 'created',
      'note': 'Lead created (demo data)',
      'createdAt': '2026-01-15T10:00:00.000Z',
    },
  ];

  static List<Map<String, dynamic>> pendingDevelopers() => [
    {
      'id': 'demo-developer-pending',
      'name': 'Demo Construction LLC',
      'legalName': 'Demo Construction LLC',
      'inn': '123456789',
      'verificationStatus': 'pending',
      'accountKind': 'property_developer',
      'directorFullName': 'Demo Director',
      'directorPinfl': '12345678901234',
      'legalAddress': 'Tashkent, demo street 1',
    },
  ];

  static List<Map<String, dynamic>> developerDocuments(String developerId) => [
    {
      'id': 'demo-doc-1',
      'developerId': developerId,
      'type': 'license',
      'status': 'pending',
      'fileUrl': '/v1/static/demo/license.pdf',
      'uploadedAt': '2026-01-10T09:00:00.000Z',
    },
  ];

  static List<Map<String, dynamic>> pendingProjects() => [
    {
      'id': 'demo-project-pending',
      'name': 'Demo Residence (pending review)',
      'type': 'residential_complex',
      'moderationStatus': 'pending_review',
      'isPublished': false,
      'district': 'Yunusabad',
      'developer': {
        'id': 'demo-developer-pending',
        'name': 'Demo Construction LLC',
      },
    },
  ];

  static List<Map<String, dynamic>> businesses() => [
    {
      'id': 'demo-developer-active',
      'name': 'Demo Builder Co.',
      'legalName': 'Demo Builder Co.',
      'inn': '987654321',
      'verificationStatus': 'approved',
      'paymentStatus': 'active',
      'canPublish': true,
      'subscription': {'planId': 'growth', 'status': 'active'},
    },
  ];

  static List<Map<String, dynamic>> tickets({String? status}) {
    final items = [
      {
        'id': 'demo-ticket-1',
        'subject': 'How do I publish a project? (demo)',
        'status': 'open',
        'category': 'billing',
        'userName': 'Sample Buyer',
        'userPhone': '+998900001003',
        'createdAt': '2026-01-12T08:00:00.000Z',
        'messages': [
          {
            'authorName': 'Sample Buyer',
            'message': 'Need help with publishing (demo).',
            'createdAt': '2026-01-12T08:00:00.000Z',
          },
        ],
      },
    ];
    if (status == null || status.isEmpty) return items;
    return items.where((t) => t['status'] == status).toList();
  }

  static Map<String, dynamic>? ticketById(String id) {
    for (final t in tickets()) {
      if (t['id'] == id) return t;
    }
    return null;
  }

  static List<Map<String, dynamic>> auditLog({int limit = 100}) => [
    {
      'id': 'demo-audit-1',
      'action': 'project.approve',
      'targetType': 'project',
      'targetId': 'demo-project-1',
      'actorUserId': 'demo-user-b2b-platform',
      'detail': 'Demo moderation event',
      'createdAt': '2026-01-11T12:00:00.000Z',
    },
  ].take(limit).toList();

  static List<Map<String, dynamic>> notifications() => [
    {
      'id': 'demo-notif-1',
      'type': 'project_submitted',
      'title': 'Project submitted for review (demo)',
      'body': 'Demo Residence was submitted for moderation.',
      'read': false,
      'createdAt': '2026-01-13T16:00:00.000Z',
    },
  ];

  static List<Map<String, dynamic>> pendingReviews() => [
    {
      'id': 'demo-review-1',
      'projectName': 'Demo Towers',
      'ratingOverall': 4,
      'comment': 'Great location (demo review).',
      'userName': 'Anonymous',
      'moderationStatus': 'pending',
    },
  ];

  static List<Map<String, dynamic>> pendingRentalListings() => [
    {
      'id': 'demo-rental-1',
      'title': '2-room near metro (demo)',
      'district': 'Mirabad',
      'monthlyRent': 650,
      'contactPhone': '+998900003001',
      'moderationStatus': 'pending',
    },
  ];

  static Map<String, dynamic> myDeveloper() => {
    'id': 'demo-developer-residence',
    'name': 'Demo Residence Admin Co.',
    'legalName': 'Demo Residence Admin Co.',
    'inn': '111222333',
    'verificationStatus': 'approved',
    'accountKind': 'property_developer',
    'paymentStatus': 'active',
    'canPublish': true,
    'subscriptionPriceUsd': 99,
    'subscription': {'planId': 'growth', 'status': 'active'},
    'demo': true,
  };

  static List<Map<String, dynamic>> myDocuments() =>
      developerDocuments('demo-developer-residence');

  static List<Map<String, dynamic>> myProjects() => [
    {
      'id': 'demo-project-residence',
      'name': 'Demo Residence Showcase',
      'type': 'residential_complex',
      'moderationStatus': 'approved',
      'isPublished': true,
      'district': 'Yunusabad',
    },
  ];

  static Map<String, dynamic> projectAnalytics(String projectId) => {
    'projectId': projectId,
    'views': 420,
    'leads': 12,
    'favorites': 8,
    'demo': true,
  };
}
