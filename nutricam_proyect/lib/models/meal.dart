class Meal {
  final int? id;
  final int userId;
  final String mealName;
  final String mealType;
  final String quantity;
  final String? mealDate;

  Meal({
    this.id,
    required this.userId,
    required this.mealName,
    required this.mealType,
    required this.quantity,
    this.mealDate,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      userId: json['userId'],
      mealName: json['mealName'],
      mealType: json['mealType'],
      quantity: json['quantity'],
      mealDate: json['mealDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mealName': mealName,
      'mealType': mealType,
      'quantity': quantity,
    };
  }
}