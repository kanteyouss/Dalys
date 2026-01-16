class UserModel {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String password; // Hashed
  final String? telephone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactEmail;
  final String? doctorEmail;
  final String? hospitalEmail;
  final String? photoUrl;

  UserModel({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    this.telephone,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactEmail,
    this.doctorEmail,
    this.hospitalEmail,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': password,
      'telephone': telephone,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_email': emergencyContactEmail,
      'doctor_email': doctorEmail,
      'hospital_email': hospitalEmail,
      'photo_url': photoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      email: map['email'],
      password: map['password'],
      telephone: map['telephone'],
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      emergencyContactEmail: map['emergency_contact_email'],
      doctorEmail: map['doctor_email'],
      hospitalEmail: map['hospital_email'],
      photoUrl: map['photo_url'],
    );
  }

  UserModel copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? password,
    String? telephone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactEmail,
    String? doctorEmail,
    String? hospitalEmail,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      password: password ?? this.password,
      telephone: telephone ?? this.telephone,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactEmail:
          emergencyContactEmail ?? this.emergencyContactEmail,
      doctorEmail: doctorEmail ?? this.doctorEmail,
      hospitalEmail: hospitalEmail ?? this.hospitalEmail,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
