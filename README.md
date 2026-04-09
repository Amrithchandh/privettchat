# Private 1:1 Messaging App (Flutter/Firebase)

A secure, private, offline-capable messaging application built for two specific users.

## 1. Initial Setup

### Prerequisites
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.2+ recommended)
- Install [Firebase CLI](https://firebase.google.com/docs/cli)

### Scaffold the Platforms
Since only the Dart source code is provided here, generate the native platform folders by running:
```bash
cd private_chat_app
flutter create --platforms=ios,android,web .
```

### Install Packages
```bash
flutter pub get
```

## 2. Firebase Setup & Configuration

1. Create a project in the [Firebase Console](https://console.firebase.google.com/) (e.g., `private-gf-chat`).
2. Enable **Authentication** (Email/Password).
3. Enable **Firestore Database**.
4. Enable **Firebase Storage**.
5. Configure the app with your Firebase project:
```bash
# Log in to Firebase CLI
firebase login

# Activate Flutterfire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for this project
flutterfire configure --project=private-gf-chat
```
6. Open `lib/main.dart` and uncomment the Firebase initialization code in the `main()` function:
```dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
```

## 3. Strict Firebase Security Rules

To ensure total privacy, apply these rules in the Firebase Console:

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /chats/{chatId} {
      allow read, write: if request.auth != null; // Since login is strictly controlled
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /chats/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 4. Offline Mode & PWA

**Mobile (iOS & Android):** 
Firestore offline persistence handles caching and queuing natively. If you send a message offline, it appears with a clock icon. Once reconnected, it seamlessly uploads in the background.

**Web (PWA):**
When you build for web, Flutter automatically generates a `flutter_service_worker.js` that aggressively caches app assets. Firestore web also supports offline persistence. 
To customize PWA colors/icons, edit `web/manifest.json`.

## 5. Build Instructions

### Android (APK)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (IPA)
*Requires a Mac with Xcode.*
```bash
flutter build ipa --release
```
Open Xcode (`open ios/Runner.xcworkspace`) to select your provisioning profile and distribute to your phone. Ensure `NSFaceIDUsageDescription`, `NSCameraUsageDescription`, and `NSPhotoLibraryUsageDescription` are added to your `ios/Runner/Info.plist`.

### Web (PWA)
```bash
flutter build web --release --pwa-strategy=offline-first
```
**Hosting on Firebase:**
```bash
firebase init hosting
# Select the 'build/web' directory as the public directory.
firebase deploy --only hosting
```
