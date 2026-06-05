import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vigenesia/models/chat_model.dart';
import 'package:vigenesia/models/friend_request_model.dart';
import 'package:vigenesia/models/friendship_model.dart';
import 'package:vigenesia/models/message_model.dart';
import 'package:vigenesia/models/motivation_model.dart';
import 'package:vigenesia/models/notification_model.dart';
import 'package:vigenesia/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Gagal Membuat Akun: ${e.toString()}');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal Mendapatkan Akun: ${e.toString()}');
    }
  }

  Future<UserModel?> updateUserOnlineStatus(
    String userId,
    bool isOnline,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'isOnline': isOnline,
          'lastSeen': DateTime.now(),
        });
      }
    } catch (e) {
      throw Exception('Gagal Update Status Online Akun: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Gagal Hapus Akun: ${e.toString()}');
    }
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Gagal Memperbarui Pengguna');
    }
  }

  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // friend request collection

  Future<void> sendFriendRequest(FriendRequestModel request) async {
    try {
      await _firestore
          .collection('friend_requests')
          .doc(request.id)
          .set(request.toMap());

      String notificationId =
          'friend_request_${request.senderId}_${request.receiverId}_&${DateTime.now().millisecondsSinceEpoch}';

      await createNotification(
        NotificationModel(
          id: notificationId,
          userId: request.receiverId,
          tittle: 'Permintaan Pertemanan Baru',
          body: 'Anda telah menerima permintaan pertemanan baru',
          type: NotificationType.friendRequest,
          data: {'senderId': request.senderId, 'requestId': request.id},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Gagal Mengirim Permintaan Pertemanan: ${e.toString()}');
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      DocumentSnapshot requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();
      if (requestDoc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );
        await _firestore.collection('friend_requests').doc(requestId).delete();

        await deleteNotificationsByTypeAndUser(
          request.receiverId,
          NotificationType.friendRequest,
          request.senderId,
        );
      }
    } catch (e) {
      throw Exception(
        'Gagal Membatalkan Permintaan Pertemanan: ${e.toString()}',
      );
    }
  }

  Future<void> respondToFriendRequest(
    String requestId,
    FriendRequestStatus status,
  ) async {
    try {
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': status.name,
        'respondedAt': DateTime.now().microsecondsSinceEpoch,
      });

      DocumentSnapshot requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();

      if (requestDoc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );

        if (status == FriendRequestStatus.accepted) {
          await createFriendShip(request.senderId, request.receiverId);

          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              tittle: 'Permintaan Pertemanan Diterima',
              body: 'Permintaan pertemanan Anda telah diterima',
              type: NotificationType.friendRequestAccepted,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );

          await _removeNotificationForCancelledReques(
            request.receiverId,
            request.senderId,
          );
        } else if (status == FriendRequestStatus.declined) {
          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              tittle: 'Permintaan Pertemanan Ditolak',
              body: 'Permintaan pertemanan Anda telah ditolak',
              type: NotificationType.friendRequestDeclined,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );

          await _removeNotificationForCancelledReques(
            request.receiverId,
            request.senderId,
          );
        }
      }
    } catch (e) {
      throw Exception(
        'Gagal Menanggapi Permintaan Pertemanan: ${e.toString()}',
      );
    }
  }

  Stream<List<FriendRequestModel>> getFriendRequestsStream(String userId) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // ✅ FIX: ganti 'friendRequests' → 'friend_requests'
  Stream<List<FriendRequestModel>> getSendFriendRequestsStream(String userId) {
    return _firestore
        .collection('friend_requests') // ← DIPERBAIKI
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // ✅ BARU: one-time fetch untuk cek status awal
  Future<FriendRequestModel?> getPendingRequest(
    String senderId,
    String receiverId,
  ) async {
    try {
      final query = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return FriendRequestModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<FriendRequestModel?> getFriendRequest(
    String senderId,
    String receiverId,
  ) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('FriendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (query.docs.isNotEmpty) {
        return FriendRequestModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Gagal menerima permintaan pertemanan: ${e.toString()}');
    }
  }

  // friendships collections
  Future<void> createFriendShip(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      FriendshipModel friendShip = FriendshipModel(
        id: friendShipId,
        user1Id: userIds[0],
        user2Id: userIds[1],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .set(friendShip.toMap());
    } catch (e) {
      throw Exception('Gagal menjalin persahabatan: ${e.toString()}');
    }
  }

  Future<void> removeFriendShip(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      await _firestore.collection('friendships').doc(friendShipId).delete();

      await createNotification(
        NotificationModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          userId: user2Id,
          tittle: 'Friend Removed',
          body: 'Yp are no longer friends',
          type: NotificationType.friendRemoved,
          data: {'userId': user1Id},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Gagal menghapus pertemanan: ${e.toString()}');
    }
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      List<String> userIds = [blockerId, blockedId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      await _firestore.collection('friendships').doc(friendShipId).update({
        'isBlocked': true,
        'blockedBy': blockerId,
      });
    } catch (e) {
      throw Exception('Gagal memblokir pengguna: ${e.toString()}');
    }
  }

  Future<void> unblockUser(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      await _firestore.collection('friendships').doc(friendShipId).update({
        'isBlocked': false,
        'blockedBy': null,
      });
    } catch (e) {
      throw Exception('Gagal membuka kunci pengguna: ${e.toString()}');
    }
  }

  Stream<List<FriendshipModel>> getFriendsStream(String userId) {
    return _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot1) async {
          QuerySnapshot snapshot2 = await _firestore
              .collection('friendships')
              .where('user2Id', isEqualTo: userId)
              .get();

          List<FriendshipModel> friendships = [];

          for (var doc in snapshot1.docs) {
            friendships.add(
              FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
            );
          }

          for (var doc in snapshot2.docs) {
            friendships.add(
              FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
            );
          }
          return friendships.where((f) => !f.isBlocked).toList();
        });
  }

  Future<FriendshipModel?> getFriendships(
    String user1Id,
    String user2Id,
  ) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      if (doc.exists) {
        return FriendshipModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Gagal menjalin persahabatan: ${e.toString()}');
    }
  }

  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      if (doc.exists) {
        FriendshipModel friendship = FriendshipModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        return friendship.isBlocked;
      }
      return false;
    } catch (e) {
      throw Exception(
        'Gagal memeriksa apakah pengguna telah diblokir: ${e.toString()}',
      );
    }
  }

  Future<bool> isUnfriended(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_ ${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      return !doc.exists || (doc.exists && doc.data() == null);
    } catch (e) {
      throw Exception(
        'Gagal memeriksa apakah pengguna telah diblokir: ${e.toString()}',
      );
    }
  }

  // chats collection
  Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      List<String> participants = [userId1, userId2];
      participants.sort();

      String chatId = '${participants[0]}_${participants[1]}';

      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      DocumentSnapshot chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        ChatModel newChat = ChatModel(
          id: chatId,
          participants: participants,
          unreadCount: {userId1: 0, userId2: 0},
          deleteBy: {userId1: false, userId2: false},
          deletedAt: {userId1: null, userId2: null},
          lastSeenBy: {userId1: DateTime.now(), userId2: DateTime.now()},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await chatRef.set(newChat.toMap());
      } else {
        ChatModel existingChat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );
        if (existingChat.isDeletedBy(userId1)) {
          await restoreChatForUser(chatId, userId1);
        }
        if (existingChat.isDeletedBy(userId2)) {
          await restoreChatForUser(chatId, userId2);
        }
      }
      return chatId;
    } catch (e) {
      throw Exception('Gagal membuat atau mengakses obrolan: ${e.toString()}');
    }
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .where((chat) => !chat.isDeletedBy(userId))
              .toList(),
        );
  }

  Future<void> updateChatLastMessage(
    String chatId,
    MessageModel message,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastMessageSenderId': message.senderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception(
        'Gagal memperbarui pesan terakhir di obrolan: ${e.toString()}',
      );
    }
  }

  Future<void> updateUserLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenBy.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception(
        'Gagal memperbarui status “Terakhir Dilihat”: ${e.toString()}',
      );
    }
  }

  Future<void> deleteChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenBy.$userId': true,
        'deletedAt.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Gagal menghapus obrolan: ${e.toString()}');
    }
  }

  Future<void> restoreChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': false,
      });
    } catch (e) {
      throw Exception('Gagal memulihkan obrolan: ${e.toString()}');
    }
  }

  Future<void> updateUnreadCount(
    String chatId,
    String userId,
    int count,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': count,
      });
    } catch (e) {
      throw Exception(
        'Gagal memperbarui jumlah pesan yang belum dibaca: ${e.toString()}',
      );
    }
  }

  Future<void> restoreUnreadCount(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw Exception(
        'Gagal memperbarui jumlah pesan yang belum dibaca: ${e.toString()}',
      );
    }
  }

  // Messages Collection

  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      String chatId = await createOrGetChat(
        message.senderId,
        message.receiverId,
      );

      await updateChatLastMessage(chatId, message);

      await updateUserLastSeen(chatId, message.senderId);

      DocumentSnapshot chatDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        ChatModel chat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );

        int currentUnread = chat.getUnreadCount(message.receiverId);

        await updateUnreadCount(chatId, message.receiverId, currentUnread + 1);
      }
    } catch (e) {
      throw Exception('Gagal mengirim pesan: ${e.toString()}');
    }
  }

  Stream<List<MessageModel>> getMessageStream(String userId1, String userId2) {
    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [userId1, userId2])
        .snapshots()
        .asyncMap((snapshot) async {
          List<String> participants = [userId1, userId2];
          participants.sort();
          String chatId = '${participants[0]}_ ${participants[1]}';

          DocumentSnapshot chatDoc = await _firestore
              .collection('chats')
              .doc(chatId)
              .get();

          ChatModel? chat;
          if (chatDoc.exists) {
            chat = ChatModel.fromMap(chatDoc.data() as Map<String, dynamic>);
          }

          List<MessageModel> messages = [];
          for (var doc in snapshot.docs) {
            MessageModel message = MessageModel.fromMap(doc.data());
            if ((message.senderId == userId1 &&
                    message.receiverId == userId2) ||
                (message.senderId == userId2 &&
                    message.receiverId == userId1)) {
              bool includeMessage = true;

              if (chat != null) {
                DateTime? currentUserDeletedAt = chat.getDeletedAt(userId1);
                if (currentUserDeletedAt != null &&
                    message.timestamp.isBefore(currentUserDeletedAt)) {
                  includeMessage = false;
                }
              }

              if (includeMessage) {
                messages.add(message);
              }
            }
          }
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  Future<void> markmessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception(
        'Gagal menandai pesan sebagai sudah dibaca: ${e.toString()}',
      );
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus pesan: ${e.toString()}');
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now().microsecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Gagal mengedit pesan: ${e.toString()}');
    }
  }

  //Notifications collection

  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Gagal membuat pemberitahuan: ${e.toString()}');
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationid) async {
    try {
      await _firestore.collection('notifications').doc(notificationid).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception(
        'Gagal menandai pemberitahuan sebagai sudah dibaca: ${e.toString()}',
      );
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception(
        'Gagal menandai semua pemberitahuan sebagai sudah dibaca: ${e.toString()}',
      );
    }
  }

  Future<void> deleteNotification(String notificationid) async {
    try {
      await _firestore.collection('notifications').doc(notificationid).delete();
    } catch (e) {
      throw Exception('Pemberitahuan gagal dihapus: ${e.toString()}');
    }
  }

  Future<void> deleteNotificationsByTypeAndUser(
    String userId,
    NotificationType type,
    String relatedUserId,
  ) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userid', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in notifications.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['data'] != null &&
            (data['data']['senderId'] == relatedUserId ||
                data['data']['userId'] == relatedUserId)) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      // throw Exception('Pemberitahuan gagal dihapus: ${e.toString()}');
      print('Kesalahan saat menghapus pemberitahuan: $e');
    }
  }

  Future<void> _removeNotificationForCancelledReques(
    String receiverId,
    String senderId,
  ) async {
    try {
      await deleteNotificationsByTypeAndUser(
        receiverId,
        NotificationType.friendRequest,
        senderId,
      );
    } catch (e) {
      print(
        'Kesalahan saat menghapus pemberitahuan untuk permintaan yang dibatalkan: $e',
      );
    }
  }

  // Tambahkan method ini ke FirestoreService
  Future<int> getUserPostsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('motivations')
          .where('user_id', isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getUserLikesCount(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['likes_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<MotivationModel>> getUserPosts(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('motivations')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => MotivationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

Future<void> createMotivation(MotivationModel motivation) async {
  try {
    final docRef = _firestore.collection('motivations').doc();

    final motivationWithId = motivation.copyWith(
      id: docRef.id,
    );

    await docRef.set(motivationWithId.toJson());
  } catch (e) {
    throw Exception('Gagal membuat motivasi: ${e.toString()}');
  }
}

Stream<List<MotivationModel>> getMotivationsStream() {
  return _firestore
      .collection('motivations')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => MotivationModel.fromJson(doc.data()))
            .toList(),
      );
}
}
