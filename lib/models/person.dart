class PersonModel {
  String? id;
  String? name;
  String? email;
  String? type;
  List<String> topics;

  PersonModel({
    this.id,
    this.name,
    this.email,
    this.type,
    this.topics = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'type': type,
        'topics': topics,
      };
}
