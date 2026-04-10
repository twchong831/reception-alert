class Team {
  final String id;
  final String name;
  final String registrationCode;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.registrationCode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'registrationCode': registrationCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        registrationCode: json['registrationCode'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
