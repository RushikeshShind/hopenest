class Orphanage {
  final int id;
  final String name;
  final String location;
  final double rating;
  final String description;
  final String imageUrl;
  final String contact;
  final List<String> needs;

  Orphanage({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.description,
    required this.imageUrl,
    required this.contact,
    required this.needs,
  });
}