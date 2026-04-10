class Visit {
  final String id;
  final String teamId;
  final String visitorName;
  final String visitorCompany;
  final String purpose;
  final String status;
  final String? teamName;
  final DateTime createdAt;

  Visit({
    required this.id,
    required this.teamId,
    required this.visitorName,
    required this.visitorCompany,
    required this.purpose,
    required this.status,
    this.teamName,
    required this.createdAt,
  });

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
        id: json['id'] as String,
        teamId: json['teamId'] as String,
        visitorName: json['visitorName'] as String? ?? '',
        visitorCompany: json['visitorCompany'] as String? ?? '',
        purpose: json['purpose'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        teamName: json['teamName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
