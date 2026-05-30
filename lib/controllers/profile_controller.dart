import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/auth_controller.dart';
import 'package:vigenesia/models/user_model.dart';
import 'package:vigenesia/services/firestore_service.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final RxBool _isloading = false.obs;
  final RxBool _isEditing = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  bool get isLoading => _isloading.value;
  bool get isEditing => _isEditing.value;
  String get error => _error.value;
  UserModel? get currentuser => _currentUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    // displayNameController.dispose();
    // emailController.dispose();
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
        }
      });
    }
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;

    if (!_isEditing.value) {
      final user = _currentUser.value;
      if (user != null) {
        displayNameController.text = user.displayName;
        emailController.text = user.email;
      }
    }
  }

  Future<void> updateProfile() async {
    try {
      _isloading.value = true;
      _error.value = '';

      final user = _currentUser.value;
      if (user == null) return;

      final updatedUser = user.copyWith(
        displayName: displayNameController.text,
      );

      await _firestoreService.updateUser(updatedUser);
      _isEditing.value = false;
      Get.snackbar('Berhasil', "Pembaruan Profil Berhasil");
    } catch (e) {
      _error.value = e.toString();
      print(e.toString());
      Get.snackbar('Kesalahan', "Gagal Memperbarui Profil");
    } finally {
      _isloading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authController.signOut();
    } catch (e) {
      Get.snackbar('Kesalahan', "Gagal keluar");
    }
  }

  Future<void> deleteAccount() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Hapus Akun"),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun Anda? Tindakan ini tidak dapat dibatalkan',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text("Hapus", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result == true) {
        _isloading.value = true;
        await _authController.deleteAccount();
      }
    } catch (e) {
      Get.snackbar('Kesalahan', "Gagal Menghapus Akun");
    } finally {
      _isloading.value = false;
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

    return 'Joined ${months[date.month - 1]} ${date.year}';
  }

  void clearError() {
    _error.value = '';
  }
}
