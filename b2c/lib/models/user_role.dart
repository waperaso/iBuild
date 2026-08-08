/// `user.role` values from `/v1/auth/otp/verify`.
abstract class UserRole {
  static const ordinaryUser = 'ordinary_user';
  static const systemAdmin = 'system_admin';
  static const residenceAdmin = 'residence_admin';
}
