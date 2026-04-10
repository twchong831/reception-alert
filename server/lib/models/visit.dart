class Visit {
  final String id;
  final String teamId;
  final String visitorName;
  final String visitorCompany;
  final String purpose;
  String status; // pending, confirmed, done
  final DateTime createdAt;

  Visit({
    required this.id,
    required this.teamId,
    required this.visitorName,
    required this.visitorCompany,
    required this.purpose,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamId': teamId,
        'visitorName': visitorName,
        'visitorCompany': visitorCompany,
        'purpose': purpose,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
        id: json['id'] as String,
        teamId: json['teamId'] as String,
        visitorName: json['visitorName'] as String,
        visitorCompany: json['visitorCompany'] as String,
        purpose: json['purpose'] as String,
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
