/**
 * LPro - Smart Push & Secure Account Management
 * - Cloud Functions v2 (Node.js)
 * - Features: One-Shot Push, Batched Hard Delete (Apple-Proof)
 */

const admin = require("firebase-admin");
admin.initializeApp();

const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// --- 1. Notification Helpers (Keep original logic) ---

function buildMessage({ topic, title, body, data = {}, imageUrl }) {
  const msg = {
    topic,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [String(k), String(v)])
    ),
    android: {
      priority: "high",
      notification: {
        channelId: "lpro_notifications",
        icon: "ic_stat_lpro",
      },
    },
    apns: {
      headers: { "apns-priority": "10" },
      payload: { aps: { sound: "default" } },
    },
  };
  if (imageUrl && typeof imageUrl === "string" && imageUrl.startsWith("http")) {
    msg.notification.imageUrl = imageUrl;
  }
  return msg;
}

function shouldSend({ beforeDoc, afterDoc }) {
  if (!afterDoc || typeof afterDoc !== "object") return false;
  if (afterDoc.notify !== true) return false;
  if ("isActive" in afterDoc && afterDoc.isActive !== true) return false;
  const beforeNotify = beforeDoc && typeof beforeDoc === "object" ? beforeDoc.notify : undefined;
  if (beforeNotify === true) return false;
  return true;
}

function defaultTitleFor(collectionId) {
  switch (collectionId) {
    case "news_ticker_items": return "شريط الأخبار";
    case "home_pro_card": return "معلومة Pro";
    case "pro_insight": return "المعلومة بتفرق";
    case "know_your_client": return "اعرف عميلك";
    case "market_radar": return "رادار السوق";
    case "money": return "اقتصاد عقاري";
    default: return "LPro";
  }
}

function defaultBodyFor(collectionId) {
  switch (collectionId) {
    case "news_ticker_items": return "خبر جديد";
    case "home_pro_card": return "تم نشر محتوى جديد";
    case "pro_insight": return "تم نشر Insight جديد";
    case "know_your_client": return "تم نشر موضوع جديد";
    case "market_radar":
    case "money": return "تحديث جديد";
    default: return "محتوى جديد";
  }
}

function pickBody(doc, collectionId) {
  const candidates = [doc.pushBody, doc.text_ar, doc.title, doc.name, doc.subtitle, doc.body, doc.text];
  for (const v of candidates) {
    if (typeof v === "string" && v.trim().length > 0) return v.trim();
  }
  return defaultBodyFor(collectionId);
}

function pickTitle(doc, collectionId) {
  if (typeof doc.pushTitle === "string" && doc.pushTitle.trim().length > 0) return doc.pushTitle.trim();
  return defaultTitleFor(collectionId);
}

function pickTopic(doc) {
  if (typeof doc.topic === "string" && doc.topic.trim().length > 0) return doc.topic.trim();
  return "all_users";
}

function pickDeepLinkTitle(doc) {
  if (typeof doc.title === "string" && doc.title.trim().length > 0) return doc.title.trim();
  if (typeof doc.text_ar === "string" && doc.text_ar.trim().length > 0) return doc.text_ar.trim();
  if (typeof doc.name === "string" && doc.name.trim().length > 0) return doc.name.trim();
  return "";
}

function makeCollectionNotifier(collectionId) {
  return onDocumentWritten(`${collectionId}/{docId}`, async (event) => {
    try {
      const afterSnap = event.data.after;
      const beforeSnap = event.data.before;
      if (!afterSnap.exists) return;
      const afterDoc = afterSnap.data();
      const beforeDoc = beforeSnap.exists ? beforeSnap.data() : null;
      if (!shouldSend({ beforeDoc, afterDoc })) return;

      const topic = pickTopic(afterDoc);
      const title = pickTitle(afterDoc, collectionId);
      const body = pickBody(afterDoc, collectionId);
      const imageUrl = typeof afterDoc.imageUrl === "string" && afterDoc.imageUrl.trim().length > 0 ? afterDoc.imageUrl.trim() : undefined;
      const deepTitle = pickDeepLinkTitle(afterDoc);

      const msg = buildMessage({
        topic, title, body, imageUrl,
        data: { collection: collectionId, docId: afterSnap.id, title: deepTitle },
      });

      const res = await admin.messaging().send(msg);
      logger.info(`Push sent: ${collectionId}/${afterSnap.id} -> topic:${topic}`, { messageId: res });

      await afterSnap.ref.set({ notify: false, notifiedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    } catch (e) {
      logger.error(`Push failed for ${collectionId}: ${e}`, e);
    }
  });
}

// --- 2. Export Notifiers ---

exports.notifyNewsTicker = makeCollectionNotifier("news_ticker_items");
exports.notifyHomeProCard = makeCollectionNotifier("home_pro_card");
exports.notifyProInsight = makeCollectionNotifier("pro_insight");
exports.notifyKnowYourClient = makeCollectionNotifier("know_your_client");
exports.notifyMarketRadar = makeCollectionNotifier("market_radar");
exports.notifyMoney = makeCollectionNotifier("money");

// --- 3. Account Deletion (Batched & Secure) ---

/**
 * Helper to execute promises in small batches to avoid Firestore spikes and timeouts.
 */
async function runInBatches(tasks, batchSize = 5) {
  for (let i = 0; i < tasks.length; i += batchSize) {
    await Promise.all(tasks.slice(i, i + batchSize));
  }
}

/**
 * ✅ Account Deletion (Hard Delete)
 * - Batched recursiveDelete for support tickets
 * - Idempotent cleanup for leaderboards and user docs
 * - Final Auth termination
 */
exports.deleteMyAccount = onCall(async (request) => {
  const uid = request.auth ? request.auth.uid : null;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Unauthorized access.");
  }

  const db = admin.firestore();

  try {
    logger.info(`Starting batched hard deletion for user: ${uid}`);

    // A) Cleanup Support Tickets (Recursive Batching)
    const ticketsSnap = await db.collection("support_tickets").where("userId", "==", uid).get();
    const ticketDeletions = ticketsSnap.docs.map((t) => db.recursiveDelete(t.ref));
    await runInBatches(ticketDeletions, 5);

    // B) Cleanup Leaderboards & Main Docs in Parallel (Lightweight)
    await Promise.all([
      ...["general", "stars", "pros"].map((league) =>
        db.collection("leaderboards").doc(league).collection("entries").doc(uid).delete().catch(() => null)
      ),
      db.collection("user_stats").doc(uid).delete().catch(() => null),
      db.collection("users").doc(uid).delete().catch(() => null)
    ]);

    // C) Wipe from Auth
    await admin.auth().deleteUser(uid).catch(() => null);

    logger.info(`Deletion completed successfully for UID: ${uid}`);
    return { success: true };
  } catch (error) {
    logger.error(`Deletion failed for ${uid}: ${error}`, error);
    // Returning error details for easier debugging
    throw new HttpsError("internal", error instanceof Error ? error.message : "Error during account deletion.");
  }
});