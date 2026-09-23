/// State of the location access flow on the map screen.
///
/// Framework-agnostic: the presentation layer maps this to the UI shown
/// over the map (loading, marker/camera, warning cards with actions).
enum LocationAccessStatus {
  /// GPS/permission checks in progress.
  checking,

  /// Permission granted and current position obtained; the map is centered
  /// on the user's location, marked as the route start point.
  ready,

  /// The user denied (or can no longer be prompted for) the location
  /// permission.
  denied,

  /// The device GPS / location service is disabled.
  serviceDisabled,

  /// Permission granted but the current position could not be obtained
  /// (e.g. no GPS fix or timeout).
  failed,
}