/// Outcome of photo uploads on the requestor review/submit screen.
class ReviewPhotoUploadDecision {
  const ReviewPhotoUploadDecision({
    required this.shouldCreateWorkOrder,
    this.partialSuccessMessage,
    this.failureMessage,
  });

  /// When false, all selected photos failed to upload — do not create a WO.
  final bool shouldCreateWorkOrder;

  /// Shown after a successful submit when some (not all) photos uploaded.
  final String? partialSuccessMessage;

  /// Shown when all photo uploads fail — submit is aborted.
  final String? failureMessage;
}

/// Decides whether to create a work order based on photo upload results.
ReviewPhotoUploadDecision evaluateReviewPhotoUpload({
  required int selectedPhotoCount,
  required int uploadedCount,
  required int failCount,
}) {
  if (selectedPhotoCount == 0) {
    return const ReviewPhotoUploadDecision(shouldCreateWorkOrder: true);
  }

  if (failCount == selectedPhotoCount) {
    return const ReviewPhotoUploadDecision(
      shouldCreateWorkOrder: false,
      failureMessage:
          'Photos could not be uploaded. Your request was not submitted. '
          'Check your connection and try again.',
    );
  }

  if (failCount > 0) {
    return ReviewPhotoUploadDecision(
      shouldCreateWorkOrder: true,
      partialSuccessMessage:
          'Request submitted successfully. $uploadedCount of $selectedPhotoCount photos were attached.',
    );
  }

  return const ReviewPhotoUploadDecision(shouldCreateWorkOrder: true);
}
