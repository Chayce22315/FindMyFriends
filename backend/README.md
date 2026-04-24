# Backend

This lightweight server creates real invite links for families.

## Run

1. `npm install`
2. `npm start`

Defaults to `http://localhost:4000`. Listens on `0.0.0.0`. On Render, `RENDER_EXTERNAL_URL` is used for invite URLs when `BASE_URL` is unset.

- `BASE_URL=http://192.168.1.50:4000 npm start`

**Invite page:** `GET /invite/:code` shows **Open in app** (deep link `findmyfriends://join?family=CODE&api=BASE_URL` so join works without typing the server URL) plus the code. Optional **`APP_INSTALL_URL`**: set to your TestFlight, App Store, or hosted IPA download page so newcomers see a **Get the app** button.

## Endpoints

- `POST /api/families` `{ "name": "The Riveras" }`
- `POST /api/families/join` `{ "code": "ABC123" }`
- `GET /api/invites/:code`
- `GET /invite/:code` (shareable link — open in Safari; share the same URL from the app after creating a family)

Data is stored in `backend/data/families.json`.
