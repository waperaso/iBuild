/// Owner-submitted secondary rental listing (`dealType: rent`), moderated
/// before appearing in the public feed.
class RentalListing {
  const RentalListing({
    required this.id,
    required this.ownerUserId,
    required this.title,
    required this.description,
    required this.district,
    required this.address,
    this.lat,
    this.lng,
    required this.propertyKind,
    required this.areaTotal,
    this.rooms,
    required this.rentMonthly,
    this.minLeaseMonths = 12,
    required this.contactPhone,
    this.photos = const <String>[],
    this.isSecondary = true,
    this.moderationStatus = 'pending',
    this.moderationNote,
    this.isFeatured = false,
    this.createdAt,
  });

  final String id;
  final String ownerUserId;
  final String title;
  final String description;
  final String district;
  final String address;
  final double? lat;
  final double? lng;

  /// `apartment` | `office` | `retail`.
  final String propertyKind;
  final double areaTotal;
  final int? rooms;
  final double rentMonthly;
  final int minLeaseMonths;
  final String contactPhone;
  final List<String> photos;
  final bool isSecondary;

  /// `pending` | `approved` | `rejected`.
  final String moderationStatus;
  final String? moderationNote;
  final bool isFeatured;
  final DateTime? createdAt;

  bool get isPending => moderationStatus == 'pending';
  bool get isApproved => moderationStatus == 'approved';
  bool get isRejected => moderationStatus == 'rejected';

  factory RentalListing.fromJson(Map<String, dynamic> json) => RentalListing(
    id: json['id'] as String,
    ownerUserId: json['ownerUserId'] as String? ?? '',
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    district: json['district'] as String,
    address: json['address'] as String,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    propertyKind: json['propertyKind'] as String? ?? 'apartment',
    areaTotal: (json['areaTotal'] as num?)?.toDouble() ?? 0,
    rooms: (json['rooms'] as num?)?.toInt(),
    rentMonthly: (json['rentMonthly'] as num?)?.toDouble() ?? 0,
    minLeaseMonths: (json['minLeaseMonths'] as num?)?.toInt() ?? 12,
    contactPhone: json['contactPhone'] as String? ?? '',
    photos: (json['photos'] as List?)?.cast<String>() ?? const <String>[],
    isSecondary: json['isSecondary'] as bool? ?? true,
    moderationStatus: json['moderationStatus'] as String? ?? 'pending',
    moderationNote: json['moderationNote'] as String?,
    isFeatured: json['isFeatured'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerUserId': ownerUserId,
    'title': title,
    'description': description,
    'district': district,
    'address': address,
    'lat': lat,
    'lng': lng,
    'propertyKind': propertyKind,
    'areaTotal': areaTotal,
    'rooms': rooms,
    'rentMonthly': rentMonthly,
    'minLeaseMonths': minLeaseMonths,
    'contactPhone': contactPhone,
    'photos': photos,
    'isSecondary': isSecondary,
    'moderationStatus': moderationStatus,
    'moderationNote': moderationNote,
    'isFeatured': isFeatured,
    'createdAt': createdAt?.toIso8601String(),
  };
}
