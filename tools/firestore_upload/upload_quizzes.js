/**
 * PATH: tools/firestore_upload/upload_quizzes.js
 * PURPOSE: Upload quizzes JSON -> Firestore (no require-cache issues)
 *
 * RUN:
 *   node upload_quizzes.js questions_stars_level1.json "دوري النجوم"
 *
 * EXAMPLES:
 *   node upload_quizzes.js questions_stars_level1.json "دوري النجوم"
 *   node upload_quizzes.js questions_pro_level1.json "دوري المحترفين"
 */

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

function die(msg) {
  console.error("❌ " + msg);
  process.exit(1);
}

// -------- Args --------
const jsonFile = process.argv[2];
const category = process.argv[3];

if (!jsonFile) die("Please provide JSON file name. Example: questions_stars_level1.json");
if (!category) die('Please provide category. Example: "دوري النجوم"');

const here = __dirname;
const jsonPath = path.join(here, jsonFile);
const serviceAccountPath = path.join(here, "serviceAccountKey.json");

if (!fs.existsSync(serviceAccountPath)) {
  die("serviceAccountKey.json not found in tools/firestore_upload/");
}
if (!fs.existsSync(jsonPath)) {
  die(`JSON file not found: ${jsonPath}`);
}

// -------- Firebase Admin Init --------
if (!admin.apps.length) {
  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// -------- Load JSON (NO CACHE) --------
let questions;
try {
  const raw = fs.readFileSync(jsonPath, "utf8");
  questions = JSON.parse(raw);
} catch (e) {
  die("Failed to read/parse JSON file. Make sure it's valid JSON.");
}

if (!Array.isArray(questions)) {
  die("JSON root must be an ARRAY of questions. Example: [ {..}, {..} ]");
}

console.log(`📥 Loading ${questions.length} questions from ${jsonFile}`);
console.log(`📤 Uploading into Firestore collection: quizzes`);
console.log(`🏷️ Category: ${category}`);

const collectionName = "quizzes";
const batchLimit = 450; // safe under 500

(async () => {
  try {
    let batch = db.batch();
    let countInBatch = 0;
    let total = 0;

    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];

      // Minimal validation
      if (!q.question || !Array.isArray(q.options) || typeof q.correctAnswer !== "number") {
        die(
          `Invalid question at index ${i}. Required keys: question (string), options (array), correctAnswer (number)`
        );
      }

      const docRef = db.collection(collectionName).doc();
      batch.set(docRef, {
        category: category,
        question: String(q.question),
        options: q.options.map(String),
        correctAnswer: Number(q.correctAnswer),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        // optional meta if exists
        ...(q.level ? { level: q.level } : {}),
        ...(q.difficulty ? { difficulty: q.difficulty } : {}),
        ...(q.topic ? { topic: q.topic } : {}),
      });

      countInBatch++;
      total++;

      if (countInBatch >= batchLimit) {
        await batch.commit();
        console.log(`✅ Committed batch: ${total}/${questions.length}`);
        batch = db.batch();
        countInBatch = 0;
      }
    }

    if (countInBatch > 0) {
      await batch.commit();
      console.log(`✅ Committed final batch: ${total}/${questions.length}`);
    }

    console.log("🎉 Upload done.");
    process.exit(0);
  } catch (e) {
    console.error("❌ Upload failed:", e);
    process.exit(1);
  }
})();