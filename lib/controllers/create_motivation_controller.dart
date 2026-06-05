import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:vigenesia/controllers/auth_controller.dart';
import 'package:vigenesia/models/motivation_model.dart';
import 'package:vigenesia/models/user_model.dart';
import 'package:vigenesia/services/firestore_service.dart';

class CreateMotivationController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController motivationController = TextEditingController();
  final RxString motivationText = ''.obs;
  final RxString selectedCategory = ''.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxBool isPosting = false.obs;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  final List<String> categories = [
    'Semangat',
    'Tujuan',
    'Inspirasi',
    'Kehidupan',
    'Karir',
  ];

  @override
  void onInit() {
    super.onInit();
    motivationController.addListener(() {
      motivationText.value = motivationController.text;
    });
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final uid = _authController.user?.uid;
    if (uid != null) {
      final user = await _firestoreService.getUser(uid);
      _currentUser.value = user;
    }
  }

  MotivationModel get previewMotivation {
    final firebaseUser = _authController.user;
    final userModel = _currentUser.value;

    return MotivationModel(
      id: '',
      userId: firebaseUser?.uid ?? '',
      userDisplayName:
          userModel?.displayName ?? firebaseUser?.displayName ?? '',
      userProfession: userModel?.profession ?? '',
      userPhotoURL: userModel?.photoURL ?? firebaseUser?.photoURL ?? '',
      content: motivationText.value.isEmpty
          ? 'Berikan motivasi terbaikmu...'
          : motivationText.value,
      imageURL: selectedImage.value?.path,
      category: selectedCategory.value.isEmpty
          ? 'Kategori'
          : selectedCategory.value,
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
      createdAt: DateTime.now(),
    );
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) selectedImage.value = File(picked.path);
  }

  void removeImage() => selectedImage.value = null;

  // ✅ Resize + kompres pakai pure Dart package 'image', tanpa native plugin
  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      // Baca bytes asli
      final rawBytes = await imageFile.readAsBytes();

      // Decode ke objek Image
      final original = img.decodeImage(rawBytes);
      if (original == null) throw Exception('Gagal membaca file gambar');

      // ✅ Resize: max lebar/tinggi 800px, pertahankan aspek rasio
      final resized = img.copyResize(
        original,
        width: original.width > original.height ? 800 : -1,
        height: original.width <= original.height ? 800 : -1,
      );

      // ✅ Encode ke JPEG dengan kualitas 60%
      final compressedBytes = img.encodeJpg(resized, quality: 60);

      // Cek ukuran akhir
      final sizeKB = compressedBytes.length / 1024;
      if (sizeKB > 700) {
        throw Exception(
          'Gambar masih terlalu besar setelah dikompres '
          '(${sizeKB.toStringAsFixed(0)}KB). '
          'Pilih gambar lain yang lebih kecil.',
        );
      }

      return 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> postMotivation() async {
    if (selectedCategory.value.isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Pilih kategori terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (motivationController.text.trim().isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Tulis motivasimu terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isPosting.value = true;
    try {
      final firebaseUser = _authController.user;
      final userModel = _currentUser.value;

      if (firebaseUser == null) {
        Get.snackbar('Error', 'User tidak ditemukan, silakan login ulang');
        return;
      }

      String? imageBase64;
      if (selectedImage.value != null) {
        imageBase64 = await _convertImageToBase64(selectedImage.value!);
      }

      final motivation = MotivationModel(
        id: '',
        userId: firebaseUser.uid,
        userDisplayName:
            userModel?.displayName ?? firebaseUser.displayName ?? '',
        userProfession: userModel?.profession ?? '',
        userPhotoURL: userModel?.photoURL ?? firebaseUser.photoURL ?? '',
        content: motivationController.text.trim(),
        imageURL: imageBase64,
        category: selectedCategory.value,
        likesCount: 0,
        commentsCount: 0,
        isLiked: false,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createMotivation(motivation);

      Get.back();
      Get.snackbar(
        'Berhasil',
        'Motivasi berhasil diposting!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memposting motivasi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isPosting.value = false;
    }
  }

  @override
  void onClose() {
    motivationController.dispose();
    super.onClose();
  }
}