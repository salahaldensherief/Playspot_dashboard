class AddStaffParams {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String loungeId;

  const AddStaffParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    required this.loungeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'p_full_name': name,
      'p_email': email,
      'p_phone': phone,
      'p_password': password,
      'p_role': role,
      'p_lounge_id': loungeId,
    };
  }
}
