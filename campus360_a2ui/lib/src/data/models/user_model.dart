class UserModel {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String avatar;
  final String phone;
  final String address;

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.avatar,
    required this.phone,
    required this.address,
  });

  String get name => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] ?? json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      avatar: json['avatar'] ??
          'https://thinksport.com.au/wp-content/uploads/2020/01/avatar-.jpg',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }
}
