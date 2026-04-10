class Team {
  final String id;
  final String name;
  final String registrationCode;

  Team({
    required this.id,
    required this.name,
    required this.registrationCode,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        registrationCode: json['registrationCode'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'registrationCode': registrationCode,
      };
}
