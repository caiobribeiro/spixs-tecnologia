# spixs_tecnologia

Este é a resolução desafio técnico proposto por Spixs_Tecnologia.
Spixs_Tecnologia: Simulação de um app de entrega/roteirização com bloqueio de segurança, mapa,
autocomplete de endereços e navegação com recálculo dinâmico de rota.

## Arquitetura
A [arquitetura](https://docs.flutter.dev/app-architecture) usada é a sugerida pela Google, mais detalhes em [Implementer Agent](.pi/agents/implementer_agent.md)

## Packages

Os packages usados no projeto.
Gerenciamento de estado foi feito todo nativo.

- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter/install)
- [Local Auth](https://pub.dev/packages/local_auth)
- [Get It](https://pub.dev/packages/get_it)
- [Connectivity Plus](https://pub.dev/packages/connectivity_plus)
- [Flutter_ Polyline Points](https://pub.dev/packages/flutter_polyline_points)
- [Dio](https://pub.dev/packages/dio)

## Chaves de API (Google Places / Maps)

As chaves são injetadas **em tempo de build** via `--dart-define` — nunca ficam
no código nem são commitadas. O autocomplete de endereços usa a **Google
Places Autocomplete API**; o módulo de mapa/rotas usa a Directions API.

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

### GitHub Actions (CI)

O workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) já roda
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
autocomplete simplesmente retorna erro da API, tratado pelo `Result`.



