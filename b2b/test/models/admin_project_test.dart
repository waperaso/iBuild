import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild_b2b/models/admin_project.dart';
import 'package:ibuild_b2b/models/developer_profile.dart';

void main() {
  group('AdminProject.fromJson', () {
    test('parses core fields from a full payload', () {
      final project = AdminProject.fromJson({
        'id': 'p1',
        'name': 'Sunrise Residence',
        'district': 'Yunusabad',
        'address': 'Amir Temur 12',
        'moderationStatus': 'approved',
        'isPublished': true,
        'extra': 'kept in raw',
      });

      expect(project.id, 'p1');
      expect(project.name, 'Sunrise Residence');
      expect(project.district, 'Yunusabad');
      expect(project.address, 'Amir Temur 12');
      expect(project.moderationStatus, 'approved');
      expect(project.isPublished, isTrue);
      // Unmodelled fields survive on `raw`.
      expect(project.raw['extra'], 'kept in raw');
    });

    test('falls back gracefully on a sparse payload', () {
      final project = AdminProject.fromJson({});
      expect(project.id, '');
      expect(project.name, '');
      expect(project.moderationStatus, '—');
      expect(project.isPublished, isFalse);
    });

    test('coerces a string boolean for isPublished', () {
      final project = AdminProject.fromJson({'isPublished': 'true'});
      expect(project.isPublished, isTrue);
    });
  });

  group('DeveloperProfile.fromJson', () {
    test('parses publish state and subscription price', () {
      final dev = DeveloperProfile.fromJson({
        'id': 'd1',
        'name': 'Acme Build',
        'canPublish': true,
        'subscriptionPriceUsd': 349,
      });
      expect(dev.id, 'd1');
      expect(dev.name, 'Acme Build');
      expect(dev.canPublish, isTrue);
      expect(dev.subscriptionPriceUsd, 349);
    });

    test('defaults the subscription price to 299 when absent', () {
      final dev = DeveloperProfile.fromJson({'id': 'd1'});
      expect(dev.canPublish, isFalse);
      expect(dev.subscriptionPriceUsd, 299);
    });
  });
}
