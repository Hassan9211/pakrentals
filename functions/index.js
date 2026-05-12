const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

/**
 * Triggered whenever a new document is added to the `notifications` collection.
 * Looks up the target user's FCM token and sends a push notification.
 */
exports.sendPushOnNotification = onDocumentCreated(
  "notifications/{notifId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return null;

    const userId = data.user_id;
    const title = data.title || "PakRentals";
    const body = data.body || "";
    const type = data.type || "general";
    const bookingId = data.booking_id || null;

    if (!userId) {
      console.log("No user_id in notification doc, skipping push.");
      return null;
    }

    // Fetch user's FCM token from Firestore
    let token;
    try {
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.log(`User ${userId} not found, skipping push.`);
        return null;
      }
      token = userDoc.data()?.fcm_token;
    } catch (err) {
      console.error("Error fetching user FCM token:", err);
      return null;
    }

    if (!token) {
      console.log(`No FCM token for user ${userId}, skipping push.`);
      return null;
    }

    // Build FCM message
    const message = {
      token,
      notification: {
        title,
        body,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "pakrentals_high",
          sound: "default",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      data: {
        type,
        ...(bookingId ? { booking_id: bookingId.toString() } : {}),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      const response = await getMessaging().send(message);
      console.log(`Push sent to ${userId}: ${response}`);
      return response;
    } catch (err) {
      // Token might be stale — remove it from Firestore
      if (
        err.code === "messaging/registration-token-not-registered" ||
        err.code === "messaging/invalid-registration-token"
      ) {
        console.log(`Stale token for ${userId}, removing from Firestore.`);
        await db.collection("users").doc(userId).update({
          fcm_token: getFirestore.FieldValue?.delete() || null,
        });
      } else {
        console.error("FCM send error:", err);
      }
      return null;
    }
  }
);
