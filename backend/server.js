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

/** Optional: HTTPS link to IPA, TestFlight, or App Store for the invite landing page. */
const APP_INSTALL_URL = String(process.env.APP_INSTALL_URL || "").trim();

const DATA_DIR = path.join(__dirname, "data");
const DATA_FILE = path.join(DATA_DIR, "families.json");

const app = express();
app.use(cors());
app.use(express.json({ limit: "256kb" }));

/** Swift JSONDecoder.iso8601 rejects fractional seconds. */
function toISO8601NoFraction(date) {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}

function escapeHtml(text) {
  return String(text || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

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
  };

  store.families.push(family);
  saveStore(store);

  return res.status(201).json(family);
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

  return res.json(family);
});

app.get("/api/invites/:code", (req, res) => {
  const code = normalizeInviteCode(req.params.code);
  const store = loadStore();
  const family = findFamilyByCode(store, code);
  if (!family) {
    return res.status(404).json({ error: "Invite code not found." });
  }
  return res.json(family);
});

app.get("/invite/:code", (req, res) => {
  const code = normalizeInviteCode(req.params.code);
  const store = loadStore();
  const family = findFamilyByCode(store, code);
  if (!family) {
    return res.status(404).send("Invite not found.");
  }

  const safeName = escapeHtml(family.name);
  const pageUrl = `${BASE_URL}/invite/${encodeURIComponent(family.inviteCode)}`;
  const deepLink =
    `findmyfriends://join?family=${encodeURIComponent(family.inviteCode)}`
    + `&api=${encodeURIComponent(BASE_URL)}`;
  const installBlock = APP_INSTALL_URL
    ? `<p style="margin-top:20px"><a class="btn secondary" href="${escapeHtml(APP_INSTALL_URL)}">Get the app (install)</a></p>
       <p class="hint">Sideload or TestFlight: open this link on your iPhone, install, then return here and tap <strong>Open in app</strong>.</p>`
    : `<p class="hint">Install Find My Friends on this phone (sideload or TestFlight), then tap <strong>Open in app</strong>. Ask the organizer for the install link, or set <code>APP_INSTALL_URL</code> on the server.</p>`;

  res.type("html").send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Join ${safeName}</title>
  <meta property="og:title" content="Join ${safeName} on Find My Friends" />
  <meta property="og:description" content="Tap Open in app to join this family, or use the invite code." />
  <meta property="og:url" content="${escapeHtml(pageUrl)}" />
  <style>
    body { font-family: -apple-system, Segoe UI, sans-serif; background:#0b0f1b; color:#f5f7ff; margin:0; }
    .wrap { max-width: 520px; margin: 40px auto; padding: 24px; }
    .card { background: #141a2b; border-radius: 20px; padding: 24px; box-shadow: 0 24px 40px rgba(0,0,0,.35); }
    h1 { font-size: 28px; margin: 0 0 12px; }
    p { color: #c4cbe1; line-height: 1.5; }
    .code { font-size: 24px; letter-spacing: 4px; font-weight: 700; margin: 16px 0; }
    .btn { display:inline-block; margin-top:8px; padding:14px 22px; border-radius:14px; font-weight:700; text-decoration:none; }
    .btn.primary { background: linear-gradient(135deg,#5b8cff,#8b5cf6); color:#fff; }
    .btn.secondary { background: #2a334d; color:#e8ecff; border:1px solid #3d4a6b; }
    .hint { font-size: 14px; color: #8b95b8; margin-top: 12px; }
    code { font-size: 13px; background:#0b0f1b; padding:2px 6px; border-radius:6px; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>Join ${safeName}</h1>
      <p>One link for everyone: install the app if needed, then open the family invite.</p>
      <a class="btn primary" href="${escapeHtml(deepLink)}">Open in app</a>
      ${installBlock}
      <p style="margin-top:24px">Or open Find My Friends → Circle → Join and enter:</p>
      <div class="code">${family.inviteCode}</div>
      <p class="hint">Share this page: <a href="${escapeHtml(pageUrl)}" style="color:#9db7ff">${escapeHtml(pageUrl)}</a></p>
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
