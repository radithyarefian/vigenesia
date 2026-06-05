import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:vigenesia/controllers/auth_controller.dart';
import 'package:vigenesia/models/friend_request_model.dart';
import 'package:vigenesia/models/friendship_model.dart';
import 'package:vigenesia/models/motivation_model.dart';
import 'package:vigenesia/models/user_model.dart';
import 'package:vigenesia/routes/app_routes.dart';
import 'package:vigenesia/services/firestore_service.dart';

enum MotivationDetailRelationshipStatus {
  none,
  friendRequestSent,
  friendRequestReceived,
  friends,
  blocked,
  isCurrentUser,
}

class MotivationDetailController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = Uuid();

  late final MotivationModel motivation;
  late final String timeAgo;

  final Rx<UserModel?> postOwner = Rx<UserModel?>(null);
  final Rx<MotivationDetailRelationshipStatus> relationshipStatus =
      Rx<MotivationDetailRelationshipStatus>(
        MotivationDetailRelationshipStatus.none,
      );
  final RxBool isLoading = false.obs;

  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;
  final RxList<FriendRequestModel> _receivedRequests =
      <FriendRequestModel>[].obs;
  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    motivation = args['motivation'] as MotivationModel;
    timeAgo = args['timeAgo'] as String? ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      if (motivation.userId == currentUserId) {
        relationshipStatus.value =
            MotivationDetailRelationshipStatus.isCurrentUser;
        return;
      }

      final owner = await _firestoreService.getUser(motivation.userId);
      postOwner.value = owner;

      // ✅ FIX: One-time fetch untuk set status awal yang benar
      // Ini memastikan status langsung benar saat halaman dibuka
      // tanpa menunggu stream
      await _checkInitialStatus(currentUserId);

      // ✅ Kemudian bind streams untuk update real-time
      _sentRequests.bindStream(
        _firestoreService.getSendFriendRequestsStream(currentUserId),
      );
      _receivedRequests.bindStream(
        _firestoreService.getFriendRequestsStream(currentUserId),
      );
      _friendships.bindStream(
        _firestoreService.getFriendsStream(currentUserId),
      );

      // ✅ Ever hanya untuk update real-time setelah status awal terset
      ever(_sentRequests, (_) => _updateRelationshipStatus());
      ever(_receivedRequests, (_) => _updateRelationshipStatus());
      ever(_friendships, (_) => _updateRelationshipStatus());
    } catch (e) {
      print('Error loading detail data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ BARU: One-time check menggunakan fetch langsung ke Firestore
  // Ini yang membuat status tidak reset saat masuk kembali ke halaman
  Future<void> _checkInitialStatus(String currentUserId) async {
    final userId = motivation.userId;

    // Cek friendship
    final friendship = await _firestoreService.getFriendships(
      currentUserId,
      userId,
    );
    if (friendship != null) {
      relationshipStatus.value = friendship.isBlocked
          ? MotivationDetailRelationshipStatus.blocked
          : MotivationDetailRelationshipStatus.friends;
      return;
    }

    // Cek apakah current user sudah kirim permintaan ke post owner
    final sentRequest = await _firestoreService.getPendingRequest(
      currentUserId,
      userId,
    );
    if (sentRequest != null) {
      relationshipStatus.value =
          MotivationDetailRelationshipStatus.friendRequestSent;
      return;
    }

    // Cek apakah post owner sudah kirim permintaan ke current user
    final receivedRequest = await _firestoreService.getPendingRequest(
      userId,
      currentUserId,
    );
    if (receivedRequest != null) {
      relationshipStatus.value =
          MotivationDetailRelationshipStatus.friendRequestReceived;
      return;
    }

    relationshipStatus.value = MotivationDetailRelationshipStatus.none;
  }

  void _updateRelationshipStatus() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    final userId = motivation.userId;

    final friendship = _friendships.firstWhereOrNull(
      (f) =>
          (f.user1Id == currentUserId && f.user2Id == userId) ||
          (f.user1Id == userId && f.user2Id == currentUserId),
    );

    if (friendship != null) {
      relationshipStatus.value = friendship.isBlocked
          ? MotivationDetailRelationshipStatus.blocked
          : MotivationDetailRelationshipStatus.friends;
      return;
    }

    final sentRequest = _sentRequests.firstWhereOrNull(
      (r) =>
          r.receiverId == userId && r.status == FriendRequestStatus.pending,
    );
    if (sentRequest != null) {
      relationshipStatus.value =
          MotivationDetailRelationshipStatus.friendRequestSent;
      return;
    }

    final receivedRequest = _receivedRequests.firstWhereOrNull(
      (r) =>
          r.senderId == userId && r.status == FriendRequestStatus.pending,
    );
    if (receivedRequest != null) {
      relationshipStatus.value =
          MotivationDetailRelationshipStatus.friendRequestReceived;
      return;
    }

    relationshipStatus.value = MotivationDetailRelationshipStatus.none;
  }

  Future<void> handleFriendAction() async {
    switch (relationshipStatus.value) {
      case MotivationDetailRelationshipStatus.none:
        await _sendFriendRequest();
        break;
      case MotivationDetailRelationshipStatus.friendRequestSent:
        await _cancelFriendRequest();
        break;
      case MotivationDetailRelationshipStatus.friendRequestReceived:
        await _acceptFriendRequest();
        break;
      case MotivationDetailRelationshipStatus.friends:
        await _startChat();
        break;
      default:
        break;
    }
  }

  Future<void> _sendFriendRequest() async {
    try {
      isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      final request = FriendRequestModel(
        id: _uuid.v4(),
        senderId: currentUserId,
        receiverId: motivation.userId,
        createdAt: DateTime.now(),
      );

      relationshipStatus.value =
          MotivationDetailRelationshipStatus.friendRequestSent;
      await _firestoreService.sendFriendRequest(request);

      Get.snackbar(
        'Berhasil',
        'Permintaan pertemanan telah dikirim ke ${motivation.userDisplayName}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      relationshipStatus.value = MotivationDetailRelationshipStatus.none;
      Get.snackbar('Kesalahan', 'Gagal mengirim permintaan pertemanan');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _cancelFriendRequest() async {
    try {
      isLoading.value = true;
      final request = _sentRequests.firstWhereOrNull(
        (r) =>
            r.receiverId == motivation.userId &&
            r.status == FriendRequestStatus.pending,
      );

      // Jika stream belum ada datanya, coba fetch langsung
      FriendRequestModel? requestToCancel = request;
      if (requestToCancel == null) {
        requestToCancel = await _firestoreService.getPendingRequest(
          _authController.user!.uid,
          motivation.userId,
        );
      }

      if (requestToCancel == null) return;

      relationshipStatus.value = MotivationDetailRelationshipStatus.none;
      await _firestoreService.cancelFriendRequest(requestToCancel.id);

      Get.snackbar(
        'Berhasil',
        'Permintaan pertemanan dibatalkan',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      relationshipStatus.value =
          MotivationDetailRelationshipStatus.friendRequestSent;
      Get.snackbar('Kesalahan', 'Gagal membatalkan permintaan');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _acceptFriendRequest() async {
    try {
      isLoading.value = true;
      final request = _receivedRequests.firstWhereOrNull(
        (r) =>
            r.senderId == motivation.userId &&
            r.status == FriendRequestStatus.pending,
      );

      FriendRequestModel? requestToAccept = request;
      if (requestToAccept == null) {
        requestToAccept = await _firestoreService.getPendingRequest(
          motivation.userId,
          _authController.user!.uid,
        );
      }

      if (requestToAccept == null) return;

      relationshipStatus.value = MotivationDetailRelationshipStatus.friends;
      await _firestoreService.respondToFriendRequest(
        requestToAccept.id,
        FriendRequestStatus.accepted,
      );

      Get.snackbar(
        'Berhasil',
        'Permintaan pertemanan diterima',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      relationshipStatus.value =
          MotivationDetailRelationshipStatus.friendRequestReceived;
      Get.snackbar('Kesalahan', 'Gagal menerima permintaan');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _startChat() async {
    try {
      isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      final owner = postOwner.value;
      if (owner == null) return;

      final chatId = await _firestoreService.createOrGetChat(
        currentUserId,
        owner.id,
      );

      Get.toNamed(
        AppRoutes.chat,
        arguments: {'chatId': chatId, 'otherUser': owner},
      );
    } catch (e) {
      Get.snackbar('Kesalahan', 'Gagal memulai chat');
    } finally {
      isLoading.value = false;
    }
  }

  String get actionButtonLabel {
    switch (relationshipStatus.value) {
      case MotivationDetailRelationshipStatus.none:
        return 'Tambah Teman';
      case MotivationDetailRelationshipStatus.friendRequestSent:
        return 'Permintaan Dikirim';
      case MotivationDetailRelationshipStatus.friendRequestReceived:
        return 'Terima Permintaan';
      case MotivationDetailRelationshipStatus.friends:
        return 'Kirim Pesan';
      case MotivationDetailRelationshipStatus.blocked:
        return 'Diblokir';
      case MotivationDetailRelationshipStatus.isCurrentUser:
        return '';
    }
  }

  String get actionButtonSubtitle {
    switch (relationshipStatus.value) {
      case MotivationDetailRelationshipStatus.none:
        return 'Tambahkan ${motivation.userDisplayName} sebagai Teman\nUntuk Berkomunikasi lebih lanjut';
      case MotivationDetailRelationshipStatus.friendRequestSent:
        return 'Menunggu konfirmasi dari ${motivation.userDisplayName}';
      case MotivationDetailRelationshipStatus.friendRequestReceived:
        return '${motivation.userDisplayName} mengirimkan permintaan pertemanan';
      case MotivationDetailRelationshipStatus.friends:
        return 'Anda dan ${motivation.userDisplayName} sudah berteman';
      case MotivationDetailRelationshipStatus.blocked:
        return 'Anda telah memblokir pengguna ini';
      case MotivationDetailRelationshipStatus.isCurrentUser:
        return '';
    }
  }
}