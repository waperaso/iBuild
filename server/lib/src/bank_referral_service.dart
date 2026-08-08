import 'dart:convert';
import 'dart:io';

import 'env_loader.dart';

/// Bank referral POST to `BANK_PARTNER_API_URL`, or log + local ref if unset.
class BankReferralService {
  BankReferralService();

  bool get isDevMode {
    final url = appEnv()['BANK_PARTNER_API_URL'];
    return url == null || url.isEmpty;
  }

  /// Submit referral; returns provider reference id.
  Future<String> submitReferral({
    required String referralId,
    required String contactPhone,
    required double price,
    required double downPayment,
    required int termYears,
    String? projectId,
    String? unitId,
    String? bankName,
  }) async {
    if (isDevMode) {
      stderr.writeln(
        '[BankReferralService] DEV referral $referralId → '
        '${bankName ?? "default partner bank"}: phone=$contactPhone '
        'price=$price down=$downPayment term=${termYears}y '
        'project=$projectId unit=$unitId',
      );
      return 'dev-ref-$referralId';
    }
    final url = appEnv()['BANK_PARTNER_API_URL']!;
    final apiKey = appEnv()['BANK_PARTNER_API_KEY'];
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      if (apiKey != null && apiKey.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $apiKey');
      }
      // jsonEncode: user-supplied fields must not reshape the bank payload.
      request.write(
        jsonEncode({
          'referralId': referralId,
          'contactPhone': contactPhone,
          'price': price,
          'downPayment': downPayment,
          'termYears': termYears,
          'projectId': projectId,
          'unitId': unitId,
        }),
      );
      final response = await request.close();
      final body = await response.transform(SystemEncoding().decoder).join();
      if (response.statusCode >= 400) {
        stderr.writeln(
          '[BankReferralService] Partner error ${response.statusCode}: $body',
        );
        return 'error-ref-$referralId';
      }
      return 'sent-ref-$referralId';
    } catch (error, stack) {
      stderr.writeln(
        '[BankReferralService] Failed to submit referral: $error\n$stack',
      );
      return 'error-ref-$referralId';
    } finally {
      client.close(force: true);
    }
  }
}
