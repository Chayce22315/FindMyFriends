# Backend

This lightweight server creates real invite links for families.

## Run

1. `npm install`
2. `npm start`

Defaults to `http://localhost:4000`.
Set `BASE_URL` if you are hosting elsewhere:

- `BASE_URL=http://192.168.1.50:4000 npm start`

## Endpoints

- `POST /api/families` `{ "name": "The Riveras" }`
- `POST /api/families/join` `{ "code": "ABC123" }`
- `GET /api/invites/:code`
- `GET /invite/:code` (shareable link)

Data is stored in `backend/data/families.json`.
