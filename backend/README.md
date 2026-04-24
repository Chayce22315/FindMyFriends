# Backend

This lightweight server creates real invite links for families and keeps a simple **member roster** so organizers can see who joined.

## Run

1. `npm install`
2. `npm start`

Listens on `0.0.0.0`. On Render, `RENDER_EXTERNAL_URL` is used for invite URLs when `BASE_URL` is unset.

- `BASE_URL=http://192.168.1.50:4000 npm start`

## Endpoints

- `POST /api/families`  
  Body: `{ "name": "The Riveras", "deviceId": "<uuid>", "displayName": "Alex" }`  
  `deviceId` / `displayName` optional but recommended so the organizer appears on the roster.

- `POST /api/families/join`  
  Body: `{ "code": "ABC123", "deviceId": "<uuid>", "displayName": "Jamie" }`  
  Response includes `newJoin: true` when this `deviceId` was newly added.

- `GET /api/families/:code/roster`  
  Returns `{ familyId, name, inviteCode, members: [{ deviceId, name, role, joinedAt }] }`.

- `GET /api/invites/:code`
- `GET /invite/:code` (shareable link)

Data is stored in `backend/data/families.json`.
