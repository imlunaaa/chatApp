const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendchatnotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    if (!messageData) return;

    const chatId = context.params.chatId;

    const chatDoc = await admin
      .firestore()
      .collection("chats")
      .doc(chatId)
      .get();
    if (!chatDoc.exists) return;

    const chat = chatDoc.data();
    const participants = chat.participants || [];
    const senderId = messageData.senderId;

    const receiverId = participants.find((id) => id !== senderId);
    if (!receiverId) return;

    const chatsSnapshot = await admin
      .firestore()
      .collection("chats")
      .where("participants", "array-contains", receiverId)
      .get();

    let totalUnread = 0;
    chatsSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.unreadCount && data.unreadCount[receiverId]) {
        totalUnread += data.unreadCount[receiverId];
      }
    });

    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(receiverId)
      .get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const message = {
      token: fcmToken,
      notification: {
        title: "New Message",
        body:
          messageData.type === "image"
            ? "📷 Photo"
            : messageData.text || "New message received",
      },
      data: {
        badge_count: totalUnread.toString(),
        senderId: senderId,
        receiverId: receiverId,
      },
      android: {
        notification: {
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            badge: totalUnread,
            sound: "default",
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });
