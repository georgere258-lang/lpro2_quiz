// PATH: tools/firestore_upload/upload_pro_insight.js
// Upload Pro Insight topics into Firestore collection: pro_insight
// Usage:
//   node upload_pro_insight.js <jsonFilePath>
// Example:
//   node upload_pro_insight.js ..\..\questions\pro_insight\pro_insight_level1.json

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

// ---- Load service account key (LOCAL ONLY) ----
const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");
if (!fs.existsSync(serviceAccountPath)) {
  console.error("❌ Missing serviceAccountKey.json in tools/firestore_upload/");
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

// ---- Init Firebase Admin ----
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const COLLECTION = "pro_insight";
const BATCH_LIMIT = 450; // safe margin under 500

function isPlainObject(v) {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}

function normalizeTags(tags) {
  if (!Array.isArray(tags)) return [];
  return tags
    .map((t) => String(t || "").trim())
    .filter((t) => t.length > 0);
}

function safeString(v) {
  return String(v ?? "").trim();
}

function safeBool(v, def = true) {
  if (typeof v === "boolean") return v;
  return def;
}

function safeInt(v, def = 1) {
  const n = Number(v);
  if (Number.isFinite(n) && n > 0) return Math.floor(n);
  return def;
}

function buildDoc(item) {
  // Accept either "core" or "insight" for the main body (some old docs used insight)
  const core = safeString(item.core || item.insight);

  return {
    title: safeString(item.title),
    hook: safeString(item.hook),
    reset: safeString(item.reset),
    core: core,
    example: safeString(item.example),
    lock: safeString(item.lock),
    tags: normalizeTags(item.tags),
    level: safeInt(item.level, 1),
    isActive: safeBool(item.isActive, true),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function validateDoc(doc) {
  // minimal validity
  if (!doc.title) return "missing title";
  if (!doc.core && !doc.hook && !doc.reset) return "content too empty";
  if (!Array.isArray(doc.tags)) return "tags must be array";
  if (typeof doc.level !== "number" || doc.level < 1) return "invalid level";
  return null;
}

function makeDocId(doc, index) {
  // Stable-ish id: level + timestamp + index
  const ms = Date.now();
  const safeTitle = doc.title
    .toLowerCase()
    .replace(/\s+/g, "_")
    .replace(/[^\u0600-\u06FFa-z0-9_]/gi, "")
    .slice(0, 36);

  return `L${doc.level}_${ms}_${index}_${safeTitle || "topic"}`;
}

async function main() {
  const jsonPathArg = process.argv[2];
  if (!jsonPathArg) {
    console.error("❌ Missing JSON file path.\nUsage: node upload_pro_insight.js <jsonFilePath>");
    process.exit(1);
  }

  const jsonFilePath = path.isAbsolute(jsonPathArg)
    ? jsonPathArg
    : path.join(process.cwd(), jsonPathArg);

  if (!fs.existsSync(jsonFilePath)) {
    console.error(`❌ JSON file not found: ${jsonFilePath}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(jsonFilePath, "utf8");
  let arr;
  try {
    arr = JSON.parse(raw);
  } catch (e) {
    console.error("❌ Invalid JSON. Make sure it is valid JSON Array.");
    process.exit(1);
  }

  if (!Array.isArray(arr)) {
    console.error("❌ JSON must be an Array of Objects: [ {...}, {...} ]");
    process.exit(1);
  }

  console.log(`📥 Loading ${arr.length} topics from ${path.basename(jsonFilePath)}`);
  console.log(`📤 Uploading into Firestore collection: ${COLLECTION}`);

  // Build + validate
  const docs = [];
  for (let i = 0; i < arr.length; i++) {
    const item = arr[i];
    if (!isPlainObject(item)) continue;

    const doc = buildDoc(item);
    const err = validateDoc(doc);
    if (err) {
      console.log(`⚠️ Skipped item #${i + 1}: ${err}`);
      continue;
    }
    docs.push(doc);
  }

  if (docs.length === 0) {
    console.error("❌ No valid topics to upload.");
    process.exit(1);
  }

  let uploaded = 0;
  while (uploaded < docs.length) {
    const batch = db.batch();
    const chunk = docs.slice(uploaded, uploaded + BATCH_LIMIT);

    chunk.forEach((doc, idx) => {
      const docId = makeDocId(doc, uploaded + idx);
      const ref = db.collection(COLLECTION).doc(docId);
      batch.set(ref, doc, { merge: false });
    });

    await batch.commit();
    uploaded += chunk.length;
    console.log(`✅ Committed batch: ${uploaded}/${docs.length}`);
  }

  console.log("🎉 Done. Pro Insight topics uploaded successfully.");
}

main().catch((e) => {
  console.error("❌ Upload failed:", e?.message || e);
  process.exit(1);
});