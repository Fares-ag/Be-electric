import 'package:cmms_core/utils/review_photo_upload_decision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluateReviewPhotoUpload', () {
    test('no photos selected — create work order', () {
      final decision = evaluateReviewPhotoUpload(
        selectedPhotoCount: 0,
        uploadedCount: 0,
        failCount: 0,
      );

      expect(decision.shouldCreateWorkOrder, isTrue);
      expect(decision.partialSuccessMessage, isNull);
      expect(decision.failureMessage, isNull);
    });

    test('all uploads fail — do not create work order', () {
      final decision = evaluateReviewPhotoUpload(
        selectedPhotoCount: 3,
        uploadedCount: 0,
        failCount: 3,
      );

      expect(decision.shouldCreateWorkOrder, isFalse);
      expect(decision.failureMessage, isNotNull);
      expect(decision.failureMessage, contains('not submitted'));
      expect(decision.partialSuccessMessage, isNull);
    });

    test('partial success — create work order with message', () {
      final decision = evaluateReviewPhotoUpload(
        selectedPhotoCount: 5,
        uploadedCount: 3,
        failCount: 2,
      );

      expect(decision.shouldCreateWorkOrder, isTrue);
      expect(decision.failureMessage, isNull);
      expect(
        decision.partialSuccessMessage,
        'Request submitted successfully. 3 of 5 photos were attached.',
      );
    });

    test('full success — create work order without partial message', () {
      final decision = evaluateReviewPhotoUpload(
        selectedPhotoCount: 2,
        uploadedCount: 2,
        failCount: 0,
      );

      expect(decision.shouldCreateWorkOrder, isTrue);
      expect(decision.partialSuccessMessage, isNull);
      expect(decision.failureMessage, isNull);
    });
  });
}
