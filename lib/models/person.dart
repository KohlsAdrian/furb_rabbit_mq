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
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (type != null) 'type': type,
        'topics': topics,
      };
}
