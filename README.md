# spixs_tecnologia

Resolução do desafio técnico da Spixs_Tecnologia: simulação de um app de
entrega/roteirização com bloqueio de segurança, mapa, autocomplete de
endereços e navegação com recálculo dinâmico de rota.

## Funcionalidades

- **Bloqueio nativo** — autenticação via FaceID/digital com fallback para senha/PIN, incluindo dispositivos sem biometria e falha de autenticação.
- **Mapa inicial** — solicita permissão de localização, centraliza o mapa na posição atual e marca o ponto de partida.
- **Endereços com autocomplete** — 3 campos de texto com sugestões via Google Places API e validação antes de prosseguir.
- **Cálculo de rota otimizada** — Routes/Directions API com waypoints otimizados; a rota passa pelos pontos na ordem mais eficiente (não necessariamente a digitada).
- **Navegação com GPS** — botão "Iniciar" e rastreio contínuo da posição via stream de localização.
- **Recálculo dinâmico** — detecta desvio da rota (threshold de distância), recalcula com os pontos não visitados, reotimiza a ordem e indica visualmente o recálculo.

## Arquitetura

Segue a [arquitetura](https://docs.flutter.dev/app-architecture) sugerida pela Google, com separação em camadas (`presenter` / `domain` / `data`) e gerenciamento de estado nativo.

## Decisões técnicas

- **Rotas otimizadas**: `optimizeWaypointOrder` reordena os pontos — a ordem digitada não é mantida por padrão.
- **Usecases puros** para desvio, conclusão, ordenação e *trim* do caminho, facilitando testes unitários.
- **Padrões `Command`/`Result` + repositórios com interfaces + GetIt** para injeção de dependência e tratamento de erros.
- **Conexão** monitorada via `ConnectivityPlus`, exibindo banner quando offline sem bloquear o fluxo.
- **Chaves de API** injetadas em build via `--dart-define` (placeholder no AndroidManifest) — nunca no código nem versionadas.
- **Testes com fakes**: os serviços são testados sem chamadas reais às APIs do Google.

## Packages

- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter/install) — widget de mapa;
- [Geolocator](https://pub.dev/packages/geolocator) — permissão de localização e status do GPS;
- [Local Auth](https://pub.dev/packages/local_auth) — autenticação local com o dispositivo;
- [Get It](https://pub.dev/packages/get_it) — injeção de dependência;
- [Connectivity Plus](https://pub.dev/packages/connectivity_plus) — acompanhar status da conexão;
- [Flutter Polyline Points](https://pub.dev/packages/flutter_polyline_points) — desenhar linhas e formas no Google Maps;
- [Dio](https://pub.dev/packages/dio) — HTTP.

## Chaves de API (Google Places / Maps)

As chaves são injetadas **em tempo de build** via `--dart-define` — nunca ficam
no código nem são commitadas. O autocomplete usa a **Google Places Autocomplete
API**; o módulo de mapa/rotas usa a Directions API.

### Local

Copie o modelo e preencha:

```bash
cp env.example.json env.json
# edite env.json com suas chaves
flutter run --dart-define-from-file=env.json
```

Ou passe direto, sem arquivo:

```bash
flutter run --dart-define=GOOGLE_PLACES_API_KEY=AIza...
```

> `env.json` está no `.gitignore`; apenas `env.example.json` é versionado.

## Como executar

```bash
flutter pub get
flutter run --dart-define-from-file=env.json   # ou as flags --dart-define
```

## Testes e relatório de cobertura

```bash
flutter test                 # testes unitários e de widget
flutter test --coverage      # gera coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html   # relatório HTML
```

Relatório publicado: https://caiobribeiro.github.io/spixs-tecnologia/

## GitHub Actions (CI)

O workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) roda
`analyze` + `test` + `build apk` e consome as chaves de **secrets** do
repositório no passo do build:

1. Em *Settings → Secrets and variables → Actions*, crie:
   - `GOOGLE_PLACES_API_KEY`
   - `GOOGLE_MAPS_API_KEY`
2. No pipeline, as secrets são passadas via:

```bash
flutter build apk --release \
  --dart-define=GOOGLE_PLACES_API_KEY="${{ secrets.GOOGLE_PLACES_API_KEY }}" \
  --dart-define=GOOGLE_MAPS_API_KEY="${{ secrets.GOOGLE_MAPS_API_KEY }}"
```

Se a secret não estiver configurada o build ainda compila (chave vazia); o
autocomplete simplesmente retorna erro da API, tratado pelo `Result`. O APK
gerado fica disponível como artifact do workflow (`app-release.apk`).