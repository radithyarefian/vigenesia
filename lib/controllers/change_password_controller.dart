import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:vigenesia/controllers/auth_controller.dart';

class ChangePasswordController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _obscureCurrentPassword = true.obs;
  final RxBool _obscureNewPassword = true.obs;
  final RxBool _obscureConfirmPassword = true.obs;

  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get obscureCurrentPassword => _obscureCurrentPassword.value;
  bool get obscureNewPassword => _obscureNewPassword.value;
  bool get obscureConfirmPassword => _obscureConfirmPassword.value;

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleCurrentPasswordVisibilty() {
    _obscureCurrentPassword.value = !_obscureCurrentPassword.value;
  }

  void toggleNewPasswordVisibilty() {
    _obscureNewPassword.value = !_obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibilty() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No User Logged In');
      }

      // final credential = EmailAuthProvider.credential(
      //   email: user.email!,
      //   password: currentPasswordController.text,
      // );

      // await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPasswordController.text);

      Get.snackbar(
        'Berhasil',
        'Kata sandi telah berhasil diubah',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: Duration(seconds: 3),
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      await _authController.signOut();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'kata sandi saat ini salah';
          break;
        case 'weak-password':
          errorMessage = 'kata sandi baru terlalu lemah';
          break;
        case 'requires-recent-login':
          errorMessage =
              'silakan keluar dan masuk kembali sebelum mengubah kata sandi';
          break;

        default:
          errorMessage = 'Gagal mengubah kata sandi';

          _error.value = errorMessage;
          Get.snackbar(
            'kesalahan',
            errorMessage,
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
            duration: Duration(seconds: 4),
          );
      }
    } catch (e) {
      _error.value = "Gagal mengubah kata sandi";
      print(e.toString());
      Get.snackbar(
        'kesalahan',
        _error.value,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  String? validateCurrentPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Silakan masukkan kata sandi Anda saat ini';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Silakan masukkan kata sandi baru';
    }
    if (value!.length < 8) {
      return 'Kata sandi harus terdiri dari minimal 8 karakter';
    }

    if (value == currentPasswordController.text) {
      return 'Kata sandi baru harus berbeda dari kata sandi saat ini';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Silakan konfirmasi kata sandi baru Anda';
    }
    if (value != newPasswordController.text) {
      return 'Kata sandi tidak cocok';
    }
    return null;
  }

  void clearError() {
    _error.value = '';
  }
}
