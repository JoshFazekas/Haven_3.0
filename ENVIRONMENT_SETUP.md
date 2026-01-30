# Haven API & Environment Configuration

This document explains how to use the dev/prod environment switching system.

## Base URLs

- **Development**: `https://dev-api.havenlighting.com/api`
- **Production**: `https://prod-api.havenlighting.com/api`

## Quick Start

### Running the App

**Development Environment:**
```bash
# iOS Simulator
flutter run --flavor dev -t lib/main_dev.dart

# Android Emulator
flutter run --flavor dev -t lib/main_dev.dart
```

**Production Environment:**
```bash
# iOS Simulator  
flutter run --flavor prod -t lib/main_prod.dart

# Android Emulator
flutter run --flavor prod -t lib/main_prod.dart
```

### Building the App

**Development Build:**
```bash
# iOS
flutter build ios --flavor dev -t lib/main_dev.dart

# Android APK
flutter build apk --flavor dev -t lib/main_dev.dart

# Android App Bundle
flutter build appbundle --flavor dev -t lib/main_dev.dart
```

**Production Build:**
```bash
# iOS
flutter build ios --flavor prod -t lib/main_prod.dart

# Android APK
flutter build apk --flavor prod -t lib/main_prod.dart

# Android App Bundle
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

## iOS Xcode Schemes Setup

To enable flavors in iOS, you need to create schemes in Xcode:

### Step 1: Open the iOS project in Xcode
```bash
open ios/Runner.xcworkspace
```

### Step 2: Create Schemes

1. In Xcode, go to **Product** → **Scheme** → **Manage Schemes...**
2. Select the existing "Runner" scheme and click the **-** button to delete it (or keep it)
3. Click the **+** button to add new schemes

#### Create "dev" Scheme:
1. Click **+**, Target: Runner, Name: **dev**
2. Click **Edit Scheme** for the "dev" scheme
3. For **Run** → **Info** → Build Configuration: **Debug-dev**
4. For **Archive** → Build Configuration: **Release-dev**

#### Create "prod" Scheme:  
1. Click **+**, Target: Runner, Name: **prod**
2. Click **Edit Scheme** for the "prod" scheme
3. For **Run** → **Info** → Build Configuration: **Debug-prod**
4. For **Archive** → Build Configuration: **Release-prod**

### Step 3: Create Build Configurations

1. In Xcode, click on the project in the navigator
2. Select the **Runner** project (not target)
3. Go to the **Info** tab
4. Under **Configurations**, duplicate existing configurations:
   - Duplicate "Debug" → name it "Debug-dev"
   - Duplicate "Debug" → name it "Debug-prod"  
   - Duplicate "Release" → name it "Release-dev"
   - Duplicate "Release" → name it "Release-prod"
   - Duplicate "Profile" → name it "Profile-dev" (optional)
   - Duplicate "Profile" → name it "Profile-prod" (optional)

5. Set the xcconfig files for each configuration:
   - Debug-dev → Flutter/Debug-dev.xcconfig
   - Debug-prod → Flutter/Debug-prod.xcconfig
   - Release-dev → Flutter/Release-dev.xcconfig
   - Release-prod → Flutter/Release-prod.xcconfig

## File Structure

```
lib/
├── main.dart           # Default entry (defaults to dev)
├── main_dev.dart       # Development entry point
├── main_prod.dart      # Production entry point
├── core/
│   ├── api/
│   │   └── api_service.dart    # Dio-based API service
│   └── constants/
│       └── api_constants.dart  # Environment URLs & endpoints
```

## Using the API Service

```dart
import 'package:haven/core/api/api_service.dart';

// Get the singleton instance
final api = ApiService.instance;

// Set auth token after login
api.setAuthToken('your-jwt-token');

// Make API calls
final users = await api.getUsers();
final lights = await api.getLights();
await api.setLightColor(lightId: 123, red: 255, green: 0, blue: 0);

// Check current environment
if (ApiConstants.isDev) {
  print('Running in development mode');
}
```

## API Endpoints Available

- **Auth**: `login()`, `register()`, `refreshToken()`
- **Users**: `getUsers()`, `getUserById()`
- **Lights**: `getLights()`, `getLightById()`, `setLightColor()`, `toggleLight()`
- **Controllers**: `getControllers()`, `getControllerById()`
- **Zones**: `getZones()`, `getZoneById()`, `setZoneColor()`
- **Scenes**: `getScenes()`, `getSceneById()`, `activateScene()`
- **Schedules**: `getSchedules()`, `getScheduleById()`, `createSchedule()`
- **Effects**: `getEffects()`, `getEffectById()`, `applyEffect()`
- **Locations**: `getLocations()`, `getLocationById()`

## Android Flavors

Android flavors are automatically configured in `android/app/build.gradle.kts`:

- **dev**: `applicationIdSuffix = ".dev"`, app name = "Haven Dev"
- **prod**: app name = "Haven"

## VS Code Launch Configurations

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Haven (Dev)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_dev.dart",
      "args": ["--flavor", "dev"]
    },
    {
      "name": "Haven (Prod)",
      "request": "launch",
      "type": "dart", 
      "program": "lib/main_prod.dart",
      "args": ["--flavor", "prod"]
    }
  ]
}
```

## Troubleshooting

### "Unable to find a build configuration"
Make sure you've created the build configurations in Xcode (Debug-dev, Debug-prod, etc.)

### Pod install fails after adding flavors
Run:
```bash
cd ios
pod deintegrate
pod install
```

### Scheme not found
Ensure the scheme names match exactly: "dev" and "prod" (lowercase)
