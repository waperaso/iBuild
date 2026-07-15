import 'dart:io';

import 'env_loader.dart';

/// Mortgage/installment bank-referral delivery (Konseptsiya §11.C —
/// "комиссия от банков за приведённых клиентов").
///
/// Production wiring is entirely environment-driven: set `BANK_PARTNER_API_URL`
/// (+ optionally `BANK_PARTNER_API_KEY`) to POST referrals to a real partner
/// bank/aggregator. With neither set (the default local/dev setup) this
/// simply logs the referral and returns a locally-generated reference id, so
/// the calculator → lead-gen flow is fully exercised without any external
/// dependency.
class BankReferralService {
  BankReferralService();

  bool get isDevMode {
    final url = appEnv()['BANK_PARTNER_API_URL'];
    return url == null || url.isEmpty;
  }

  /// Submits a mortgage/installment referral to the configured bank partner
  /// adapter. Returns a provider reference id.
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
      request.write('''{
        "referralId": "$referralId",
        "contactPhone": "$contactPhone",
        "price": $price,
        "downPayment": $downPayment,
        "termYears": $termYears,
        "projectId": ${projectId == null ? 'null' : '"$projectId"'},
        "unitId": ${unitId == null ? 'null' : '"$unitId"'}
      }''');
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
