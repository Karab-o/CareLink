class ServerResponse {
  final bool? success;
  final String? message;

  ServerResponse({this.message, this.success});

  factory ServerResponse.fromJson(Map<String, dynamic> json) {
    return ServerResponse(
      success: json['success'],
      message: json['message'],
    );
  }
}
