import '../../domain/entity/home_summary_entity.dart';

/// Data Transfer Object for the home summary payload.
///
/// Responsible for serialization/deserialization and for the conversion
/// into the domain [HomeSummaryEntity].
class HomeSummaryModel {
  const HomeSummaryModel({
    required this.isConnected,
    required this.connectionLabel,
    required this.message,
  });

  factory HomeSummaryModel.fromMap(Map<String, dynamic> map) {
    return HomeSummaryModel(
      isConnected: map['isConnected'] as bool,
      connectionLabel: map['connectionLabel'] as String,
      message: map['message'] as String,
    );
  }

  final bool isConnected;
  final String connectionLabel;
  final String message;

  Map<String, dynamic> toMap() {
    return {
      'isConnected': isConnected,
      'connectionLabel': connectionLabel,
      'message': message,
    };
  }

  /// Converts this DTO into the domain entity used by the presentation layer.
  HomeSummaryEntity toEntity() {
    return HomeSummaryEntity(
      isConnected: isConnected,
      connectionLabel: connectionLabel,
      message: message,
    );
  }

  @override
  String toString() => 'HomeSummaryModel($toMap)';
}