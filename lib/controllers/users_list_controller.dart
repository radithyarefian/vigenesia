import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vigenesia/controllers/auth_controller.dart';
import 'package:vigenesia/models/friend_request_model.dart';
import 'package:vigenesia/models/friendship_model.dart';
import 'package:vigenesia/models/user_model.dart';
import 'package:vigenesia/routes/app_routes.dart';
import 'package:vigenesia/services/firestore_service.dart';

enum UserRelationshipStatus {
  none,
  friendRequestSent,
  friendRequestReceived,
  friends,
  blocked,
}

class UsersListController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = Uuid();

  final RxList<UserModel> _users = <UserModel>[].obs;
  final RxList<UserModel> _filteredUsers = <UserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _error = ''.obs;

  final RxMap<String, UserRelationshipStatus> _userRelationships =
      <String, UserRelationshipStatus>{}.obs;
  final RxList<FriendRequestModel> _sendrequests = <FriendRequestModel>[].obs;
  final RxList<FriendRequestModel> _receivedRequests =
      <FriendRequestModel>[].obs;

  final RxList<FriendshipModel> _Friendships = <FriendshipModel>[].obs;

  List<UserModel> get users => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading.value;
  String get seacrhQuery => _searchQuery.value;
  String get Error => _error.value;
  Map<String, UserRelationshipStatus> get userRelationships =>
      _userRelationships;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
    _loadRelationships();

    debounce(
      _searchQuery,
      (_) => _filterUsers(),
      time: Duration(milliseconds: 300),
    );
  }

  void _loadUsers() async {
    _users.bindStream(_firestoreService.getAllUsersStream());

    ever(_users, (List<UserModel> userList) {
      final currentUserId = _authController.user?.uid;
      final otherUsers = userList
          .where((user) => user.id != currentUserId)
          .toList();

      if (_searchQuery.isEmpty) {
        _filteredUsers.value = otherUsers;
      } else {
        _filterUsers();
      }
    });
  }

  void _loadRelationships() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      //load sent friend requests
      _sendrequests.bindStream(
        _firestoreService.getSendFriendRequestsStream(currentUserId),
      );

      //load received friend requests
      _receivedRequests.bindStream(
        _firestoreService.getFriendRequestsStream(currentUserId),
      );

      //load friends/friendships
      _Friendships.bindStream(
        _firestoreService.getFriendsStream(currentUserId),
      );

      //update realtionship status whenever any of the lists change
      ever(_sendrequests, (_) => _updateAllRelationshipsStatus());
      ever(_receivedRequests, (_) => _updateAllRelationshipsStatus());
      ever(_Friendships, (_) => _updateAllRelationshipsStatus());

      ever(_users, (_) => _updateAllRelationshipsStatus());
    }
  }

  void _updateAllRelationshipsStatus() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId == null) return;

    for (var user in _users) {
      if (user.id != currentUserId) {
        final status = _calculateUserRelationshipStatus(user.id);
        _userRelationships[user.id] = status;
      }
    }
  }

  UserRelationshipStatus _calculateUserRelationshipStatus(String userId) {
    final currentUserId = _authController.user?.uid;

    if (currentUserId == null) return UserRelationshipStatus.none;

    //check if they are friends
    final friendship = _Friendships.firstWhereOrNull(
      (f) =>
          (f.user1Id == currentUserId && f.user2Id == userId) ||
          (f.user1Id == userId && f.user2Id == currentUserId),
    );

    if (friendship != null) {
      if (friendship.isBlocked) {
        return UserRelationshipStatus.blocked;
      } else {
        return UserRelationshipStatus.friends;
      }
    }

    final sentRequest = _sendrequests.firstWhereOrNull(
      (r) => r.receiverId == userId && r.status == FriendRequestStatus.pending,
    );

    if (sentRequest != null) {
      return UserRelationshipStatus.friendRequestSent;
    }

    // check if there is a pending friend request from the user
    final receivedRequest = _receivedRequests.firstWhereOrNull(
      (r) => r.senderId == userId && r.status == FriendRequestStatus.pending,
    );

    if (receivedRequest != null) {
      return UserRelationshipStatus.friendRequestReceived;
    }
    return UserRelationshipStatus.none;
  }

  UserRelationshipStatus getUserRelationshipStatus(String userId) {
    return _userRelationships[userId] ?? UserRelationshipStatus.none;
  }

  void _filterUsers() {
    final currentUserId = _authController.user?.uid;
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      _filteredUsers.value = _users
          .where((user) => user.id != currentUserId)
          .toList();
    } else {
      _filteredUsers.value = _users.where((User) {
        return User.id != currentUserId &&
            (User.displayName.toLowerCase().contains(query) ||
                User.email.toLowerCase().contains(query));
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
  _searchQuery.value = query;
}

  void clearSearch() {
    _searchQuery.value = '';
  }

  Future<void> sendFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = FriendRequestModel(
          id: _uuid.v4(),
          senderId: currentUserId,
          receiverId: user.id,
          createdAt: DateTime.now(),
        );

        _userRelationships[user.id] = UserRelationshipStatus.friendRequestSent;
        await _firestoreService.sendFriendRequest(request);
        Get.snackbar(
          'Berhasil',
          "Permintaan pertemanan telah dikirim ke ${user.displayName}",
        );
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationshipStatus.none;
      _error.value = e.toString();
      print("Terjadi kesalahan saat mengirim permintaan pertemanan $e");
      Get.snackbar('kesalahan', "Gagal mengirim permintaan pertemanan");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> cancelFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _sendrequests.firstWhereOrNull(
          (r) =>
              r.receiverId == user.id &&
              r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          _userRelationships[user.id] = UserRelationshipStatus.none;
          await _firestoreService.cancelFriendRequest(request.id);

          Get.snackbar('Berhasil', 'Permintaan Pertemanan Dibatalkan');
        }
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationshipStatus.friendRequestSent;
      _error.value = e.toString();
      print("Terjadi kesalahan saat mengirim permintaan pertemanan $e");
      Get.snackbar('Kesalahan', "gagal mengirim permintaan pertemanan");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> acceptFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _sendrequests.firstWhereOrNull(
          (r) =>
              r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          _userRelationships[user.id] = UserRelationshipStatus.friends;

          await _firestoreService.respondToFriendRequest(
            request.id,
            FriendRequestStatus.accepted,
          );

          Get.snackbar('Berhasil', 'Permintaan pertemanan diterima');
        }
      }
    } catch (e) {
      _userRelationships[user.id] =
          UserRelationshipStatus.friendRequestReceived;
      _error.value = e.toString();
      print("Terjadi kesalahan saat menerima permintaan pertemanan $e");
      Get.snackbar('Kesalahan', "gagal menerima permintaan pertemanan");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> declineFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _sendrequests.firstWhereOrNull(
          (r) =>
              r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          _userRelationships[user.id] = UserRelationshipStatus.none;

          await _firestoreService.respondToFriendRequest(
            request.id,
            FriendRequestStatus.declined,
          );

          Get.snackbar('Berhasil', 'Permintaan pertemanan ditolak');
        }
      }
    } catch (e) {
      _userRelationships[user.id] =
          UserRelationshipStatus.friendRequestReceived;
      _error.value = e.toString();
      print("Terjadi Kesalahan saat menolak permintaan pertemanan $e");
      Get.snackbar('Kesalahan', "Gagal menolak permintaan pertemanan");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> startChat(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final relationship =
            _userRelationships[user.id] ?? UserRelationshipStatus.none;
        if (relationship != UserRelationshipStatus.friends) {
          Get.snackbar(
            'Informasi',
            "Anda hanya bisa mengobrol dengan teman. Silakan kirim permintaan pertemanan terlebih dahulu",
          );
          return;
        }

        final chatId = await _firestoreService.createOrGetChat(
          currentUserId,
          user.id,
        );

        Get.toNamed(
          AppRoutes.chat,
          arguments: {'chatId': chatId, 'otheruser': user},
        );
      }
    } catch (e) {
      _error.value = e.toString();
      print("Terjadi Kesalahansaat Memulai Komunikasi $e");
      Get.snackbar('Kesalahan', "Gagal memulai komunikasi");
    } finally {
      _isLoading.value = false;
    }
  }

  String getRelationshipButtonText(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return 'Add Friend';
      case UserRelationshipStatus.friendRequestSent:
        return 'Request sent';
      case UserRelationshipStatus.friendRequestReceived:
        return 'Accept';
      case UserRelationshipStatus.friends:
        return 'Message';
      case UserRelationshipStatus.blocked:
        return 'Blocked';
    }
  }

  IconData getRelationshipButtonIcon(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return Icons.person_add;

      case UserRelationshipStatus.friendRequestSent:
        return Icons.access_time;

      case UserRelationshipStatus.friendRequestReceived:
        return Icons.check;

      case UserRelationshipStatus.friends:
        return Icons.chat_bubble_outline;

      case UserRelationshipStatus.blocked:
        return Icons.block;
    }
  }

  Color getRelationshipButtonColor(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return Colors.blue;

      case UserRelationshipStatus.friendRequestSent:
        return Colors.orange;

      case UserRelationshipStatus.friendRequestReceived:
        return Colors.green;

      case UserRelationshipStatus.friends:
        return Colors.blue;

      case UserRelationshipStatus.blocked:
        return Colors.redAccent;
    }
  }

  void handleRelationshipAction(UserModel user) {
    final status = getUserRelationshipStatus(user.id);

    switch (status) {
      case UserRelationshipStatus.none:
        sendFriendRequest(user);
        break;

      case UserRelationshipStatus.friendRequestSent:
        cancelFriendRequest(user);
        break;

      case UserRelationshipStatus.friendRequestReceived:
        acceptFriendRequest(user);
        break;

      case UserRelationshipStatus.friends:
        startChat(user);
        break;

      case UserRelationshipStatus.blocked:
        Get.snackbar('Informasi', "Anda telah memblokir pengguna ini");
        break;
    }
  }

  String getLastSeenText(UserModel user) {
    if (user.isOnline) {
      return 'Online';
    } else {
      final now = DateTime.now();
      final difference = now.difference(user.lastSeen);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return 'Last seen ${difference.inMinutes} m ago';
      } else if (difference.inDays < 1) {
        return 'Last seen ${difference.inHours} h ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inHours} d ago';
      } else {
        return 'Last seen ${user.lastSeen.day}/${user.lastSeen.month}/${user.lastSeen.year}';
      }
    }
  }

  void _clearError() {
    _error.value = '';
  }
}
