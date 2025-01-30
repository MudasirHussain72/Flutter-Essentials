class ApiResponse<T> {
  final Status status;
  final T? data;
  final String? message;
  final bool isSyncing;

  // Private constructor for field initialization
  ApiResponse._(this.status, this.data, this.message, {this.isSyncing = false});

  // Initial state
  ApiResponse.initial() : this._(Status.initial, null, null);

  // Loading state
  ApiResponse.loading() : this._(Status.loading, null, null);

  // Completed state
  ApiResponse.completed(T data) : this._(Status.completed, data, null);

  // Error state
  ApiResponse.error(String message) : this._(Status.error, null, message);

  // Syncing state
  ApiResponse.syncing(T data)
      : this._(Status.completed, data, null, isSyncing: true);

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $data";
  }

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(Object?) fromJsonT) {
    final status = Status.values[json['status'] as int];
    final data = json['data'] != null ? fromJsonT(json['data']) : null;
    final message = json['message'] as String?;
    final isSyncing = json['isSyncing'] as bool? ?? false;

    return ApiResponse._(status, data, message, isSyncing: isSyncing);
  }

  Map<String, dynamic> toJson(Object Function(T) toJsonT) {
    return {
      'status': status.index,
      'data': data != null ? toJsonT(data!) : null,
      'message': message,
      'isSyncing': isSyncing,
    };
  }
}

enum Status { initial, loading, completed, error }
