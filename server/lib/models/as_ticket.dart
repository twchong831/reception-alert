class AsTicket {
  final String id;
  final String customerName;
  final String contactNumber;
  final String productName;
  final String symptom;
  String status; // received, in_progress, done
  final bool privacyAgreed;
  final DateTime? privacyAgreedAt;
  final DateTime createdAt;
  final DateTime? completedAt;

  AsTicket({
    required this.id,
    required this.customerName,
    required this.contactNumber,
    required this.productName,
    required this.symptom,
    this.status = 'received',
    this.privacyAgreed = false,
    this.privacyAgreedAt,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'contactNumber': contactNumber,
        'productName': productName,
        'symptom': symptom,
        'status': status,
        'privacyAgreed': privacyAgreed,
        'privacyAgreedAt': privacyAgreedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory AsTicket.fromJson(Map<String, dynamic> json) => AsTicket(
        id: json['id'] as String,
        customerName: json['customerName'] as String? ?? json['companyName'] as String? ?? '',
        contactNumber: json['contactNumber'] as String,
        productName: json['productName'] as String,
        symptom: json['symptom'] as String,
        status: json['status'] as String? ?? 'received',
        privacyAgreed: json['privacyAgreed'] as bool? ?? false,
        privacyAgreedAt: json['privacyAgreedAt'] != null
            ? DateTime.parse(json['privacyAgreedAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}
