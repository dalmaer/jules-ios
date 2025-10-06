# Background Notifications Setup

This app now supports background notifications for new Jules activities, even when the app isn't running.

## How It Works

1. **Foreground Polling**: When viewing a session, the app checks for new activities every 30 seconds
2. **Background Fetch**: iOS periodically wakes the app to check for new activities (typically every 15-30 minutes)
3. **Deep Linking**: Tapping a notification opens the app directly to the relevant session

## Xcode Setup Required

### 1. Enable Background Modes
1. Open the project in Xcode
2. Select the **Jules** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Background Modes**
6. Check these boxes:
   - ✅ **Background fetch**
   - ✅ **Background processing**

### 2. Add Info.plist to Build
The `Info.plist` file has been created with the necessary background task identifier. Xcode should automatically include it.

## Testing Background Notifications

### Test in Simulator
```bash
# Trigger background fetch manually
xcrun simctl push booted com.jules.ios --background-task com.jules.ios.refresh
```

### Test on Device
1. Run the app from Xcode
2. Open a session to start monitoring
3. Put the app in background
4. Wait for iOS to trigger background fetch (15-30 min)
5. Or use Xcode's Debug > Simulate Background Fetch

## How Notifications Work

### When App is Running
- Polls every 30 seconds for new activities
- Shows notification banner even when app is in foreground

### When App is in Background
- iOS wakes app periodically (system controlled)
- Checks monitored sessions for new activities
- Sends local notification if new agent activity found

### When App is Killed by User
- Background tasks stop (iOS limitation)
- No notifications until app is opened again

## Limitations

### iOS Background Fetch Limitations
- **Not guaranteed**: iOS decides when to run background tasks
- **Frequency**: Typically 15-30 minutes, based on app usage patterns
- **Battery**: iOS may reduce frequency if battery is low
- **Killed apps**: Won't work if user force-quits the app

### Better Alternative: Push Notifications
For real-time notifications when app isn't running, the Jules API would need to implement push notifications via APNs (Apple Push Notification service). This requires:
1. Server-side APNs integration
2. Device token registration
3. Jules API sending push notifications when activities complete

## Files Added

- **BackgroundTaskManager.swift**: Handles background fetch and activity checking
- **NotificationManager.swift**: Manages local notifications with deep linking
- **JulesApp.swift**: Updated with AppDelegate for background tasks and notification handling
- **Info.plist**: Background modes configuration
- **NavigationCoordinator**: Handles deep linking from notifications

## How to Monitor Sessions

Sessions are automatically monitored when you open them in the app. The app tracks:
- Session ID and title
- Last activity ID (to detect new activities)
- All monitored sessions persist across app launches
