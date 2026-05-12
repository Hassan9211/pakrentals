# Firebase Cloud Functions Deploy — Push Notifications

## One-time setup

```bash
# 1. Install Firebase CLI (if not installed)
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Install function dependencies
cd functions
npm install
cd ..

# 4. Deploy functions
firebase deploy --only functions
```

## What this deploys

`sendPushOnNotification` — Firestore trigger on `notifications/{notifId}`

Every time a notification document is created in Firestore, this function:
1. Reads the `user_id` from the document
2. Fetches that user's `fcm_token` from Firestore `users` collection
3. Sends a real FCM push notification to their device

## Notification events that trigger push

| Event | Who gets push |
|---|---|
| New booking request | Host + Admin |
| Booking approved | Renter |
| Booking rejected | Renter |
| Payment proof uploaded | Host + Admin |
| Item picked up | Admin |
| Item returned | Admin |

## Firestore rules needed

Make sure your Firestore rules allow the Cloud Function to read `users` collection.
Cloud Functions run with admin SDK so rules don't apply — no changes needed.

## Blaze plan required

Cloud Functions require Firebase Blaze (pay-as-you-go) plan.
Free tier: 2M function invocations/month — more than enough for this app.
