# main.dart — Required change

Add `usePathUrlStrategy()` to main() for clean path URLs (F2/H2 Flutter translation).
This pairs with the F1 SPA rewrite in netlify.toml.

## Add this import to main.dart:
```dart
import 'package:flutter_web_plugins/url_strategy.dart';
```

## Add this call as the FIRST line inside main():
```dart
void main() async {
  usePathUrlStrategy(); // ← ADD THIS LINE FIRST
  WidgetsFlutterBinding.ensureInitialized();
  // ... rest of existing main()
}
```

## Add errorBuilder to GoRouter in router.dart:
```dart
import 'package:edupaths/core/router/app_router.dart';

// Inside your GoRouter(...) constructor, add:
errorBuilder: (context, state) => const NotFoundScreen(),
```

## Wire ExternalLink in course detail screens:
Replace:
```dart
onPressed: () => launchUrl(Uri.parse(course.url ?? ''))
```
With:
```dart
import 'package:edupaths/core/widgets/external_link.dart';
// ...
ExternalLink(url: course.url ?? '', label: 'Visit official site')
```
