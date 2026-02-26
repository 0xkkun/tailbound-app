/// Typed model for incoming bridge messages from the WebView.
///
/// Replaces raw `Map<String, dynamic>` parsing with type-safe access.
class BridgeMessage {
  /// Unique message identifier for request-response correlation.
  final String id;

  /// Message type indicating the command (e.g., 'ad.request', 'storage.get').
  final String type;

  /// Payload data associated with the message.
  final Map<String, dynamic> payload;

  /// Creates a [BridgeMessage] with the given [id], [type], and [payload].
  const BridgeMessage({
    required this.id,
    required this.type,
    required this.payload,
  });

  /// Parses a [BridgeMessage] from a decoded JSON map.
  ///
  /// Throws [FormatException] if required fields are missing or have wrong types.
  factory BridgeMessage.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    final payload = json['payload'];

    if (id is! String) {
      throw const FormatException('BridgeMessage: "id" must be a String');
    }
    if (type is! String) {
      throw const FormatException('BridgeMessage: "type" must be a String');
    }
    if (payload is! Map<String, dynamic>) {
      throw const FormatException(
        'BridgeMessage: "payload" must be a Map<String, dynamic>',
      );
    }

    return BridgeMessage(id: id, type: type, payload: payload);
  }

  /// Safely retrieves a [String] value from [payload] by [key].
  ///
  /// Returns [defaultValue] if the key is missing or not a String.
  String getString(String key, {String defaultValue = ''}) {
    final value = payload[key];
    return value is String ? value : defaultValue;
  }

  /// Safely retrieves an optional [String] value from [payload] by [key].
  String? getStringOrNull(String key) {
    final value = payload[key];
    return value is String ? value : null;
  }

  /// Safely retrieves a nested [Map] from [payload] by [key].
  Map<String, dynamic>? getMapOrNull(String key) {
    final value = payload[key];
    return value is Map<String, dynamic> ? value : null;
  }

  /// Safely retrieves an [int] value from [payload] by [key].
  int? getIntOrNull(String key) {
    final value = payload[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() => 'BridgeMessage(id: $id, type: $type)';
}

/// Typed model for bridge response sent back to the WebView.
class BridgeResponse {
  /// The original message [id] this response correlates to.
  final String id;

  /// The original message [type].
  final String type;

  /// Whether the operation succeeded.
  final bool success;

  /// Response data on success.
  final Map<String, dynamic>? data;

  /// Error message on failure.
  final String? error;

  /// Timestamp of the response in milliseconds since epoch.
  final int timestamp;

  /// Creates a [BridgeResponse].
  const BridgeResponse({
    required this.id,
    required this.type,
    required this.success,
    this.data,
    this.error,
    required this.timestamp,
  });

  /// Creates a successful response.
  factory BridgeResponse.success(
    String id,
    String type, {
    Map<String, dynamic>? data,
  }) {
    return BridgeResponse(
      id: id,
      type: type,
      success: true,
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Creates a failure response.
  factory BridgeResponse.failure(String id, String type, String error) {
    return BridgeResponse(
      id: id,
      type: type,
      success: false,
      error: error,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Converts this response to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'success': success,
    'data': data,
    'error': error,
    'timestamp': timestamp,
  };
}
