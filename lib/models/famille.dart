class Famille {
  final String code;
  final String label;

  Famille({required this.code, required this.label});

  factory Famille.fromJson(Map<String, dynamic> json) {
    return Famille(
      code: json['code'],
      label: json['label'],
    );
  }
}
