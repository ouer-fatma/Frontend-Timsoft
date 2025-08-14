class RemiseType {
  final String id;
  final String libelle;

  RemiseType({required this.id, required this.libelle});

  factory RemiseType.fromJson(Map<String, dynamic> json) {
    return RemiseType(
      id: json['id'],
      libelle: json['libelle'],
    );
  }
}
