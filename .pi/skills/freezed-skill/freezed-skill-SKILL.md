---
    name: freezed-model-generator
    description: "Generates immutable Models and Entities with Freezed, including toEntity/fromEntity/toModel/fromModel conversions. Respects the Clean Architecture from implementer_agent.md."
    ---

# Freezed Model & Entity Generator

Use this skill when it is necessary to create or migrate **Models** (Data Layer) and **Entities** (Domain Layer) to use `freezed` with automatic code generation, maintaining layer conversion conventions.

## Trigger

- Create new Models/Entities in Flutter projects
- Migrate manual classes (`copy()`, `toString`, `==`) to Freezed
- Generate serializable DTOs with `fromJson`/`toJson` integrated into `json_serializable`
- Maintain conversion contracts `toEntity`, `fromEntity`, `toModel`, `fromModel`

## Fundamental Rules (respect implementer_agent.md)

### 1. Layers and Responsibilities

| Layer | Contents | Freezed Convention |
|---|---|---|
| **Domain** (`domain/entity/`) | Pure entities, no external dependencies | `@freezed` — immutable, primary constructors |
| **Data** (`data/models/`) | DTOs with serialization/deserialization | `@freezed` + `@JsonSerializable()` + `fromJson`/`toJson` |

### 2. Mandatory Conversions

Each Model ↔ Entity pair must implement:

```dart
// In the MODEL (Data Layer)
/// Converts model to domain entity
MyEntity toEntity();

/// Creates a copy with updated fields (Freezed generates automatically with @freezed)
MyModel copy({...}); // inherited from Freezed
```

```dart
// In the ENTITY (Domain Layer) — optional, when reconstruction is needed
static MyModel fromModel(MyEntity entity);
```

**Rule:** The repository (`_impl.dart`) handles the mapping `models.map((e) => e.toEntity()).toList()`. The entity **does not need** `fromModel` if conversion is unidirectional (Model → Entity). Add `fromModel` only when there is a need to reconstruct the Model from the Entity.

### 3. File Structure

```
lib/modules/<module>/
├── domain/
│   ├── entity/
│   │   └── <name>_entity.dart      # @freezed, immutable
│   └── repository/
│       ├── <name>_repository.dart  # interface
│       └── _impl.dart              # converts Model → Entity via .toEntity()
├── data/
│   ├── models/
│   │   └── <name>_model.dart       # @freezed + json_serializable, toEntity()
│   └── service/                    # when there is a native channel or API
```

### 4. Naming Conventions

- Entity: `<Name>Entity` → file `<name>_entity.dart`
- Model: `<Name>Model` → file `<name>_model.dart`
- Repository interface: `<Name>Repository` → `<name>_repository.dart`
- Implementation: `<Name>RepositoryImpl` → `_impl.dart`

## Generating Entities with Freezed

### Immutable Entity (Domain Layer)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '<name>_entity.freezed.dart';

@freezed
abstract class <Name>Entity with _$<Name>Entity {
  const factory <Name>Entity({
    required String field1,
    required int field2,
    String? optionalField,
  }) = _<Name>Entity;
}
```

**Rules:**
- Use `@freezed` (not `@unfreezed`) — entities are immutable
- Primary constructor with `factory` and parentheses `= _<Name>Entity`
- Mixin `with _$<Name>Entity`
- **DO NOT** import Flutter, Supabase, or any external dependency
- Use `required` for mandatory fields; `?` for optional ones

### Entity with Private Constructor (for getters/methods)

```dart
@freezed
abstract class <Name>Entity with _$<Name>Entity {
  const <Name>Entity._(); // required if defining methods

  const factory <Name>Entity({required String name}) = _<Name>Entity;

  /// Custom getter
  bool get isNotEmpty => name.isNotEmpty;

  /// Domain method
  void validate() {
    if (name.isEmpty) throw ArgumentError('Empty name');
  }
}
```

## Generating Models with Freezed + json_serializable

### Serializable Model (Data Layer)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entity/<name>_entity.dart';

part '<name>_model.freezed.dart';
part '<name>_model.g.dart'; // json_serializable

@freezed
@JsonSerializable()
class <Name>Model with _$<Name>Model {
  const factory <Name>Model({
    int? id,
    required String name,
    @JsonKey(name: 'period_start') DateTime periodStart,
    bool isFavorite = false,
  }) = _<Name>Model;

  /// Creates a Model from a Map (database row / API response)
  factory <Name>Model.fromMap(Map<String, dynamic> map);

  /// Converts to Map (database storage / API send)
  Map<String, dynamic> toMap();

  /// Conversion to Domain Entity
  <Name>Entity toEntity() {
    return <Name>Entity(
      id: id,
      name: name,
      periodStart: periodStart,
      isFavorite: isFavorite,
    );
  }

  /// Creates a Model from an Entity (when needed)
  static <Name>Model fromEntity(<Name>Entity entity) {
    return <Name>Model(
      id: entity.id,
      name: entity.name,
      periodStart: entity.periodStart,
      isFavorite: entity.isFavorite,
    );
  }

  // Freezed + json_serializable generate automatically:
  // - factory <Name>Model.fromJson(Map<String, dynamic> json) => _$...FromJson(json);
  // - Map<String, dynamic> toJson() => _$...ToJson(this);
}
```

**Rules:**
- Use `@freezed` + `@JsonSerializable()` together
- Annotate fields with `@JsonKey(name: 'column_name')` when JSON uses snake_case
- Implement `toEntity()` manually — Freezed does not generate this
- Implement static `fromEntity()` only if there is a need to reconstruct the Model from the Entity
- Import the corresponding entity at the top of the file

## Conversion Rules in Repository (_impl.dart)

The repository orchestrates conversion. Follow the typed switch pattern:

```dart
@override
Future<Result<List<<Name>Entity>>> get<Nomes>() async {
  final result = await _service.get<Nomes>();

  switch (result) {
    case Ok<List<<Name>Model>>():
      final value = result.value;
      return Result.ok(value.map((e) => e.toEntity()).toList());
    case Error<List<<Name>Model>>():
      final value = result;
      return Result.error(value.error);
  }
}

@override
Future<Result<<Name>Entity>> get<Name>(int id) async {
  final result = await _service.get<Name>(id);

  switch (result) {
    case Ok<<Name>Model>():
      final value = result.value;
      return Result.ok(value.toEntity());
    case Error<<Name>Model>():
      final value = result;
      return Result.error(value.error);
  }
}
```

## Special Cases

### Default Values with Freezed

```dart
@freezed
abstract class <Name>Entity with _$<Name>Entity {
  const factory <Name>Entity({
    @Default(false) bool isFavorite,
    @Default('active') String status,
  }) = _<Name>Entity;
}
```

### Mutable Classes (use `@unfreezed`)

Rarely needed in Entities. Use only if the domain requires mutability:

```dart
@unfreezed
abstract class <Name> with _$<Name> {
  factory <Name>({required String name}) = _<Name>;
}
```

### Inheritance with Freezed

```dart
class BaseClass {
  const BaseClass.name(this.value);
  final int value;
}

@freezed
abstract class MyFreezedClass extends BaseClass with _$MyFreezedClass {
  const MyFreezedClass._(super.value) : super.name();

  const factory MyFreezedClass(int value) = _MyFreezedClass;
}
```

### Union Types (Tagged Unions)

Useful for representing states or domain variants:

```dart
@freezed
sealed class <Name>State with _$<Name>State {
  const factory <Name>.loading() = Loading;
  const factory <Name>.success(<Name>Data> data) = Success;
  const factory <Name>.error(String message) = Error;
}
```

## Generation Checklist

Before finalizing generation, verify:

- [ ] Entity uses `@freezed` with primary constructor and mixin `_$<Name>Entity`
- [ ] Entity is immutable (no mutable fields, no `@unfreezed`)
- [ ] Entity does not import Flutter, Supabase, or external dependencies
- [ ] Model uses `@freezed` + `@JsonSerializable()`
- [ ] Model has `part '<name>_model.freezed.dart'` and `part '<name>_model.g.dart'`
- [ ] Model implements `toEntity()` manually
- [ ] Model implements static `fromEntity()` (only if needed)
- [ ] Fields with different names in JSON use `@JsonKey(name: '...')`
- [ ] Repository converts via `.map((e) => e.toEntity()).toList()` or `.toEntity()`
- [ ] Repository uses typed switch (`Ok<ConcreteModel>()`, `Error<ConcreteModel>()`)
- [ ] Generated files (`*.freezed.dart`, `*.g.dart`) are ignored in versioning

## Complete Example (Budget)

### Entity

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_entity.freezed.dart';

@freezed
abstract class BudgetEntity with _$BudgetEntity {
  const factory BudgetEntity({
    int? id,
    required String name,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double availableValue,
    required String currency,
    required String distributionType,
    @Default(false) bool isFavorite,
    @Default('active') String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BudgetEntity;
}
```

### Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entity/budget_entity.dart';

part 'budget_model.freezed.dart';
part 'budget_model.g.dart';

@freezed
@JsonSerializable()
class BudgetModel with _$BudgetModel {
  const factory BudgetModel({
    int? id,
    required String name,
    @JsonKey(name: 'period_start') required DateTime periodStart,
    @JsonKey(name: 'period_end') required DateTime periodEnd,
    @JsonKey(name: 'available_value') required double availableValue,
    required String currency,
    @JsonKey(name: 'distribution_type') required String distributionType,
    @JsonKey(name: 'is_favorite') @Default(false) bool isFavorite,
    @Default('active') String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _BudgetModel;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => _$BudgetModelFromJson(json);

  /// Converts model to domain entity
  BudgetEntity toEntity() {
    return BudgetEntity(
      id: id,
      name: name,
      periodStart: periodStart,
      periodEnd: periodEnd,
      availableValue: availableValue,
      currency: currency,
      distributionType: distributionType,
      isFavorite: isFavorite,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a Model from an Entity
  static BudgetModel fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      name: entity.name,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      availableValue: entity.availableValue,
      currency: entity.currency,
      distributionType: entity.distributionType,
      isFavorite: entity.isFavorite,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
```

### Repository (conversion)

```dart
@override
Future<Result<List<BudgetEntity>>> getBudgets() async {
  final result = await _service.getBudgets();

  switch (result) {
    case Ok<List<BudgetModel>>():
      final value = result.value;
      return Result.ok(value.map((e) => e.toEntity()).toList());
    case Error<List<BudgetModel>>():
      final value = result;
      return Result.error(value.error);
  }
}
```

## Post-Generation Commands

After creating the files:

```bash
# Generate Freezed + json_serializable code
dart run build_runner watch -d

# Or generate once (production)
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*_freezed.dart` and `*_g.dart`) should be added to `.gitignore`:

```
# Freezed generated files
*.freezed.dart
*.g.dart
```
