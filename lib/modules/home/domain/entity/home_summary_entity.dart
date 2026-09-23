class HomeSummaryEntity {
  const HomeSummaryEntity({
    required this.isConnected,
    required this.connectionLabel,
    required this.message,
  });

  final bool isConnected;

  final String connectionLabel;

  final String message;

  @override
  String toString() =>
      'HomeSummaryEntity(isConnected: $isConnected, '
      'connectionLabel: $connectionLabel, message: $message)';
}
