import '../config.dart';

/// Pre-filled feedback email, so testers' reports arrive with the details we need.
/// No coordinates or personal data are included.
String buildFeedbackBody({
  required String androidVersion,
  required bool isPro,
  required String language,
  required String photoSize,
  required String gps,
  required String placeName,
}) {
  return 'Please describe what happened, and what you expected:\n\n\n\n'
      '---- App details (please keep) ----\n'
      'App: SiteStamp $kAppVersion (build $kBuildNumber)\n'
      'Android: $androidVersion\n'
      'Plan: ${isPro ? 'Pro' : 'Free'}\n'
      'Language: $language\n'
      'Photo size: $photoSize\n'
      'GPS: $gps\n'
      'Place name: $placeName\n';
}

/// mailto: link. Uses %20 for spaces (Uri.queryParameters would use "+", which
/// many mail apps show literally).
Uri feedbackUri({
  required String to,
  required String subject,
  required String body,
}) {
  return Uri.parse(
    'mailto:$to?subject=${Uri.encodeComponent(subject)}'
    '&body=${Uri.encodeComponent(body)}',
  );
}
