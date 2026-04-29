class CeoRequest {
  final String id;
  final String type; // coffee, call
  final String? message;
  String status; // pending, confirmed, done
  final DateTime createdAt;
  final DateTime? confirmedAt;

  CeoRequest({
    required this.id,
    required this.type,
    this.message,
    this.status = 'pending',
    DateTime? createdAt,
    this.confirmedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
      };

  factory CeoRequest.fromJson(Map<String, dynamic> json) => CeoRequest(
        id: json['id'] as String,
        type: json['type'] as String,
        message: json['message'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['createdAt'] as String),
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.parse(json['confirmedAt'] as String)
            : null,
      );
}
