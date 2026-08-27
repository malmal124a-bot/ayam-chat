enum AgencyRequestStatus { pending, approved, rejected }

class AgencyRequest {
  final String userId;
  final String agencyName;
  final String personalName;
  final String email;
  final String nationalId;
  final String phoneNumber;
  final String whatsappLink;
  final String contactInfo;
  final String description;
  final String? idCardFrontUrl;
  final String? idCardBackUrl;
  final int? selectedTier;
  AgencyRequestStatus status;

  AgencyRequest({
    required this.userId,
    required this.agencyName,
    required this.personalName,
    this.email = '',
    required this.nationalId,
    required this.phoneNumber,
    required this.whatsappLink,
    required this.contactInfo,
    required this.description,
    this.idCardFrontUrl,
    this.idCardBackUrl,
    this.selectedTier,
    this.status = AgencyRequestStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'agencyName': agencyName,
      'personalName': personalName,
      'email': email,
      'nationalId': nationalId,
      'phoneNumber': phoneNumber,
      'whatsappLink': whatsappLink,
      'contactInfo': contactInfo,
      'description': description,
      'idCardFrontUrl': idCardFrontUrl,
      'idCardBackUrl': idCardBackUrl,
      'selectedTier': selectedTier,
      'status': status.name,
    };
  }

  factory AgencyRequest.fromJson(Map<String, dynamic> json) {
    return AgencyRequest(
      userId: json['userId'] ?? '',
      agencyName: json['agencyName'] ?? '',
      personalName: json['personalName'] ?? '',
      email: json['email'] ?? '',
      nationalId: json['nationalId'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      whatsappLink: json['whatsappLink'] ?? '',
      contactInfo: json['contactInfo'] ?? '',
      description: json['description'] ?? '',
      idCardFrontUrl: json['idCardFrontUrl'],
      idCardBackUrl: json['idCardBackUrl'],
      selectedTier: json['selectedTier'],
      status: AgencyRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AgencyRequestStatus.pending,
      ),
    );
  }
}
