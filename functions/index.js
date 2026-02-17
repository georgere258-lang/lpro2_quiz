/**
 * LPro - Smart Push (Minimal, Safe, Controlled)
 * - Sends push ONLY when doc.notify == true (ONE-SHOT)
 * - Works for BOTH Create + Update (so fixed-slot docs like radar/money/pro_card work)
 * - Auto-resets notify=false after sending (prevents spam)
 * - Default topic: all_users (or doc.topic if provided)
 * - Provides data payload for deep-linking: collection + docId + title
 */

const admin = require("firebase-admin");
admin.initializeApp();

const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

/**
 * Build a clean FCM message payload.
 * - "notification" => system UI notification (Android/iOS)
 * - "data" => deep-link routing in app
 */
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
        icon: "ic_stat_lpro", // android/app/src/main/res/drawable/ic_stat_lpro.png
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

/**
 * Decide whether we should send (ONE-SHOT):
 * - after.notify must be true
 * - if isActive exists, must be true
 * - and (before.notify !== true) so it doesn't resend on same state
 */
function shouldSend({ beforeDoc, afterDoc }) {
  if (!afterDoc || typeof afterDoc !== "object") return false;

  if (afterDoc.notify !== true) return false;

  if ("isActive" in afterDoc && afterDoc.isActive !== true) return false;

  // One-shot: only when notify becomes true (or doc newly created with notify=true)
  const beforeNotify = beforeDoc && typeof beforeDoc === "object" ? beforeDoc.notify : undefined;
  if (beforeNotify === true) return false;

  return true;
}

/**
 * Arabic titles per collection (as you want)
 * App name itself will appear as "LPro" automatically by OS.
 */
function defaultTitleFor(collectionId) {
  switch (collectionId) {
    case "news_ticker_items":
      return "شريط الأخبار";
    case "home_pro_card":
      return "معلومة Pro";
    case "pro_insight":
      return "المعلومة بتفرق";
    case "know_your_client":
      return "اعرف عميلك";
    case "market_radar":
      return "رادار السوق";
    case "money":
      return "اقتصاد عقاري";
    default:
      return "LPro";
  }
}

function defaultBodyFor(collectionId) {
  switch (collectionId) {
    case "news_ticker_items":
      return "خبر جديد";
    case "home_pro_card":
      return "تم نشر محتوى جديد";
    case "pro_insight":
      return "تم نشر Insight جديد";
    case "know_your_client":
      return "تم نشر موضوع جديد";
    case "market_radar":
    case "money":
      return "تحديث جديد";
    default:
      return "محتوى جديد";
  }
}

function pickBody(doc, collectionId) {
  const candidates = [
    doc.pushBody,
    doc.text_ar,
    doc.title,
    doc.name,
    doc.subtitle,
    doc.body, // radar/money
    doc.text, // pro_card text sometimes
  ];

  for (const v of candidates) {
    if (typeof v === "string" && v.trim().length > 0) return v.trim();
  }

  return defaultBodyFor(collectionId);
}

function pickTitle(doc, collectionId) {
  if (typeof doc.pushTitle === "string" && doc.pushTitle.trim().length > 0) {
    return doc.pushTitle.trim();
  }
  return defaultTitleFor(collectionId);
}

function pickTopic(doc) {
  if (typeof doc.topic === "string" && doc.topic.trim().length > 0) {
    return doc.topic.trim();
  }
  return "all_users";
}

function pickDeepLinkTitle(doc) {
  if (typeof doc.title === "string" && doc.title.trim().length > 0) {
    return doc.title.trim();
  }
  if (typeof doc.text_ar === "string" && doc.text_ar.trim().length > 0) {
    return doc.text_ar.trim();
  }
  if (typeof doc.name === "string" && doc.name.trim().length > 0) {
    return doc.name.trim();
  }
  return "";
}

/**
 * Generic notifier factory (WRITE trigger):
 * - Works for Create + Update
 * - Sends only when notify toggles to true
 * - Resets notify=false after success (ONE-SHOT)
 */
function makeCollectionNotifier(collectionId) {
  return onDocumentWritten(`${collectionId}/{docId}`, async (event) => {
    try {
      const afterSnap = event.data.after;
      const beforeSnap = event.data.before;

      if (!afterSnap.exists) return; // deleted

      const afterDoc = afterSnap.data();
      const beforeDoc = beforeSnap.exists ? beforeSnap.data() : null;

      if (!shouldSend({ beforeDoc, afterDoc })) return;

      const topic = pickTopic(afterDoc);
      const title = pickTitle(afterDoc, collectionId);
      const body = pickBody(afterDoc, collectionId);

      const imageUrl =
        typeof afterDoc.imageUrl === "string" && afterDoc.imageUrl.trim().length > 0
          ? afterDoc.imageUrl.trim()
          : undefined;

      const deepTitle = pickDeepLinkTitle(afterDoc);

      const msg = buildMessage({
        topic,
        title,
        body,
        imageUrl,
        data: {
          collection: collectionId,
          docId: afterSnap.id,
          title: deepTitle, // for your current constructors (title-only)
        },
      });

      const res = await admin.messaging().send(msg);
      logger.info(`Push sent: ${collectionId}/${afterSnap.id} -> topic:${topic}`, {
        messageId: res,
      });

      // ✅ ONE-SHOT reset to prevent spam
      await afterSnap.ref.set(
        {
          notify: false,
          notifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    } catch (e) {
      logger.error(`Push failed for ${collectionId}: ${e}`, e);
    }
  });
}

// ✅ Collections (based on your Firestore Rules)
exports.notifyNewsTicker = makeCollectionNotifier("news_ticker_items");
exports.notifyHomeProCard = makeCollectionNotifier("home_pro_card");
exports.notifyProInsight = makeCollectionNotifier("pro_insight");
exports.notifyKnowYourClient = makeCollectionNotifier("know_your_client");
exports.notifyMarketRadar = makeCollectionNotifier("market_radar");
exports.notifyMoney = makeCollectionNotifier("money");