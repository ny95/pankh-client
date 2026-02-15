class Account {
  final String email;
  final String password;

  const Account({required this.email, required this.password});

  Map<String, dynamic> toMap() {
    return {'email': email, 'password': password};
  }

  static Account? fromMap(dynamic value) {
    if (value is! Map) return null;
    final email = value['email'];
    final password = value['password'];
    if (email is! String || password is! String) return null;
    return Account(email: email, password: password);
  }
}
