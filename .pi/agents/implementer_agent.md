---
description: 'Describe what this custom agent does and when to use it.'
tools: ['vscode', 'execute', 'read', 'edit', 'search', 'web', 'agent', 'todo']
---
# App Architecture

## 📑 Table of Contents
- [Overview](#-overview)
- [Layered Structure](#-layered-structure)
- [Directory Structure](#-directory-structure)
- [Modules](#-modules)
- [Pub Workspace (Monorepo)](#-pub-workspace-monorepo)
- [Names and Organization](#-names-and-organization)
- [Architecture Layers](#-architecture-layers)
- [View and Widget Separation](#-view-and-widget-separation)
- [Implemented Design Patterns](#-implemented-design-patterns)
- [Use Cases](#-use-cases)
- [Single Source of Truth](#-single-source-of-truth)
- [Typed Result Switch Rule](#-typed-result-switch-rule)
- [RPC-First Backend Rule](#-rpc-first-backend-rule)
- [Data Flow](#-data-flow)
- [EventChannel: Real-Time Monitoring](#-eventchannel-real-time-monitoring)
- [UI and Responsiveness](#-ui-and-responsiveness)
- [Widget Previewer](#-widget-previewer)

## 📋 Overview


**Launcher Hermeneutics** is an Android application developed in Flutter that implements a custom launcher. The architecture follows **Clean Architecture** principles, ensuring clear separation of responsibilities, testability, and maintainability of the code.

## 🏗️ Layered Structure

```
┌─────────────────────────────────────────────────┐
│              PRESENTATION LAYER                 │
│  (Views, ViewModels, Widgets, Commands)         │
└─────────────────┬───────────────────────────────┘
                  │ Commands + Result<T>
┌─────────────────▼───────────────────────────────┐
│               DOMAIN LAYER                      │
│  (Entities, Repository Interfaces, Use Cases)   │
└─────────────────┬───────────────────────────────┘
                  │ Result<T>
┌─────────────────▼───────────────────────────────┐
│                DATA LAYER                       │
│  (Models, Services, Platform Channels)          │
└─────────────────┬───────────────────────────────┘
                  │ MethodChannel/EventChannel
┌─────────────────▼───────────────────────────────┐
│            PLATFORM LAYER (Android)             │
│  (MainActivity.kt, LauncherApps API)            │
└─────────────────────────────────────────────────┘
```

## 📁 Directory Structure

The directory structure follows a **feature-first modular** model. Each feature lives in its own module with the three layers (data, domain, presenter) isolated internally. Code shared between modules lives in `modules/core/`.

### General rule

```
lib/
├── modules/
│   ├── core/                      # Code shared between modules
│   │   └── <feature>/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presenter/
│   └── <module>/                  # Isolated feature
│       ├── data/
│       ├── domain/
│       └── presenter/
├── app_dependency_injection.dart
├── app_routes.dart
└── main.dart
```


### App (`packages/student_app/lib/`)

```
lib/
├── modules/
│   ├── core/
│   │   └── theme/
│   │       └── domain/
│   │           └── repository/    # theme_repository.dart / _impl.dart
│   ├── home/
│   │   └── presenter/
│   │       ├── home_view.dart
│   │       └── home_viewmodel.dart
│   └── map_view/
│       └── presenter/
│           ├── map_view.dart
│           └── map_viewmodel.dart
├── app_dependency_injection.dart
├── app_routes.dart
└── spixs_tecnologia_app.dart
```

## 🧩 Modules

Each module is a vertical, self-contained feature. It has its own data, domain, and presenter layers — and does not import directly from other modules.

### What is a module

A module represents a **complete business feature**. Examples: `login`, `workouts`, `students`. Each module:

- Has its own layers (data / domain / presenter) when needed.
- If a layer does not exist (e.g. `login` does not access the database directly), the folder is simply not created.
- Does not import code from other modules. Cross-module dependencies go through `core/`.

### What goes in `core/`

`modules/core/` groups features that are **shared by two or more modules** within the same app. Examples: authentication, theme, shared Supabase services.

```
# Practical rule
# Belongs to a module      → lib/modules/<module>/
# Used by >= 2 modules     → lib/modules/core/<feature>/
```

### When to create each layer inside a module

| Layer | Create when |
|---|---|
| `data/` | The module accesses an external data source (Supabase, API, cache) |
| `domain/` | There are entities, repository interfaces, or pure business rules |
| `presenter/` | There is at least one screen or widget associated with the module |

### Shared utilities (not modules)

Code patterns and reusable helpers **are not modules** and live in `shared/`:

```
lib/
└── shared/
    ├── design_pattern/     # command_pattern.dart, result_pattern.dart
    ├── interface_helpers/  # responsive_layout.dart
    ├── mixins/             # validation_mixin.dart
    ├── services/           # supabase_client_service.dart, theme_service.dart
    └── enum/               # type_app_mode.dart
```


### Daily usage

- Resolve all packages:

```bash
flutter flutter pub get
```


## ✍️ Names and Organization

Use clear, descriptive names for variables, functions, classes, entities, models, routes, and all other code elements. Every part of the code must be simple for humans to read and understand.

Code organization rule:

- In classes, declare fields before constructors.
- Keep constructors immediately after field declarations.
- Prefer this structure order: fields, constructor, named constructors/factories, getters/setters, public methods, private methods.

## 🎯 Architecture Layers

Create a use case in exactly two situations: **(1)** a ViewModel method that uses **more than two repositories** (orchestration that does not belong in the presentation layer), and **(2)** a reusable domain rule/helper worth a named contract (e.g. `MapMarkerHelper`, `RouteStopsSorter`, `RoutePathTrimmer`, `GeographicDistance`). Theme code is **never** a use case. See [Use Cases](#-use-cases) for the full rule.

### 1. **Presentation Layer**

#### Responsibilities:
- Manage the user interface
- React to user events
- Display formatted data
- Manage UI state

#### Components:

**Views** (`lib/presenter/views/`)
- `MapView`: Main launcher screen with swipe gesture support
- Implements responsive layouts for mobile/tablet/desktop
- Uses `SwipeDetector` for gesture detection

**ViewModels** (`lib/presenter/views/*/viewmodel.dart`)
- `MapViewmodel`: Manages the state and logic of `MapView`
- Exposes `Command` objects for action execution
- Maintains a repository reference via Dependency Injection

**ViewModel Example:**
```dart
class MapViewmodel extends ChangeNotifier {
  final _repository = getIt<DesktopRepository>();

  late final getUserAppsCommand = Command0(_repository.getUserApps);
  late final launchAppCommand = Command1<bool, String>(_repository.launchApp);
  
  ValueNotifier<List<AppInfoEntity>> get apps => _repository.apps;
}
```

## 🧩 View and Widget Separation

Keep screen composition and reusable UI components in separate files. A `View` is
the feature entry point: it coordinates layout, navigation, ViewModel listeners,
Commands, and feature-level callbacks. A widget is a focused UI component that
renders a bounded part of the screen and receives its data and callbacks through
constructor parameters.

### Rules

- Do not define private reusable widgets inside a `*_view.dart` file. A widget
  that has its own class, meaningful layout, or can be named independently must
  live in a separate `*_widget.dart` file.
- A widget used only by one feature belongs in that feature's `presenter`
  directory, preferably in `presenter/widgets/`:

  ```text
  packages/trainer_app/lib/modules/home/presenter/
  ├── home_view.dart
  ├── home_viewmodel.dart
  └── widgets/
      └── dashboard_chart_card.dart
  ```

- A widget used by two or more modules in the same app belongs in that app's
  `shared/widgets/` directory. A widget used by the root app and packages, or
  that is part of the product-wide visual language, belongs in
  `packages/gym_design_system/lib/src/widgets/`.
- Promote a widget to `shared` or `gym_design_system` only after there is a real
  second consumer. Do not create a generic shared widget speculatively.
- Use public, descriptive widget names for components that live in their own
  files. Avoid names such as `_Card`, `_Section`, or `_Widget` that hide the
  component's ownership and make reuse difficult.
- Keep feature business decisions and data loading in the ViewModel/repository.
  Widgets may own local visual state such as hover, animation, controller, or
  expansion state when that state is not shared domain data.
- Widgets must not resolve `getIt`, access a `RepositoryImpl`, call a service, or
  mutate repository state. Pass immutable values, `ValueListenable`s, and
  callbacks from the View/ViewModel instead.
- `*_view.dart` files should primarily compose the screen from widgets. If a
  section grows beyond simple composition, extract it without changing the
  public behavior or moving domain state into the widget.

### Correct Example

For `packages/trainer_app/lib/modules/home/presenter/home_view.dart`,
`_DashboardChartCard` is a feature widget and should be extracted to:

`packages/trainer_app/lib/modules/home/presenter/widgets/dashboard_chart_card.dart`

```dart
// presenter/widgets/dashboard_chart_card.dart
import 'package:flutter/material.dart';

class DashboardChartCard extends StatelessWidget {
  const DashboardChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(subtitle, style: textTheme.bodySmall),
            const SizedBox(height: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
```

The `HomeView` imports `DashboardChartCard` and only supplies the chart data and
child widget. The component does not know about `HomeViewModel`, repositories,
services, routes, or backend entities.

### Incorrect Example

```dart
// home_view.dart
class _DashboardChartCard extends StatelessWidget {
  const _DashboardChartCard(this.viewmodel);

  final HomeViewModel viewmodel;

  @override
  Widget build(BuildContext context) {
    final repository = getIt<HomeDashboardRepository>();
    return Card(
      child: Text('${repository.metrics.length}'),
    );
  }
}
```

Do not keep this private component at the bottom of `home_view.dart`, inject a
ViewModel or repository into a reusable widget, or make the widget fetch its own
data. Those choices blur the View/widget boundary, hide ownership, and make the
component impossible to reuse or test independently.

#### Navigation

Each module must define and expose its own routes.
The App Routes must import and register the routes from every module.


```dart
import 'package:flutter/material.dart';

enum AppRoute { home, map }

extension AppRouteExtension on AppRoute {
  String get path {
    switch (this) {
      case AppRoute.home:
        return '/';
      case AppRoute.map:
        return '/map';
    }
  }
}

Route<AppRoute> onGenerateAppRoute(AppRoute settings) {
  switch (settings) {
    case AppRoute.home:
      return MaterialPageRoute(builder: (context) => HomeView());
    case AppRoute.map:
      return MaterialPageRoute(builder: (context) => MapView());
  }
}

```

---


### 2. **Domain Layer**

#### Responsibilities:
- Define business entities
- Declare repository contracts (interfaces)
- Contain pure business rules (framework-independent)
- Encapsulate reusable operations as use cases (see [Use Cases](#-use-cases))

#### Components:

**Entities** (`lib/domain/entity/`)
```dart
class AppInfoEntity {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final bool enabled;
  final String? iconBase64;
}
```
- Pure representations of business objects
- No external dependencies (Flutter, Android, etc.)
- Immutable and focused on domain logic

**Repository Interfaces** (`lib/domain/repository/`)
```dart
abstract class DesktopRepository {
  Future<Result<List<AppInfoEntity>>> getUserApps();
  Future<Result<bool>> launchApp(String packageName);
  ValueNotifier<List<AppInfoEntity>> get apps;
  // ... other methods
}
```
- Defines the contract for data operations
- Returns `Result<T>` for explicit error handling
- Works only with `Entities`, not with `Models`

**Repository Implementation** (`lib/domain/repository/*_impl.dart`)
- Implements the repository interface
- Converts `Models` (Data Layer) to `Entities` (Domain Layer)
- Delegates calls to the `Service` (Data Layer)
- Handles results using pattern matching with `switch`

---


### 3. **Data Layer**

#### Responsibilities:
- Communication with external data sources (Platform Channels)
- Data serialization/deserialization
- Data format conversion

#### Components:

**Models** (`lib/data/models/`)
```dart
class AppInfoModel {
  final String packageName;
  final String appName;
  // ...
  
  factory AppInfoModel.fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap();
  AppInfoEntity toEntity();  // Conversion to Domain
}
```
- DTOs (Data Transfer Objects)
- Responsible for serialization/deserialization
- Have a `toEntity()` method for conversion

**Services** (`lib/data/service/`)
```dart
class AppService {
  static const MethodChannel _channel = MethodChannel('...');
  static const EventChannel _eventChannel = EventChannel('...');
  
  Future<Result<List<AppInfoModel>>> getUserApps() async {
    try {
      final result = await _channel.invokeMethod('getUserApps');
      return Result.ok(apps);
    } on PlatformException catch (e) {
      return Result.error(Exception(e.message));
    }
  }
}
```
- Communication with the native side (Android) via `MethodChannel` and `EventChannel`
- Returns `Result<T>` to encapsulate success/error
- Handles `PlatformException` and generic exceptions

---



---

## 🔧 Implemented Design Patterns

## 📦 Use Cases

A **use case** is a single, well-named domain operation that the presentation layer can call without knowing which repositories or rules it orchestrates. It lives in the **domain layer**, depends only on repository **contracts** (never on `RepositoryImpl` or `getIt`), and returns `Result<T>` so errors propagate explicitly — the same pattern used everywhere else in the app.

### When to create a use case

Create a use case in exactly **two** situations:

1. **A ViewModel method uses more than two repositories.**

   When a feature function ends up orchestrating more than two repositories (e.g. "compute what the user sees" combining auth, location and map data), extract that orchestration into a use case instead of letting the ViewModel wire repositories together. The ViewModel keeps a single `execute()` entry point and stays readable.

2. **A reusable domain rule or pure helper deserves a named contract.**

   Domain utilities that encapsulate business logic used by a feature — such as `MapMarkerHelper`, `RouteStopsSorter`, `RoutePathTrimmer` and `GeographicDistance` — are modeled as use cases so they have a clear contract, live in the domain layer and are unit-testable in isolation.

### When NOT to create a use case

- **Never create use cases for the theme.** Design-system tokens, theme building, `AppBreakpoints` and theme repositories stay out of the use-case world: they are configuration/design code, not domain operations.
- Do not create a use case for a single repository call that the ViewModel can invoke directly through the repository contract.
- Do not create speculative use cases without a real consumer. Promote a helper to a use case only when it is actually used by a feature (same rule as promoting widgets).

### Structure

- Live in `lib/modules/<module>/domain/usecases/<use_case_name>.dart`.
- Expose a single public method `execute(...)`.
- Depend on repository interfaces (contracts); never on `RepositoryImpl` or `getIt`.
- Return `Result<T>` and follow the [Typed Result Switch Rule](#-typed-result-switch-rule) when orchestrating repositories.

### Example

```dart
// lib/modules/map/domain/usecases/get_user_route_use_case.dart
class GetUserRouteUseCase {
  GetUserRouteUseCase(this._mapRepository, this._locationRepository);

  final MapRepository _mapRepository;
  final LocationRepository _locationRepository;

  Future<Result<RouteEntity>> execute(RouteRequestEntity request) async {
    final origin = _locationRepository.startPoint.value;
    if (origin == null) {
      return const Result.error(LocationUnavailableFailure());
    }
    return _mapRepository.computeRoute(
      RouteRequestEntity(addresses: request.addresses, origin: origin),
    );
  }
}
```

### ViewModel usage

```dart
class MapViewmodel extends ChangeNotifier {
  MapViewmodel(this._getUserRoute);

  final GetUserRouteUseCase _getUserRoute;

  late final getRouteCommand = Command1<RouteEntity, RouteRequestEntity>(
    _getUserRoute.execute,
  );
}
```

---

## 📌 Single Source of Truth

Every data type must have a single source of truth (SSOT) responsible for representing its local or remote state. In this architecture, the SSOT for repository-managed data must live in the concrete `RepositoryImpl` class.

### Rule

- `RepositoryImpl` owns the canonical state for its data type, including cached entities, collections, and `ValueNotifier` instances exposed to the presentation layer.
- If the data can be modified in the app, only `RepositoryImpl` may mutate the SSOT. ViewModels, Views, Services, and other classes must not keep or independently modify copies of that state.
- The SSOT must be accessed by the `ViewModel` through the repository contract. Views must interact with state and mutations through the `ViewModel`, and must never access `RepositoryImpl` directly.
- The repository interface exposes the contract for reading state and requesting mutations; it must not contain a second state or mutation implementation.
- Services may fetch, persist, or synchronize data with external sources, but they are not the frontend SSOT. `RepositoryImpl` updates its canonical state after those operations succeed.
- Derive related values from the SSOT with getters or grouped records instead of maintaining parallel fields or lists that can become inconsistent.

### Correct Example

```dart
abstract class DesktopRepository {
  ValueNotifier<List<AppInfoEntity>> get apps;
  Future<Result<List<AppInfoEntity>>> refreshApps();
}

class DesktopRepositoryImpl implements DesktopRepository {
  final ValueNotifier<List<AppInfoEntity>> _apps =
      ValueNotifier<List<AppInfoEntity>>([]);

  @override
  ValueNotifier<List<AppInfoEntity>> get apps => _apps;

  Future<Result<List<AppInfoEntity>>> refreshApps() async {
    final result = await _service.getUserApps();
    switch (result) {
      case Ok<List<AppInfoModel>>():
        final value = result.value.map((model) => model.toEntity()).toList();
        _apps.value = value;
        return Result.ok(value);
      case Error<List<AppInfoModel>>():
        return Result.error(result.error);
    }
  }
}

class MapViewModel extends ChangeNotifier {
  MapViewModel(this._repository);

  final DesktopRepository _repository;

  ValueNotifier<List<AppInfoEntity>> get apps => _repository.apps;

  Future<void> refreshApps() async {
    await _repository.refreshApps();
  }
}
```

The view observes `MapViewModel.apps` and requests refreshes through `MapViewModel`. The `ViewModel` is the only presentation-layer entry point and accesses the SSOT through `DesktopRepository`; it never depends on `DesktopRepositoryImpl` directly.

### Incorrect Example

```dart
class MapView extends StatelessWidget {
  MapView(this._repository);

  final DesktopRepositoryImpl _repository;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AppInfoEntity>>(
      valueListenable: _repository.apps,
      builder: (context, apps, child) => Text('${apps.length} apps'),
    );
  }
}

class IncorrectMapViewModel extends ChangeNotifier {
  IncorrectMapViewModel(this._repository);

  final DesktopRepositoryImpl _repository;
  final ValueNotifier<List<AppInfoEntity>> _apps =
      ValueNotifier<List<AppInfoEntity>>([]);

  void replaceApps(List<AppInfoEntity> apps) {
    _apps.value = apps;
    _repository.apps.value = apps;
  }
}
```

Do not access `RepositoryImpl` directly from a view, service, or another feature. Do not expose mutable implementation details so another class can assign to the repository's `ValueNotifier`, and do not create a second `_apps` collection outside `RepositoryImpl`. These patterns create multiple sources of truth and can leave the UI, repository, and remote data out of sync.

Keeping one canonical copy in `RepositoryImpl` reduces synchronization bugs and ensures every consumer observes the same state.

## 📌 Typed Result Switch Rule

Use explicit generic pattern matching when handling `Result<T>` in repository implementations.

### Rule

- In repositories, prefer typed switch cases (`Ok<ConcreteModel>()` and `Error<ConcreteModel>()`) over untyped destructuring.
- Inside each case, assign to a local variable (`final value = ...`) before mapping, to keep transformation steps explicit.
- Keep this style for methods that convert `Model -> Entity`, especially when mapping logic can grow.

### Why

- Easier to read and debug in large methods.
- Clearer control over success/error branches.
- Safer refactors when changing model types.

### Example

```dart
@override
Future<Result<ProfileEntity>> updateProfile({String? fullName}) async {
  final result = await _service.updateProfile(
    userId: _userId,
    fullName: fullName,
  );

  switch (result) {
    case Ok<ProfileModel>():
      final value = result.value;
      return Result.ok(value.toEntity(email: _email));
    case Error<ProfileModel>():
      final value = result;
      return Result.error(value.error);
  }
}
```



### 1. **Result Pattern** (`lib/utils/patterns/result_pattern.dart`)
Google's implementation.

Encapsulates the result of operations that may fail, eliminating the need for try-catch in multiple layers.

```dart
sealed class Result<T> {
  const factory Result.ok(T value) = Ok._;
  const factory Result.error(Exception error) = Error._;
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error._(this.error);
  final Exception error;
}
```

**Advantages:**
- ✅ Type-safe: Compiler enforces error checking
- ✅ No unhandled exceptions
- ✅ Cleaner and more explicit code
- ✅ Pattern matching with `switch` expressions

**Usage:**
```dart
final result = await repository.getUserApps();
switch (result) {
  case Ok(value: final apps):
    // success
  case Error(:final error):
    // error
}
```

---

### 2. **Command Pattern** (`lib/utils/patterns/command_pattern.dart`)
Google's implementation.

Encapsulates asynchronous actions with automatic state management (loading, error, completed).

```dart
abstract class Command<T> extends ChangeNotifier {
  bool get running;       // Indicates whether it is executing
  bool get error;         // Indicates whether an error occurred
  bool get completed;     // Indicates whether it completed successfully
  Result<T>? get result;  // Execution result
}

class Command0<T> extends Command<T> {
  Command0(CommandAction0<T> action);
  Future<void> execute();
}

class Command1<T, A> extends Command<T> {
  Command1(CommandAction1<T, A> action);
  Future<void> execute(A argument);
}
```

**Advantages:**
- ✅ Execution state managed automatically
- ✅ Prevents multiple simultaneous executions
- ✅ Facilitates loading state display in the UI
- ✅ Notifies listeners automatically (`ChangeNotifier`)

**Usage in UI:**
```dart
// ViewModel
late final launchAppCommand = Command1<bool, String>(
  _repository.launchApp
);

// View
AnimatedBuilder(
  animation: viewmodel.launchAppCommand,
  builder: (context, child) {
    if (viewmodel.launchAppCommand.running) {
      return CircularProgressIndicator();
    }
    return ElevatedButton(
      onPressed: () => viewmodel.launchAppCommand.execute(packageName),
      child: Text('Open App'),
    );
  },
)
```

---

### 3. **Repository Pattern**

Abstracts the data source, allowing implementations to be swapped without affecting upper layers.

```dart
// Interface (Domain)
abstract class DesktopRepository {
  Future<Result<List<AppInfoEntity>>> getUserApps();
}

// Implementation (Domain)
class DesktopRepositoryImpl implements DesktopRepository {
  final _service = getIt<AppService>();
  
  @override
  Future<Result<List<AppInfoEntity>>> getUserApps() async {
    final result = await _service.getUserApps();
    switch (result) {
      case Ok(value: final models):
        return Result.ok(models.map((e) => e.toEntity()).toList());
      case Error(:final error):
        return Result.error(error);
    }
  }
}
```

---

### 4. **Dependency Injection** (GetIt)

Centralized dependency management, making testing and maintenance easier.

```dart
final getIt = GetIt.instance;

void setupDependencyInjection() {
  getIt.registerFactory<AppService>(() => AppService());
  getIt.registerFactory<DesktopRepository>(() => DesktopRepositoryImpl());
  getIt.registerFactory<MapViewmodel>(() => MapViewmodel());
}
```

**Benefits:**
- Decoupling between layers
- Facilitates unit testing (mocking)
- Object lifecycle management

---

### 5. **Validation Mixin** (`lib/shared/mixins/validation_mixin.dart`)

Reuses form validation logic across multiple widgets without inheritance, keeping the code lean and decoupled.

```dart
mixin ValidationMixin {
  // Validates that the field is not empty
  String? isNotEmpty(String? value, [String? message]) {
    if (value == null || value.isEmpty) {
      return message ?? "This field is required";
    }
    return null;
  }

  // Validates the minimum number of characters
  String? hasFiveChars(String? value, [String? message]) {
    if (value != null && value.length < 5) {
      return message ?? "You must enter at least five characters";
    }
    return null;
  }

  // Combines multiple validations, returning the first error found
  String? combine(List<String? Function()> validators) {
    for (final func in validators) {
      final validation = func();
      if (validation != null) {
        return validation;
      }
    }
    return null;
  }
}
```

**Applying the Mixin in a Widget:**

The mixin is added to the `State` class of a `StatefulWidget` via `with`, making all methods directly available:

```dart
class _LoginPageState extends State<LoginPage> with ValidationMixin {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: TextFormField(
        validator: (value) => combine([
          () => isNotEmpty(value),
          () => hasFiveChars(value),
        ]),
      ),
    );
  }
}
```

**Where to use:**
- `lib/presenter/login/`
- `lib/presenter/register/`
- `lib/presenter/recovery_account/`

**Advantages:**
- ✅ Reuse without inheritance: multiple mixins can be combined in the same widget
- ✅ Composed validations with `combine()`, returning the first error found
- ✅ Per-call customizable messages with a fallback to a default message
- ✅ Independent of any external form framework

---


### 6. **AppBreakpoints** (`packages/gym_design_system/lib/src/utils/app_breakpoints.dart`)

Centralizes all responsive layout breakpoints and derived values in the design system so that every app in the workspace shares a single source of truth. No app-level widget should hard-code screen-width thresholds.

```dart
abstract final class AppBreakpoints {
  static const double desktop = 1100;
  static const double tablet = 760;
  static const double mobileWide = 420;

  static int dashboardCrossAxisCount(double width) { ... }
  static double dashboardCardAspectRatio(double width) { ... }
}
```

**Rules:**
- All breakpoint constants and layout helpers must live in `AppBreakpoints`, never inline in feature code.
- When adding a new responsive widget, add a dedicated static helper method to `AppBreakpoints` (e.g. `railMinWidth(double width)`).
- `AppBreakpoints` is exported from `gym_design_system` and consumed by both `student_app` and `trainer_app`.

**Usage:**
```dart
final crossAxisCount = AppBreakpoints.dashboardCrossAxisCount(width);
final aspectRatio    = AppBreakpoints.dashboardCardAspectRatio(width);
```

**Advantages:**
- ✅ Single source of truth: changing a threshold fixes all apps at once
- ✅ No magic numbers scattered across feature widgets
- ✅ Easy to test with plain unit tests (pure functions, no Flutter dependency)

---

## 📊 Data Flow

### Read Flow (Fetch Apps)

```
┌──────────────┐
│  MapView │ (User taps button)
└──────┬───────┘
      │ 1. execute()
┌──────▼──────────────┐
│ getUserAppsCommand  │ (Command1)
└──────┬──────────────┘
      │ 2. calls repository
┌──────▼─────────────┐
│ DesktopRepository  │ (Interface)
└──────┬─────────────┘
      │ 3. delegates to service
┌──────▼────────────┐
│ DesktopService    │ (MethodChannel)
└──────┬────────────┘
      │ 4. invokeMethod()
┌──────▼──────────┐
│ MainActivity.kt │ (Android)
└──────┬──────────┘
      │ 5. getUserApps() native
      │    ├─ LauncherApps.getActivityList()
      │    └─ Returns List<Map>
┌──────▼────────────┐
│ DesktopService    │ (MethodChannel result)
└──────┬────────────┘
      │ 6. Result.ok(List<AppInfoModel>)
┌──────▼─────────────┐
│ DesktopRepository  │ (Converts to Entity)
└──────┬─────────────┘
      │ 7. Result.ok(List<AppInfoEntity>)
┌──────▼──────────────┐
│ getUserAppsCommand  │ (Updates state)
└──────┬──────────────┘
      │ 8. notifyListeners()
┌──────▼───────┐
│  MapView │ (Rebuilds UI)
└──────────────┘
```

---
