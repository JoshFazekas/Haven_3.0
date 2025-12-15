# Haven Light Control - Color Setting API Integration

## Overview

This implementation adds automatic API calls when users select colors in the Haven lighting app. When a user selects a color from the color palette, the app:

1. **Optimistically updates the UI** - Shows the new color immediately
2. **Calls the API** - Sends the color change to the lighting system
3. **Provides feedback** - Shows success/error messages

## Features

- ✅ **Add Color Button** - Grey circle with plus icon at the end of color list
- ✅ **Automatic Toggle** - Toggle turns on when color is selected
- ✅ **Color Matching** - Toggle and container show selected color
- ✅ **Optimistic Updates** - UI updates immediately on color selection
- ✅ **API Integration** - Sends HTTP POST requests to set colors
- ✅ **Error Handling** - Shows success/error feedback to users

## Configuration

### 1. API Settings

Update the configuration in `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://your-actual-api-url.com';
  static const String bearerToken = 'YOUR_ACTUAL_TOKEN';
  static const int defaultLocationId = 27040; // Your location ID
}
```

### 2. Supported API Endpoints

The service supports multiple endpoint patterns:

```
POST /App/Light/SetColor               (with locationId in body)
POST /App/Light/{lightId}/SetColor     (light-specific)
POST /App/Zone/{zoneId}/SetColor       (zone-specific)  
POST /App/Controller/{id}/SetColor     (controller-specific)
POST /App/Light/Command                (generic command)
```

### 3. Usage Example

When creating `LightZoneCard` widgets, pass the appropriate IDs:

```dart
LightZoneCard(
  channelName: 'Channel 1',
  lightName: 'Living Room Lights',
  lightId: 123,        // For /App/Light/123/SetColor
  locationId: 27040,   // For /App/Light/SetColor
  zoneId: 456,         // For /App/Zone/456/SetColor
)
```

## API Request Format

### Set Color by Location
```json
POST /App/Light/SetColor
{
  "locationId": 27040,
  "red": 255,
  "green": 0, 
  "blue": 0,
  "brightness": 100
}
```

### Set Color by Light ID
```json
POST /App/Light/123/SetColor
{
  "red": 255,
  "green": 0,
  "blue": 0, 
  "brightness": 100
}
```

### Red Color Example
To set a light to red (as requested):
- **red**: 255
- **green**: 0
- **blue**: 0
- **brightness**: 100 (default)

## How It Works

1. **Color Selection**: User taps a color in the palette
2. **Immediate UI Update**: 
   - Selected color shows border and shadow
   - Toggle automatically turns on
   - Container shows color with opacity
   - Toggle animation plays with color filter
3. **API Call**: HTTP POST sent to appropriate endpoint
4. **Feedback**: Success/error message displayed
5. **Done Button**: Returns color data to parent screen

## Error Handling

- **Network errors** - Shows error snackbar
- **API failures** - Shows failure message  
- **Loading state** - Done button shows spinner during API calls
- **Optimistic updates** - UI updates immediately regardless of API success

## Testing

The app will work with the current placeholder API configuration. To test with real hardware:

1. Update `ApiConfig` with your actual API URL and token
2. Set real light/zone/location IDs when creating `LightZoneCard` widgets
3. Monitor debug console for API request/response logs

## Debug Output

All API calls are logged to the debug console:

```
Color selected: Color(0xffff0000)
SetColorByLightId Response: 200 - {"success": true}
Light Living Room Lights updated: Color=Color(0xffff0000), IsOn=true
```
