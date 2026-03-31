---
description: Testing conventions and requirements. Apply when editing or creating files in test/.
globs: ["test/**/*.dart"]
---

# Testing Rules

## Structure
`test/` mirrors `lib/` exactly. If the file is `lib/app/modules/auth/data/auth_repository.dart`,
the test is `test/app/modules/auth/data/auth_repository_test.dart`.

## Required Coverage
Every new file in `lib/` that contains business logic MUST have a corresponding test file.
No feature moves to `02_completed/` without passing tests.

## Naming Conventions
```dart
group('QuoteRepository', () {
  test('returns QuoteModel on successful fetch', () async { ... });
  test('returns null on not found', () async { ... });
});
```

## GetX Testing
```dart
setUp(() {
  Get.testMode = true;
  Get.put(MockQuoteRepository());
  Get.put(QuoteController());
});
tearDown(() => Get.reset());
```

## Dart 3.8+ Notes
- `Color.alpha`/`.opacity` deprecated in tests too — use `.a` (0.0–1.0)

## Forbidden Patterns
- `expect(true, true)` — meaningless assertions
- Tests that only verify the mock was called (verify behavior, not implementation)
- Skipped tests (`skip: true`) committed to main — fix or delete them
- Mocking the class under test
