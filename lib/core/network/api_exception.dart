class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.data,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Object? data;

  @override
  String toString() => message;
}
