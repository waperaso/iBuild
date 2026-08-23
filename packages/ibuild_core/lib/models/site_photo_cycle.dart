/// One A→B construction-photo cycle for a project.
class SitePhotoCycle {
  const SitePhotoCycle({
    required this.id,
    required this.projectId,
    required this.status,
    required this.intervalDays,
    this.intervalMinutes,
    this.dueAt,
    this.windowEndAt,
    this.photoA,
    this.photoB,
    this.canUploadA = false,
    this.canUploadB = false,
    this.canUnlockFollowUp = false,
    this.tooEarlyUntil,
    this.reuploadLockedUntil,
    this.developerId,
    this.developerName,
    this.projectName,
    this.stubVerdict,
    this.vendorCall,
    this.result,
    this.verifyExport,
    this.govNotifiedAt,
  });

  final String id;
  final String projectId;
  final String status;
  final int intervalDays;
  final int? intervalMinutes;
  final DateTime? dueAt;
  final DateTime? windowEndAt;
  final SitePhotoRef? photoA;
  final SitePhotoRef? photoB;
  final bool canUploadA;
  final bool canUploadB;
  final bool canUnlockFollowUp;
  final DateTime? tooEarlyUntil;
  final DateTime? reuploadLockedUntil;
  final String? developerId;
  final String? developerName;
  final String? projectName;
  final String? stubVerdict;
  final Map<String, dynamic>? vendorCall;
  final Map<String, dynamic>? result;
  final Map<String, dynamic>? verifyExport;
  final DateTime? govNotifiedAt;

  bool get isReuploadLocked {
    final until = reuploadLockedUntil;
    if (until == null) return false;
    return DateTime.now().toUtc().isBefore(until.toUtc());
  }

  factory SitePhotoCycle.fromJson(Map<String, dynamic> json) {
    return SitePhotoCycle(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      status: json['status'] as String,
      intervalDays: (json['intervalDays'] as num?)?.round() ?? 14,
      intervalMinutes: (json['intervalMinutes'] as num?)?.round(),
      dueAt: _dt(json['dueAt']),
      windowEndAt: _dt(json['windowEndAt']),
      photoA: json['photoA'] is Map
          ? SitePhotoRef.fromJson(Map<String, dynamic>.from(json['photoA'] as Map))
          : null,
      photoB: json['photoB'] is Map
          ? SitePhotoRef.fromJson(Map<String, dynamic>.from(json['photoB'] as Map))
          : null,
      canUploadA: json['canUploadA'] == true,
      canUploadB: json['canUploadB'] == true,
      canUnlockFollowUp: json['canUnlockFollowUp'] == true,
      tooEarlyUntil: _dt(json['tooEarlyUntil']),
      reuploadLockedUntil: _dt(json['reuploadLockedUntil']),
      developerId: json['developerId'] as String?,
      developerName: json['developerName'] as String?,
      projectName: json['projectName'] as String?,
      stubVerdict: json['stubVerdict'] as String?,
      vendorCall: json['vendorCall'] is Map
          ? Map<String, dynamic>.from(json['vendorCall'] as Map)
          : null,
      result: json['result'] is Map
          ? Map<String, dynamic>.from(json['result'] as Map)
          : null,
      verifyExport: json['verifyExport'] is Map
          ? Map<String, dynamic>.from(json['verifyExport'] as Map)
          : null,
      govNotifiedAt: _dt(json['govNotifiedAt']),
    );
  }

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

class SitePhotoRef {
  const SitePhotoRef({
    required this.id,
    required this.photoUrl,
    required this.takenAt,
  });

  final String id;
  final String photoUrl;
  final String takenAt;

  factory SitePhotoRef.fromJson(Map<String, dynamic> json) {
    return SitePhotoRef(
      id: json['id'] as String,
      photoUrl: json['photoUrl'] as String? ?? '',
      takenAt: json['takenAt'] as String? ?? '',
    );
  }
}
