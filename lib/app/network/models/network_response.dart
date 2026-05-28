class NetworkResponse<T> {
  static const int malformedResponseCode = -1;
  static const String malformedResponseMessage = 'Illegal response format';

  const NetworkResponse({
    required this.code,
    required this.message,
    required this.data,
    this.raw,
  });

  final int code;
  final String message;
  final T? data;
  final Object? raw;

  bool get isMalformed => code == malformedResponseCode;

  bool isSuccessWith(Set<int> successCodes) => successCodes.contains(code);

  factory NetworkResponse.fromDynamic(
    dynamic json, {
    String codeKey = 'code',
    String messageKey = 'msg',
    String alternateMessageKey = 'message',
    String dataKey = 'data',
    int malformedCode = malformedResponseCode,
    String malformedMessage = malformedResponseMessage,
  }) {
    if (json is! Map<String, dynamic>) {
      return NetworkResponse<T>(
        code: malformedCode,
        message: malformedMessage,
        data: null,
        raw: json,
      );
    }

    final dynamic codeValue = json[codeKey];
    final dynamic messageValue = json[messageKey] ?? json[alternateMessageKey];
    final int parsedCode = codeValue is num
        ? codeValue.toInt()
        : int.tryParse(codeValue?.toString() ?? '') ?? malformedCode;

    return NetworkResponse<T>(
      code: parsedCode,
      message: messageValue?.toString() ?? malformedMessage,
      data: json[dataKey] as T?,
      raw: json,
    );
  }
}
