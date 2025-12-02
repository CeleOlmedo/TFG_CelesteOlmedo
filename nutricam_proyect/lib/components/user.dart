class User {
  int? id;
  String name;
  String surname;
  String birthDate;
  String email;

  User({
    this.id,
    required this.name,
    required this.surname,
    required this.birthDate,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      name: json["name"] ?? "",
      surname: json["surname"] ?? "",
      birthDate: json["birthDate"] ?? "",
      email: json["email"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "surname": surname,
      "birthDate": birthDate,
      "email": email,
    };
  }
}
