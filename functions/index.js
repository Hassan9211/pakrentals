const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
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
          fcm_token: FieldValue.delete(),
        });
      } else {
        console.error("FCM send error:", err);
      }
      return null;
    }
  }
);

/**
 * Scheduled function to check for overdue bookings daily.
 * Runs at 9:00 AM every day.
 */
exports.checkOverdueBookings = onSchedule("every day 09:00", async (event) => {
  const now = new Date();
  const todayStr = now.toISOString().split("T")[0]; // YYYY-MM-DD

  console.log(`Checking for overdue bookings on ${todayStr}...`);

  try {
    // 1. Get all active bookings
    const activeBookings = await db
      .collection("bookings")
      .where("status", "==", "active")
      .get();

    if (activeBookings.empty) {
      console.log("No active bookings found.");
      return null;
    }

    const overduePromises = [];

    for (const doc of activeBookings.docs) {
      const booking = doc.data();
      const endDate = booking.end_date; // YYYY-MM-DD

      // If endDate is before today, it's overdue
      if (endDate < todayStr) {
        console.log(`Booking ${doc.id} is overdue (ended ${endDate})`);

        const renterId = booking.renter_id;
        const hostId = booking.host_id;
        const listingId = booking.listing_id;

        // Fetch listing title
        let listingTitle = "item";
        try {
          const listingDoc = await db.collection("listings").doc(listingId).get();
          if (listingDoc.exists) {
            listingTitle = listingDoc.data()?.title || "item";
          }
        } catch (e) {
          console.error("Error fetching listing title:", e);
        }

        // Notify Renter
        overduePromises.push(
          db.collection("notifications").add({
            user_id: renterId,
            type: "overdue_warning",
            title: "⚠️ Overdue Return Warning",
            body: `Your return date for "${listingTitle}" has passed (${endDate}). Please return it immediately to avoid penalties.`,
            booking_id: doc.id,
            is_read: false,
            created_at: FieldValue.serverTimestamp(),
          })
        );

        // Notify Host
        overduePromises.push(
          db.collection("notifications").add({
            user_id: hostId,
            type: "overdue_alert",
            title: "🔔 Overdue Item Alert",
            body: `The renter has not yet returned "${listingTitle}" (due date was ${endDate}).`,
            booking_id: doc.id,
            is_read: false,
            created_at: FieldValue.serverTimestamp(),
          })
        );
      }
    }

    if (overduePromises.length > 0) {
      await Promise.all(overduePromises);
      console.log(`Sent ${overduePromises.length} overdue notifications.`);
    } else {
      console.log("No overdue bookings today.");
    }
  } catch (error) {
    console.error("Error in checkOverdueBookings:", error);
  }

  return null;
});
