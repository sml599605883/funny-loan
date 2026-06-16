class CertificationPersonalInfoArgs {
  const CertificationPersonalInfoArgs({
    required this.title,
    required this.payloadMap,
  });

  factory CertificationPersonalInfoArgs.from(Object? arguments) {
    final routeArguments = arguments is Map
        ? arguments
        : const <String, dynamic>{};
    final payload = routeArguments['payload'];
    final payloadMap = payload is Map ? payload : const <String, dynamic>{};
    return CertificationPersonalInfoArgs(
      title: (payloadMap['nextStepTitle'] as String? ?? '').trim(),
      payloadMap: Map<String, dynamic>.from(payloadMap),
    );
  }

  final String title;
  final Map<String, dynamic> payloadMap;

  String get displayTitle {
    if (title.isNotEmpty) {
      return title;
    }
    return 'Personal information';
  }

  String get productId => (payloadMap['productId'] as String? ?? '').trim();

  String get orderNo => (payloadMap['orderNo'] as String? ?? '').trim();
}
