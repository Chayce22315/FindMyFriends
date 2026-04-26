# FindMyFriends
A simple location app designed to find friends & family.

## Backend
Invite links are powered by the lightweight server in `backend/`.
See `backend/README.md` for setup.

The iOS app’s default public API URL is set in `lib/App/InviteServerConfiguration.swift` (change it if you deploy your own host).

## Apple Developer portal (Health + Music)

- **HealthKit:** Enable the HealthKit capability for your App ID; the app uses `App.entitlements` (`com.apple.developer.healthkit`).
- **MusicKit:** Enable **MusicKit** under App Services for the same App ID, then refresh your provisioning profile so `com.apple.developer.music-kit` matches your team signing. Without this, catalog / recently-played APIs may not work on device.

## Installing the IPA (third‑party sideloading)

Apple does not offer a public “download IPA from Safari and install” flow like Android APKs. Many people use **third‑party sideload installers** (for example **Scarlet** or similar clients) to install IPAs without Xcode. Those tools are **not** from Apple; trust, revocation, and limits depend entirely on the tool and how the IPA was signed.

**Typical flow**

1. Get the **IPA** (e.g. from a successful **GitHub Actions** run on this repo: download the workflow artifact, or attach the IPA from a release you publish).
2. On your iPhone, install your chosen sideload client **from that project’s official instructions** (follow their current install guide — it changes over time).
3. In the client, import or install the **FindMyFriends** IPA (often via URL, file share, or “Install from link,” depending on the app).
4. If iOS shows **“Untrusted Developer”**: **Settings → General → VPN & Device Management** → trust the profile listed for that install.
5. Open **Find My Friends**. If **Health** or **Apple Music** features complain about entitlements, the IPA may have been signed without the right capabilities for your Apple ID; builds you produce with your own **paid** Developer Program + matching App ID capabilities are the most predictable.

**Caveats**

- Third‑party sideloading can stop working when certificates are revoked or iOS changes behavior; keep a fallback (Xcode install from source, or TestFlight once you have a paid membership).
- Only install IPAs from **sources you trust** (your own CI artifact, your own release asset, or a maintainer you trust).
