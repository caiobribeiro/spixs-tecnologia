import '../../domain/entity/place_suggestion_entity.dart';

class PlaceSuggestionModel {
  const PlaceSuggestionModel({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestionModel.fromMap(Map<String, dynamic> map) {
    final description = map['description'] as String;
    final structured = map['structured_formatting'] as Map<String, dynamic>?;
    return PlaceSuggestionModel(
      placeId: map['place_id'] as String,
      description: description,
      mainText: structured?['main_text'] as String? ?? description,
      secondaryText: structured?['secondary_text'] as String? ?? '',
    );
  }

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestionEntity toEntity() {
    return PlaceSuggestionEntity(
      placeId: placeId,
      description: description,
      mainText: mainText,
      secondaryText: secondaryText,
    );
  }

  @override
  String toString() => 'PlaceSuggestionModel($description)';
}
