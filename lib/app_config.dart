/// App-wide compile-time configuration.
///
/// As chaves de API nunca ficam no código-fonte: são injetadas no build
/// (local e CI) via `--dart-define`. Exemplos:
///
/// ```bash
/// # Direto
/// flutter run --dart-define=GOOGLE_PLACES_API_KEY=AIza...
///
/// # Ou a partir de um arquivo (copie env.example.json para env.json)
/// flutter run --dart-define-from-file=env.json
/// ```
///
/// No GitHub Actions, as mesmas variáveis vêm de secrets e são passadas na
/// linha de comando (ver `.github/workflows/ci.yml`).
abstract final class AppConfig {
  /// Google Places API key — autocomplete de endereços do formulário.
  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
  );

  /// Google Maps API key — módulo de mapa/rotas (Directions API).
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
}
