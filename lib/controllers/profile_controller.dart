import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/auth_controller.dart';
import 'package:vigenesia/models/motivation_model.dart';
import 'package:vigenesia/models/user_model.dart';
import 'package:vigenesia/services/firestore_service.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController professionController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  final RxBool _isSaving = false.obs;
  final RxBool _isGettingLocation = false.obs;
  final RxBool _isDeleting = false.obs;
  final RxBool _isEditing = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxInt _postsCount = 0.obs;
  final RxInt _likesCount = 0.obs;
  final RxList<MotivationModel> _userPosts = <MotivationModel>[].obs;

  final RxDouble mapLatitude = (-6.200000).obs;
  final RxDouble mapLongitude = (106.816666).obs;

  bool get isSaving => _isSaving.value;
  bool get isGettingLocation => _isGettingLocation.value;
  bool get isDeleting => _isDeleting.value;
  bool get isLoading => _isSaving.value || _isGettingLocation.value;
  bool get isEditing => _isEditing.value;
  String get error => _error.value;
  UserModel? get currentuser => _currentUser.value;
  int get postsCount => _postsCount.value;
  int get likesCount => _likesCount.value;
  List<MotivationModel> get userPosts => _userPosts.toList();

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    displayNameController.dispose();
    emailController.dispose();
    professionController.dispose();
    bioController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.onClose();
  }

  void _loadUserData() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _currentUser.bindStream(_firestoreService.getUserStream(currentUserId));

      ever(_currentUser, (UserModel? user) {
        if (user != null) {
          displayNameController.text = user.displayName;
          emailController.text = user.email;
          professionController.text = user.profession;
          bioController.text = user.bio;
          addressController.text = user.address;
          latitudeController.text = user.latitude?.toString() ?? '';
          longitudeController.text = user.longitude?.toString() ?? '';

          if (user.latitude != null && user.longitude != null) {
            mapLatitude.value = user.latitude!;
            mapLongitude.value = user.longitude!;
          }

          _loadUserStats(user.id);
          _loadUserPosts(user.id);
        }
      });
    }
  }

  Future<void> _loadUserStats(String userId) async {
    try {
      final postsCount = await _firestoreService.getUserPostsCount(userId);
      final likesCount = await _firestoreService.getUserLikesCount(userId);
      _postsCount.value = postsCount;
      _likesCount.value = likesCount;
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadUserPosts(String userId) async {
    try {
      final posts = await _firestoreService.getUserPosts(userId, limit: 5);
      _userPosts.value = posts;
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;

    if (!_isEditing.value) {
      final user = _currentUser.value;
      if (user != null) {
        displayNameController.text = user.displayName;
        emailController.text = user.email;
        professionController.text = user.profession;
        bioController.text = user.bio;
        addressController.text = user.address;
        latitudeController.text = user.latitude?.toString() ?? '';
        longitudeController.text = user.longitude?.toString() ?? '';

        if (user.latitude != null && user.longitude != null) {
          mapLatitude.value = user.latitude!;
          mapLongitude.value = user.longitude!;
        }
      }
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      _isGettingLocation.value = true;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'GPS Mati',
          'Silakan aktifkan GPS terlebih dahulu',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Izin Ditolak Permanen',
          'Aktifkan izin lokasi di Pengaturan > Aplikasi',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Izin Ditolak',
          'Aplikasi membutuhkan akses lokasi',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitudeController.text = position.latitude.toStringAsFixed(6);
      longitudeController.text = position.longitude.toStringAsFixed(6);
      mapLatitude.value = position.latitude;
      mapLongitude.value = position.longitude;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [
            place.street,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
          ].where((p) => p != null && p.isNotEmpty).toList();

          addressController.text = parts.join(', ');
        }
      } catch (geocodeError) {
        addressController.text =
            '${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)}';
        print('Geocoding error: $geocodeError');
      }

      Get.snackbar(
        'Berhasil',
        'Lokasi berhasil diambil',
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(12),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mendapatkan lokasi: $e',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isGettingLocation.value = false;
    }
  }

  Future<void> updateProfile() async {
    try {
      _isSaving.value = true;

      final userId = _authController.user?.uid;
      if (userId == null) throw Exception('User tidak ditemukan');

      final currentUser = _currentUser.value;
      if (currentUser == null) throw Exception('Data user tidak ditemukan');

      final updatedUser = currentUser.copyWith(
        displayName: displayNameController.text.trim(),
        profession: professionController.text.trim(),
        bio: bioController.text.trim(),
        address: addressController.text.trim(),
        latitude: mapLatitude.value,
        longitude: mapLongitude.value,
      );

      await _firestoreService.updateUser(updatedUser);

      // tutup mode edit
      _isEditing.value = false;

      // kembali ke halaman Profile
      Get.back();

      // tampilkan snackbar setelah kembali
      Future.delayed(const Duration(milliseconds: 200), () {
        Get.snackbar(
          'Berhasil',
          'Profil berhasil diperbarui',
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
        );
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authController.signOut();
    } catch (e) {
      Get.snackbar('Error', 'Gagal keluar');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Hapus Akun'),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun Anda? '
            'Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result == true) {
        _isDeleting.value = true;
        await _authController.deleteAccount();
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus akun');
    } finally {
      _isDeleting.value = false;
    }
  }

  String getJoinedData() {
    final user = _currentUser.value;
    if (user == null) return '';
    final date = user.createdAt;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Bergabung ${months[date.month - 1]} ${date.year}';
  }

  String formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    if (diff.inDays < 30)
      return '${(diff.inDays / 7).floor()} minggu yang lalu';
    if (diff.inDays < 365)
      return '${(diff.inDays / 30).floor()} bulan yang lalu';
    return '${(diff.inDays / 365).floor()} tahun yang lalu';
  }

  void clearError() => _error.value = '';
}
