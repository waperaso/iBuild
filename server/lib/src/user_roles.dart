/// Account roles returned by `/v1/auth/otp/verify` in the `user.role` field.
///
/// B2C sign-ups always get [ordinaryUser]. B2B will introduce
/// [systemAdmin] and [residenceAdmin] when that app ships.
abstract class UserRole {
  static const ordinaryUser = 'ordinary_user';
  static const systemAdmin = 'system_admin';
  static const residenceAdmin = 'residence_admin';
}
