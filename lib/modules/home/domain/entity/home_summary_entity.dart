/// Domain entity that summarizes the home screen state.
///
/// Pure representation of the business data shown on the home dashboard.
/// It has no framework dependency and is immutable.
class HomeSummaryEntity {
  const HomeSummaryEntity({
    required this.isConnected,
    required this.connectionLabel,
    required this.message,
  });

  /// Whether the device currently has an active network connection.
  final bool isConnected;

  /// Human-readable label describing the active connection type.
  final String connectionLabel;

  /// Short message displayed to the user about the connection state.
  final String message;

  @override
  String toString() =>
      'HomeSummaryEntity(isConnected: $isConnected, '
      'connectionLabel: $connectionLabel, message: $message)';
}