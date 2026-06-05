import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:vigenesia/controllers/auth_controller.dart';
import 'package:vigenesia/models/friendship_model.dart';
import 'package:vigenesia/models/user_model.dart';
import 'package:vigenesia/routes/app_routes.dart';
import 'package:vigenesia/services/firestore_service.dart';

class FriendsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;
  final RxList<UserModel> _friends = <UserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxString _searchQuery = ''.obs;
  final RxList<UserModel> _filteredFriends = <UserModel>[].obs;

  StreamSubscription? _friendshipsSubscriptions;

  List<FriendshipModel> get frienships => _friendships.toList();
  List<UserModel> get friends => _friends;
  List<UserModel> get filteredFriends => _filteredFriends;
  bool get isloading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    _loadFriends();

    debounce(
      _searchQuery,
      (_) => _filterFriends,
      time: Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    _friendshipsSubscriptions?.cancel();
    super.onClose();
  }

  void _loadFriends() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _friendshipsSubscriptions?.cancel();

      _friendshipsSubscriptions = _firestoreService
          .getFriendsStream(currentUserId)
          .listen((friendshipList) {
            _friendships.value = friendshipList;
            _loadFriendsDetails(currentUserId, friendshipList);
          });
    }
  }

  Future<void> _loadFriendsDetails(
    String currentUserId,
    List<FriendshipModel> friendshipsList,
  ) async {
    try {
      _isLoading.value = true;

      List<UserModel> friendUsers = [];

      final futures = friendshipsList.map((friendship) async {
        String friendId = friendship.getOtherUserId(currentUserId);
        return await _firestoreService.getUser(friendId);
      }).toList();

      final results = await Future.wait(futures);

      for (var friend in results) {
        if (friend != null) {
          friendUsers.add(friend);
        }
      }

      _friends.value = friendUsers;
      _filterFriends();
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  void _filterFriends() {
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      _filteredFriends.value = _friends;
    } else {
      _filteredFriends.value = _friends.where((friend) {
        return friend.displayName.toLowerCase().contains(query) ||
            friend.email.toLowerCase().contains(query);
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query; 
  }

  void clearSearc() {
    _searchQuery.value = '';
  }

  Future<void> refreshFriends() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _loadFriends();
    }
  }

  Future<void> removeFriend(UserModel friend) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Remove friend"),
          content: Text(
            'Are you sure you want to remove ${friend.displayName} from your friends?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text('Remove'),
            ),
          ],
        ),
      );

      if (result == true) {
        final currentUserId = _authController.user?.uid;
        if (currentUserId != null) {
          await _firestoreService.removeFriendShip(currentUserId, friend.id);
          Get.snackbar(
            'Succes',
            '${friend.displayName} has been removed from your friends',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
            duration: Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove friend',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: Duration(seconds: 4),
      );
      print(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> blockFriend(UserModel friend) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Block user"),
          content: Text(
            'Are you sure you want to block ${friend.displayName}? You will no longer be able to see each other\'s profiles or interact.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text('Block'),
            ),
          ],
        ),
      );

      if (result == true) {
        final currentUserId = _authController.user?.uid;
        if (currentUserId != null) {
          await _firestoreService.blockUser(currentUserId, friend.id);
          Get.snackbar(
            'Success',
            '${friend.displayName} has been blocked.',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
            duration: Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to block user',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: Duration(seconds: 4),
      );
      print(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> startChat(UserModel friend) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        Get.toNamed(
          AppRoutes.chat,
          arguments: {'chatId': null, 'otherUser': friend, 'isNewChat': true},
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start chat',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: Duration(seconds: 4),
      );
      print(e.toString());
    } finally {
      _isLoading.value = false;
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

  void openFriendRequest() {
    Get.toNamed(AppRoutes.friendRequest);
  }

  void clearError() {
    _error.value = '';
  }
}
