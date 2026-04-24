# Backend

This lightweight server creates real invite links for families.

## Run

1. `npm install`
2. `npm start`

Defaults to `http://localhost:4000`. The server listens on `0.0.0.0` so phones and cloud platforms can reach it.

Set `BASE_URL` to the URL your phone will use (HTTPS on a free host, or your LAN IP for local testing):

- `BASE_URL=http://192.168.1.50:4000 npm start`

On [Render](https://render.com), set `BASE_URL` to your service URL (or rely on `RENDER_EXTERNAL_URL`, which is picked up automatically). Use the HTTPS URL in the app’s backend setting on iPhone.

## Endpoints

- `POST /api/families` `{ "name": "The Riveras" }`
- `POST /api/families/join` `{ "code": "ABC123" }`
- `GET /api/invites/:code`
- `GET /invite/:code` (shareable link)

Data is stored in `backend/data/families.json`.
