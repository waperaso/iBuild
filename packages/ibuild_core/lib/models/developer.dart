import 'package:freezed_annotation/freezed_annotation.dart';

part 'developer.freezed.dart';
part 'developer.g.dart';

@freezed
abstract class Developer with _$Developer {
  const factory Developer({
    required String id,
    required String name,
    String? logoUrl,
    @Default(0) double rating,
    @Default(0) int projectsCount,

    /// Developer/sales-office contact number.
    String? phone,

    /// Assigned realtor/sales agent for this project, if any.
    String? agentName,
    String? agentPhone,
    String? agentAvatarUrl,
  }) = _Developer;

  factory Developer.fromJson(Map<String, dynamic> json) =>
      _$DeveloperFromJson(json);
}
