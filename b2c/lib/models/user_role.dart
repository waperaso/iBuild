/// Account role returned by `/v1/auth/otp/verify` in `user.role`.
///
/// Every B2C sign-up is tagged [ordinaryUser]. B2B will add [systemAdmin] and
/// [residenceAdmin] when that app ships.
abstract class UserRole {
  static const ordinaryUser = 'ordinary_user';
  static const systemAdmin = 'system_admin';
  static const residenceAdmin = 'residence_admin';
}
