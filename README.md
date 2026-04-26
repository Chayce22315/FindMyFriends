# FindMyFriends
A simple location app designed to find friends & family.

## Backend
Invite links are powered by the lightweight server in `backend/`.
See `backend/README.md` for setup.

The iOS app’s default public API URL is set in `lib/App/InviteServerConfiguration.swift` (change it if you deploy your own host).

## Apple Developer portal (Health + Music)

- **HealthKit:** Enable the HealthKit capability for your App ID; the app uses `App.entitlements` (`com.apple.developer.healthkit`).
- **MusicKit:** Enable **MusicKit** under App Services for the same App ID, then refresh your provisioning profile so `com.apple.developer.music-kit` matches your team signing. Without this, catalog / recently-played APIs may not work on device.
