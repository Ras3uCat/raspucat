Scaffold a new feature module: $ARGUMENTS

Generate the complete file structure for a new module following this project's architecture.

**Input expected:** Feature name (e.g., "notifications", "search")

**Steps:**

1. **Derive the feature slug** from the input (snake_case)

2. **Create the module directory structure under `lib/app/modules/<slug>/`:**
```
lib/app/modules/<slug>/
├── controllers/
│   └── <slug>_controller.dart
├── views/
│   └── <slug>_view.dart
│   └── <slug>_screen.dart
└── data/
    ├── <slug>_repository.dart           (abstract)
    └── supabase_<slug>_repository.dart  (concrete)
```

3. **Scaffold with correct patterns:**

`<slug>_controller.dart`:
```dart
class <Feature>Controller extends GetxController {
  // RxTypes for reactive state
  // Methods for business logic only — no UI logic
}
```

`<slug>_view.dart`:
```dart
class <Feature>View extends GetView<<Feature>Controller> {
  const <Feature>View({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(...);
}
```

`<slug>_repository.dart` (abstract):
```dart
abstract class <Feature>Repository {
  // Method signatures only
}
```

`supabase_<slug>_repository.dart` (concrete):
```dart
class Supabase<Feature>Repository implements <Feature>Repository {
  // All Supabase calls isolated here
}
```

4. **Register the controller** in the appropriate binding or route.

5. **Create a backlog feature file:**
```
planning/features/00_backlog/NNN_<slug>.md
```
Use the next sequential ID.

Output a summary of all files created and next steps.
