class AsTicket {
  final String id;
  final String customerName;
  final String contactNumber;
  final String productName;
  final String symptom;
  final String status;
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
    required this.status,
    this.privacyAgreed = false,
    this.privacyAgreedAt,
    required this.createdAt,
    this.completedAt,
  });

  factory AsTicket.fromJson(Map<String, dynamic> json) => AsTicket(
        id: json['id'] as String,
        customerName: json['customerName'] as String? ?? json['companyName'] as String? ?? '',
        contactNumber: json['contactNumber'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        symptom: json['symptom'] as String? ?? '',
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
