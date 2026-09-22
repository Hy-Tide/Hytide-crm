// functions/index.js
/**
 * Hytide CRM Follow-up Reminders & Push Notification Processor
 * Runs every 1 minute to check due follow-ups and dispatch FCM + in-app notifications.
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Scheduled Cloud Function running every 1 minute.
 * Query strategy:
 *   - reminderEnabled == true
 *   - reminderSent == false
 *   - status == "pending"
 *   - reminderAt <= now
 */
exports.checkFollowUpReminders = onSchedule("every 1 minutes", async (event) => {
  const now = admin.firestore.Timestamp.now();
  console.log(`[Reminders] Checking due follow-up reminders at ${new Date().toISOString()}...`);

  try {
    const querySnap = await db
      .collection("followUps")
      .where("reminderEnabled", "==", true)
      .where("reminderSent", "==", false)
      .where("status", "==", "pending")
      .where("reminderAt", "<=", now)
      .limit(50)
      .get();

    if (querySnap.empty) {
      console.log("[Reminders] No due reminders found.");
      return;
    }

    console.log(`[Reminders] Found ${querySnap.docs.length} follow-up reminders due.`);

    for (const doc of querySnap.docs) {
      const followUpId = doc.id;
      const followUp = doc.data();

      // Idempotent execution using transaction
      const shouldSend = await db.runTransaction(async (transaction) => {
        const freshDoc = await transaction.get(doc.reference);
        if (!freshDoc.exists) return false;
        const freshData = freshDoc.data();
        if (freshData.reminderSent === true || freshData.status !== "pending") {
          return false;
        }

        // Mark reminder as sent atomically to avoid duplicate sends
        transaction.update(doc.reference, {
          reminderSent: true,
          reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return true;
      });

      if (!shouldSend) {
        console.log(`[Reminders] Follow-up ${followUpId} was already processed or cancelled.`);
        continue;
      }

      const assignedTo = followUp.assignedTo;
      const title = "Follow-up Reminder";
      const scheduledTimeStr = followUp.scheduledAt
        ? new Date(followUp.scheduledAt.toDate()).toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
          })
        : "";
      const body = `${followUp.companyName || followUp.leadName || "Lead"}: ${followUp.title || "Sales activity scheduled"} at ${scheduledTimeStr}`;

      // 1. Create In-App Notification document in notifications/{id}
      try {
        await db.collection("notifications").add({
          userId: assignedTo,
          type: "follow_up_reminder",
          title: title,
          body: body,
          followUpId: followUpId,
          leadId: followUp.leadId || "",
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (err) {
        console.error(`[Reminders] Failed to create in-app notification for ${followUpId}:`, err);
      }

      // 2. Log activity to lead timeline (leads/{leadId}/activities)
      if (followUp.leadId) {
        try {
          await db
            .collection("leads")
            .doc(followUp.leadId)
            .collection("activities")
            .add({
              type: "followup_reminder_sent",
              title: "Follow-up reminder sent",
              description: `Automated push reminder dispatched for "${followUp.title}"`,
              createdBy: "system",
              createdByName: "Hytide System",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              metadata: {
                followUpId: followUpId,
                assignedTo: assignedTo,
              },
            });
        } catch (err) {
          console.error(`[Reminders] Failed to log activity for lead ${followUp.leadId}:`, err);
        }
      }

      // 3. Dispatch FCM Push Notifications to active devices in users/{assignedTo}/devices
      if (assignedTo) {
        try {
          const devicesSnap = await db
            .collection("users")
            .doc(assignedTo)
            .collection("devices")
            .where("isActive", "==", true)
            .get();

          if (devicesSnap.empty) {
            console.log(`[Reminders] No active devices found for user ${assignedTo}.`);
            continue;
          }

          const tokens = [];
          const tokenDocRefs = [];

          for (const dDoc of devicesSnap.docs) {
            const token = dDoc.data().fcmToken;
            if (token) {
              tokens.push(token);
              tokenDocRefs.push(dDoc.reference);
            }
          }

          if (tokens.length > 0) {
            const response = await admin.messaging().sendEachForMulticast({
              tokens: tokens,
              notification: {
                title: title,
                body: body,
              },
              data: {
                followUpId: followUpId,
                leadId: followUp.leadId || "",
                type: "follow_up_reminder",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
              android: {
                priority: "high",
                notification: {
                  channelId: "hytide_crm_channel",
                  priority: "high",
                  defaultSound: true,
                },
              },
            });

            console.log(
              `[Reminders] Sent push for ${followUpId}: ${response.successCount} success, ${response.failureCount} failed.`
            );

            // Clean up inactive/invalid tokens
            if (response.failureCount > 0) {
              const batch = db.batch();
              response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                  const errCode = resp.error ? resp.error.code : "";
                  if (
                    errCode === "messaging/registration-token-not-registered" ||
                    errCode === "messaging/invalid-registration-token" ||
                    errCode === "messaging/invalid-argument"
                  ) {
                    batch.update(tokenDocRefs[idx], {
                      isActive: false,
                      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                  }
                }
              });
              await batch.commit();
            }
          }
        } catch (fcmErr) {
          console.error(`[Reminders] Error dispatching FCM for ${followUpId}:`, fcmErr);
        }
      }
    }
  } catch (error) {
    console.error("[Reminders] Error checking follow-up reminders:", error);
  }
});
