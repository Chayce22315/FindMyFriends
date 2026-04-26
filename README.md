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

Apple does not offer a public “download IPA from Safari and install” flow like Android APKs. Many people use **third‑party sideload installers** (for example **Scarlet** or similar clients) to install IPAs without Xcode. Those tools are **not** from Apple; trust, revocation, and limits depend entirely on the tool and its signing pipeline.

**Unsigned / CI-built IPAs:** Some clients (including **Scarlet**, per their documentation) **re‑sign the IPA for you at install time** using signing infrastructure they operate, so you do **not** need an IPA that was already signed with your own Apple Developer certificate. You still install a normal `.ipa` produced by CI or exported from Xcode; the sideload app replaces the signature before or during install.

**Typical flow**

1. Get the **IPA** (e.g. from a successful **GitHub Actions** run on this repo: download the workflow artifact, or attach the IPA from a release you publish).
2. On your iPhone, install your chosen sideload client **from that project’s official instructions** (follow their current install guide — it changes over time).
3. In the client, import or install the **FindMyFriends** IPA (often via URL, file share, or “Install from link,” depending on the app).
4. If iOS shows **“Untrusted Developer”**: **Settings → General → VPN & Device Management** → trust the profile listed for that install.
5. Open **Find My Friends**. If **Health** or **Apple Music** misbehave, the app’s **embedded entitlements** (from how the IPA was built) still have to be allowed for the identity that ends up signing the bundle; fully predictable behavior usually means a build signed under **your** Apple Developer Program with HealthKit + MusicKit enabled for your App ID.

**Caveats**

- Third‑party sideloading can stop working when certificates are revoked or iOS changes behavior; keep a fallback (Xcode install from source, or TestFlight once you have a paid membership).
- Only install IPAs from **sources you trust** (your own CI artifact, your own release asset, or a maintainer you trust).
