class CeoRequest {
  final String id;
  final String type; // coffee, call
  final String? message;
  final String status; // pending, confirmed, done
  final DateTime createdAt;
  final DateTime? confirmedAt;

  CeoRequest({
    required this.id,
    required this.type,
    this.message,
    this.status = 'pending',
    required this.createdAt,
    this.confirmedAt,
  });

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
      };

  String get typeLabel => type == 'coffee' ? '커피 요청' : '호출';
}
