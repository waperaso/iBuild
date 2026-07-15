import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'media.freezed.dart';
part 'media.g.dart';

@freezed
abstract class MediaItem with _$MediaItem {
  const factory MediaItem({
    required String id,
    required MediaType type,
    required String url,
    @Default(0) int sortOrder,
    @Default(false) bool isCover,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}
