const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggers when a user document is updated. It manages a corresponding
 * 'barbers' document based on the user's 'role' field.
 * This function uses the V2 SDK.
 */
exports.onUserRoleChange = onDocumentUpdated(
    "users/{userId}",
    async (event) => {
      // The event.data object contains the before and after data.
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      const userId = event.params.userId;

      // Exit if the role field has not changed.
      if (beforeData.role === afterData.role) {
        logger.log(
            `Role for user ${userId} has not changed. Exiting.`,
        );
        return null;
      }

      // --- PROMOTION LOGIC: User is promoted TO a barber ---
      if (afterData.role === "barber") {
        logger.log(
            `User ${userId} promoted to 'barber'. Creating barber profile.`,
        );

        const barberDocRef = admin.firestore()
            .collection("barbers")
            .doc(userId);

        // Create the new barber document, pulling the name and email
        // directly from the user's document.
        return barberDocRef.set({
          fullName: afterData.username || "",
          email: afterData.email || "",
          bio: "Welcome! Please update your professional bio.",
          services: [],
          rating: 0.0,
          totalRatings: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // --- DEMOTION LOGIC: User is demoted FROM a barber ---
      if (beforeData.role === "barber" && afterData.role !== "barber") {
        logger.log(
            `User ${userId} demoted from 'barber'. Deleting barber profile.`,
        );

        const barberDocRef = admin.firestore()
            .collection("barbers")
            .doc(userId);
        return barberDocRef.delete();
      }

      // If the role change was not to or from 'barber', do nothing.
      return null;
    });
