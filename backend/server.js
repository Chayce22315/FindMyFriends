const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const PORT = Number(process.env.PORT || 4000);

function defaultBaseUrlFromEnv() {
  const render = process.env.RENDER_EXTERNAL_URL;
  if (render && String(render).trim()) {
    return normalizeBaseUrl(render);
  }
  return `http://localhost:${PORT}`;
}

const BASE_URL = normalizeBaseUrl(
  process.env.BASE_URL || defaultBaseUrlFromEnv()
);

function toISO8601NoFraction(date) {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}

const DATA_DIR = path.join(__dirname, "data");
const DATA_FILE = path.join(DATA_DIR, "families.json");

const app = express();
app.use(cors());
app.use(express.json({ limit: "256kb" }));

function normalizeBaseUrl(url) {
  if (!url) {
    return "";
  }
  const trimmed = url.trim();
  if (!trimmed) {
    return "";
  }
  const withScheme = trimmed.startsWith("http://") || trimmed.startsWith("https://")
    ? trimmed
    : `http://${trimmed}`;
  return withScheme.endsWith("/") ? withScheme.slice(0, -1) : withScheme;
}

function loadStore() {
  try {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
    if (!fs.existsSync(DATA_FILE)) {
      return { families: [] };
    }
    const raw = fs.readFileSync(DATA_FILE, "utf8");
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || !Array.isArray(parsed.families)) {
      return { families: [] };
    }
    for (const f of parsed.families) {
      if (!Array.isArray(f.members)) {
        f.members = [];
      }
    }
    return parsed;
  } catch (error) {
    return { families: [] };
  }
}

function saveStore(store) {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
  fs.writeFileSync(DATA_FILE, JSON.stringify(store, null, 2), "utf8");
}

function generateInviteCode() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let out = "";
  for (let i = 0; i < 6; i += 1) {
    out += chars[Math.floor(Math.random() * chars.length)];
  }
  return out;
}

function buildInviteUrl(code) {
  return `${BASE_URL}/invite/${code}`;
}

function normalizeInviteCode(code) {
  return String(code || "").trim().toUpperCase();
}

function findFamilyByCode(store, code) {
  const normalized = normalizeInviteCode(code);
  return store.families.find((family) => family.inviteCode === normalized);
}

function publicFamilyPayload(family) {
  return {
    id: family.id,
    name: family.name,
    inviteCode: family.inviteCode,
    inviteUrl: family.inviteUrl,
    createdAt: family.createdAt,
    memberCount: Array.isArray(family.members) ? family.members.length : 0,
  };
}

function rosterPayload(family) {
  const members = Array.isArray(family.members) ? family.members : [];
  return {
    familyId: family.id,
    name: family.name,
    inviteCode: family.inviteCode,
    members: members.map((m) => ({
      deviceId: m.deviceId,
      name: m.name,
      role: m.role,
      joinedAt: m.joinedAt,
    })),
  };
}

function upsertMember(family, { deviceId, name, role }) {
  if (!family.members) {
    family.members = [];
  }
  const id = String(deviceId || "").trim();
  const display = String(name || "Someone").trim().slice(0, 80) || "Someone";
  const r = String(role || "Member").trim().slice(0, 40) || "Member";
  if (!id) {
    return { added: false, duplicate: false };
  }
  const existing = family.members.find((m) => m.deviceId === id);
  if (existing) {
    existing.name = display;
    existing.role = r;
    return { added: false, duplicate: true };
  }
  family.members.push({
    deviceId: id,
    name: display,
    role: r,
    joinedAt: toISO8601NoFraction(new Date()),
  });
  return { added: true, duplicate: false };
}

app.get("/health", (req, res) => {
  res.json({ ok: true, time: new Date().toISOString() });
});

app.post("/api/families", (req, res) => {
  const name = String(req.body?.name || "").trim();
  if (!name) {
    return res.status(400).json({ error: "Family name is required." });
  }

  const store = loadStore();
  let inviteCode = generateInviteCode();
  while (findFamilyByCode(store, inviteCode)) {
    inviteCode = generateInviteCode();
  }

  const family = {
    id: crypto.randomUUID(),
    name,
    inviteCode,
    inviteUrl: buildInviteUrl(inviteCode),
    createdAt: toISO8601NoFraction(new Date()),
    members: [],
  };

  const deviceId = String(req.body?.deviceId || "").trim();
  const displayName = String(req.body?.displayName || "Organizer").trim().slice(0, 80) || "Organizer";
  if (deviceId) {
    upsertMember(family, { deviceId, name: displayName, role: "Organizer" });
  }

  store.families.push(family);
  saveStore(store);

  return res.status(201).json(publicFamilyPayload(family));
});

app.post("/api/families/join", (req, res) => {
  const code = normalizeInviteCode(req.body?.code);
  if (!code) {
    return res.status(400).json({ error: "Invite code is required." });
  }

  const store = loadStore();
  const family = findFamilyByCode(store, code);
  if (!family) {
    return res.status(404).json({ error: "Invite code not found." });
  }

  const deviceId = String(req.body?.deviceId || "").trim();
  const displayName = String(req.body?.displayName || "Member").trim().slice(0, 80) || "Member";
  let newJoin = false;
  if (deviceId) {
    const { added } = upsertMember(family, { deviceId, name: displayName, role: "Member" });
    newJoin = added;
    saveStore(store);
  }

  const body = publicFamilyPayload(family);
  body.newJoin = newJoin;
  return res.json(body);
});

app.get("/api/families/:code/roster", (req, res) => {
  const code = normalizeInviteCode(req.params.code);
  const store = loadStore();
  const family = findFamilyByCode(store, code);
  if (!family) {
    return res.status(404).json({ error: "Invite code not found." });
  }
  return res.json(rosterPayload(family));
});

app.get("/api/invites/:code", (req, res) => {
  const code = normalizeInviteCode(req.params.code);
  const store = loadStore();
  const family = findFamilyByCode(store, code);
  if (!family) {
    return res.status(404).json({ error: "Invite code not found." });
  }
  return res.json(publicFamilyPayload(family));
});

app.get("/invite/:code", (req, res) => {
  const code = normalizeInviteCode(req.params.code);
  const store = loadStore();
  const family = findFamilyByCode(store, code);
  if (!family) {
    return res.status(404).send("Invite not found.");
  }

  res.type("html").send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Join ${family.name}</title>
  <style>
    body { font-family: -apple-system, Segoe UI, sans-serif; background:#0b0f1b; color:#f5f7ff; margin:0; }
    .wrap { max-width: 520px; margin: 40px auto; padding: 24px; }
    .card { background: #141a2b; border-radius: 20px; padding: 24px; box-shadow: 0 24px 40px rgba(0,0,0,.35); }
    h1 { font-size: 28px; margin: 0 0 12px; }
    p { color: #c4cbe1; line-height: 1.5; }
    .code { font-size: 24px; letter-spacing: 4px; font-weight: 700; margin: 16px 0; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>Join ${family.name}</h1>
      <p>Open Find My Friends and use this invite code to join.</p>
      <div class="code">${family.inviteCode}</div>
      <p>If you already have the app open, tap Join and paste the code.</p>
    </div>
  </div>
</body>
</html>`);
});

const HOST = process.env.HOST || "0.0.0.0";

app.listen(PORT, HOST, () => {
  console.log(`FindMyFriends backend listening on http://${HOST}:${PORT}`);
  console.log(`Public BASE_URL (invite links): ${BASE_URL}`);
});
