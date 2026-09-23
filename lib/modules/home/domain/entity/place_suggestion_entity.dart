class PlaceSuggestionEntity {
  const PlaceSuggestionEntity({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;

  final String description;

  final String mainText;

  final String secondaryText;

  @override
  String toString() => 'PlaceSuggestionEntity($description)';
}
