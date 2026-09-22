---
name: test-creator-skill
description: "Create Flutter unit tests with mocktail. Trigger: create tests for entities, models, services, masks, validators, mixins."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load this skill whenever you need to generate unit tests in Flutter/Dart projects. Applies to:

- **Entities** — pure data, equals/hashCode/toString
- **Models** — JSON serialization, fromJson/toJson, copyWith
- **Services** — business logic, external calls, retry/circuit-breaker
- **Masks** — UI/state transformation intermediates
- **Validators** — validation rules, regex, constraints
- **Mixins** — shared behavior, extension methods

## Fundamental Rules

### 1. Zero False Positives

Every test must be **deterministic**. If a test fails intermittently or depends on uncontrolled external state, it is invalid and must be discarded.

| Anti-pattern | Solution |
|---|---|
| `expect(actual, isTrue)` without context of why | Specify the exact expected value: `expect(actual, equals(expected))` |
| Test depending on execution order | Each test is isolated; setUp creates fresh state every time |
| Mocks with overly generic `any` | Use `anyThat(isA<Type>())` or specific values when possible |
| `await` without timeout for async operations | Always use `expectLater(..., completes)` or explicit timeouts |
| Verifying implementation instead of behavior | Test public contracts, not private methods |

### 2. Happy Path and Sad Paths

For each entity/model/service/mask/validator/mixin, cover:

- **Happy path** — valid input → expected result without error
- **Sad paths** — invalid inputs, nulls, boundaries, error states

```dart
// Example: validator with happy + sad paths
group('EmailValidator', () {
  test('happy path: valid email returns true'), // ✅
  test('sad path: null throws exception'),      // ✅
  test('sad path: empty string returns false'), // ✅
  test('sad path: missing @ returns false'),    // ✅
});
```

### 3. Mocktail — Correct Patterns

#### Records (Dart 3+) for multiple return values

```dart
// Dart 3+ records with mocktail
when(() => service.fetchData(any())).thenAnswer((_) async => const <String, dynamic>{'error': 'network'});
```

#### Argument matchers

```dart
// Specific (preferred)
when(() => validator.validate('test@example.com')).thenReturn(true);

// Generic when necessary
import 'package:mocktail/mocktail.dart';

when(() => repository.save(any())).thenAnswer((_) async => Future.value(result));

// Match by type/property
when(() => repository.findByStatus(anyThat(isA<Status>())))
    .thenReturn(expectedList);
```

#### Fallback for unsupported functions

```dart
import 'package:mocktail/mocktail.dart';

void setUp() {
  mocktailFallback((_) => throw UnsupportedError('Not supported by mocktail'));
}
```

### 4. Test Structure

Organize groups by responsibility:

```dart
group('<ClassName>', () {
  late ClassName subject;
  late MockDependency dependency;

  setUp(() {
    // Fresh state in each test
    dependency = MockDependency();
    subject = ClassName(dependency);
  });

  group('happy path', () {
    test('description of valid scenario');
  });

  group('sad paths', () {
    test('null input throws');
    test('empty string returns false');
    test('invalid format fails validation');
    test('timeout on slow operation');
  });

  group('edge cases', () {
    test('boundary value at limit');
    test('concurrent calls handled correctly');
  });
});
```

## Coverage Matrix

### Entities

| Aspect | Happy Path | Sad Paths |
|---|---|---|
| Constructor | Valid instance with minimal data | Null fields, negative values |
| `equals` | Same values → true | Different values → false |
| `hashCode` | Consistent with equals | Equals changes, hashCode changes |
| `toString` | Readable format | Null fields don't break it |

### Models

| Aspect | Happy Path | Sad Paths |
|---|---|---|
| `fromJson` | Complete and valid JSON | Incomplete JSON, wrong types, nulls |
| `toJson` | Object serialized correctly | Optional fields omitted |
| `copyWith` | All fields updated | No fields passed (original intact) |

### Services

| Aspect | Happy Path | Sad Paths |
|---|---|---|
| Main method | External call returns success | Timeout, network error, 4xx/5xx |
| Retry logic | Retries on transient failures | Permanent failure after retries exhausted |
| Cache | Cached data returns fast | Expired or invalidated cache |

### Masks

| Aspect | Happy Path | Sad Paths |
|---|---|---|
| Formatting | Input → formatted output | Empty input, overly long input |
| Parse | String → structured value | Invalid string, wrong format |

### Validators

| Aspect | Happy Path | Sad Paths |
|---|---|---|
| Validation | Valid input → true/pass | Null, empty, over-length, wrong format |
| Error message | Error describes the problem | Non-null error even for valid input |

### Mixins

| Aspect | Happy Path | Sad Paths |
|---|---|---|
| Inherited behavior | Class uses mixin correctly | Class without required implementation |
| Extension methods | Calls extended method | Null reference, inconsistent state |

## Execution Flow

1. **Identify** the target file and its dependencies
2. **Map** all public responsibilities (constructors, methods, getters)
3. **Generate** tests for each responsibility covering happy + sad paths
4. **Validate** that every test is deterministic and doesn't depend on uncontrolled external state
5. **Verify** that mocks are used correctly with `when().thenAnswer()` or `thenReturn()`

## Specific Mocktail Rules

### When to use `thenAnswer` vs `thenReturn`

- `thenReturn` for simple synchronous values
- `thenAnswer` for async, callbacks, or when you need to inspect arguments

```dart
// thenReturn — sync, simple
when(() => validator.validate('email@test.com')).thenReturn(true);

// thenAnswer — async or complex
when(() => service.fetchData(any())).thenAnswer((_) async {
  // can inspect the passed argument
  return const <String, dynamic>{};
});
```

### Verification calls (verifications)

```dart
// Verify method was called N times
verify(() => dependency.method(any())).called(3);

// Never called
verifyNever(() => dependency.unusedMethod());

// Always in order
verifyInOrder([
  () => dependency.first(),
  () => dependency.second(),
]);
```

## Anti-Patterns to Avoid

| What to do | Why avoid | Alternative |
|---|---|---|
| `expect(true, isTrue)` | Doesn't say what should be true | `expect(actual, equals(expectedValue))` |
| Test private methods | Violates encapsulation | Test via public API |
| Use `any()` blindly | Masks wrong arguments | Use specific matchers: `anyThat(isA<Type>())`, `anything`, literal values |
| Depend on test order | Fails intermittently in CI | Each test self-contained with clean setUp |
| Mock everything | Tests the mock, not the class | Only mock external dependencies (HTTP, DB, storage) |

## Complete Examples — Service

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trainer_platform_app/services/data_service.dart';
import 'package:trainer_platform_app/models/response_model.dart';

// Mocks
class MockHttpClient extends Mock implements HttpClient {}
class MockResponseModel extends Mock implements ResponseModel {}

void main() {
  group('DataService', () {
    late DataService subject;
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      subject = DataService(mockClient);
    });

    group('fetchUser', () {
      test('happy path: returns model when API responds 200', () async {
        // Arrange
        when(() => mockClient.getUrl(any())).thenAnswer(
          (_) async => MockResponseModel()..statusCode = 200,
        );

        // Act
        final result = await subject.fetchUser('123');

        // Assert
        expect(result, isA<ResponseModel>());
        verify(() => mockClient.getUrl(any())).called(1);
      });

      test('sad path: throws exception when API returns 404', () async {
        when(() => mockClient.getUrl(any())).thenAnswer(
          (_) async => MockResponseModel()..statusCode = 404,
        );

        expect(() => subject.fetchUser('999'), throwsException);
      });

      test('sad path: throws timeout on slow response', () async {
        when(() => mockClient.getUrl(any())).thenAnswer(
          (_) async => Future.delayed(Duration(seconds: 30),
            () => MockResponseModel()..statusCode = 200,
          ),
        );

        expect(() => subject.fetchUser('123'), throwsException);
      });
    });
  });
}
```

## Complete Examples — Validator

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:trainer_platform_app/validators/email_validator.dart';

void main() {
  group('EmailValidator', () {
    late EmailValidator subject;

    setUp(() {
      subject = EmailValidator();
    });

    group('happy path', () {
      test('valid email returns true', () {
        expect(subject.validate('test@example.com'), isTrue);
      });

      test('email with subdomain is valid', () {
        expect(subject.validate('user@mail.example.com'), isTrue);
      });
    });

    group('sad paths', () {
      test('null throws ArgumentError', () {
        expect(() => subject.validate(null), throwsArgumentError);
      });

      test('empty string returns false', () {
        expect(subject.validate(''), isFalse);
      });

      test('missing @ returns false', () {
        expect(subject.validate('testexample.com'), isFalse);
      });

      test('only @ returns false', () {
        expect(subject.validate('@'), isFalse);
      });

      test('overly long email (>254 chars) returns false', () {
        final longEmail = '${'a' * 250}@example.com';
        expect(subject.validate(longEmail), isFalse);
      });
    });
  });
}
```

## Final Checklist

Before finalizing generated tests, verify:

- [ ] Each test is self-contained (setUp creates fresh state)
- [ ] Mocks are only used for external dependencies
- [ ] Happy paths cover minimal and complete valid inputs
- [ ] Sad paths cover null, empty, boundaries, API errors
- [ ] No test depends on order or uncontrolled external state
- [ ] Matchers are specific (avoid generic `isTrue`)
- [ ] Mock verifications use `called(N)` when relevant
- [ ] Async tests have explicit timeouts
