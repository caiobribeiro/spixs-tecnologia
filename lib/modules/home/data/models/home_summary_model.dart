import '../../domain/entity/home_summary_entity.dart';

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
