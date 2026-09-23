/// A single address suggestion returned by the Google Places Autocomplete
/// API, already mapped to the domain.
class PlaceSuggestionEntity {
  const PlaceSuggestionEntity({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  /// Google's unique identifier for the place (used later by Place Details
  /// to resolve the exact coordinates when confirming the route).
  final String placeId;

  /// Full address as displayed by Google, e.g. `Av. Paulista, 1000 -
  /// Bela Vista, São Paulo - SP, Brasil`.
  final String description;

  /// Highlighted main part of the address (street + number).
  final String mainText;

  /// Complement: neighborhood, city, state/country.
  final String secondaryText;

  @override
  String toString() => 'PlaceSuggestionEntity($description)';
}