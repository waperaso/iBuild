import 'package:ibuild_core/ibuild_core.dart';

/// Local discovery filter snapshot (SharedPreferences; not a wire model).
class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.label,
    required this.mode,
    this.searchText = '',
    this.district,
    this.status,
    this.minPrice,
    this.maxPrice,
    this.notifyOnMatch = false,
    required this.createdAt,
  });

  final String id;
  final String label;
  final DiscoveryMode mode;
  final String searchText;
  final String? district;
  final ProjectStatus? status;
  final double? minPrice;
  final double? maxPrice;
  final bool notifyOnMatch;
  final DateTime createdAt;

  SavedSearch copyWith({bool? notifyOnMatch}) => SavedSearch(
    id: id,
    label: label,
    mode: mode,
    searchText: searchText,
    district: district,
    status: status,
    minPrice: minPrice,
    maxPrice: maxPrice,
    notifyOnMatch: notifyOnMatch ?? this.notifyOnMatch,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'mode': mode.name,
    'searchText': searchText,
    'district': district,
    'status': status?.name,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'notifyOnMatch': notifyOnMatch,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedSearch.fromJson(Map<String, dynamic> json) => SavedSearch(
    id: json['id'] as String,
    label: json['label'] as String,
    mode:
        DiscoveryMode.values.cast<DiscoveryMode?>().firstWhere(
          (m) => m?.name == json['mode'],
          orElse: () => null,
        ) ??
        DiscoveryMode.buy,
    searchText: json['searchText'] as String? ?? '',
    district: json['district'] as String?,
    status: ProjectStatus.values.cast<ProjectStatus?>().firstWhere(
      (s) => s?.name == json['status'],
      orElse: () => null,
    ),
    minPrice: (json['minPrice'] as num?)?.toDouble(),
    maxPrice: (json['maxPrice'] as num?)?.toDouble(),
    notifyOnMatch: json['notifyOnMatch'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
