class SvnResult {
  final bool success;
  final String? errorMessage;
  final String? output;

  SvnResult({
    required this.success,
    this.errorMessage,
    this.output,
  });

  factory SvnResult.success(String output) {
    return SvnResult(
      success: true,
      output: output,
    );
  }

  factory SvnResult.error(String errorMessage) {
    return SvnResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}
