class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'student' or 'admin'
  final String? adminType; // 'zoya' or 'muskan'
  final String? department; // 'Commerce' or 'Maths and Science'
  final String? batch; // e.g. 'Class 10', 'Class 11 and 12 Commerce'
  final String? rollNo;
  final bool isPhoneVerified;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.adminType,
    this.department,
    this.batch,
    this.rollNo,
    this.isPhoneVerified = true,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'student',
      adminType: json['adminType'],
      department: json['department'],
      batch: json['batch'],
      rollNo: json['rollNo'] ?? 'ZM-101',
      isPhoneVerified: json['is_phone_verified'] == true || json['isVerified'] == true,
      token: token ?? json['token'] ?? json['access_token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'adminType': adminType,
    'department': department,
    'batch': batch,
    'token': token,
  };
}
