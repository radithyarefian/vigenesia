import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:vigenesia/controllers/auth_controller.dart';
import 'package:vigenesia/controllers/beranda_controller.dart';
import 'package:vigenesia/controllers/friends_controller.dart';
import 'package:vigenesia/controllers/home_controller.dart';
import 'package:vigenesia/controllers/profile_controller.dart';
import 'package:vigenesia/controllers/users_list_controller.dart';
import 'package:vigenesia/routes/app_routes.dart';

class MainController extends GetxController {
  final RxInt _currentindex = 0.obs;
  final PageController pageController = PageController();
  final AuthController _authController = Get.find<AuthController>();

  int get currentIndex => _currentindex.value;

  @override
  void onInit() {
    super.onInit();

    Get.put(HomeController(), permanent: true);
    Get.put(FriendsController(), permanent: true);
    Get.put(UsersListController(), permanent: true);
    Get.put(ProfileController(), permanent: true);
    Get.put(BerandaController(), permanent: true);

    Future.delayed(const Duration(seconds: 2), () {
      final user = _authController.currentUser;

      if (user != null && !user.profileCompleted) {
        Get.dialog(
          AlertDialog(
            title: const Text('Lengkapi Profil'),
            content: const Text(
              'Silakan lengkapi profil Anda terlebih dahulu agar pengguna lain dapat mengenal Anda.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.editProfile);
                },
                child: const Text('Oke'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      }
    });
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void changeTabIndex(int index) {
    _currentindex.value = index;
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void onPageChanged(int index) {
    _currentindex.value = index;
  }

  int getUnreadCount() {
    try {
      final homeController = Get.find<HomeController>();
      return homeController.getTotalUnreadCount();
    } catch (e) {}
    return 0;
  }

  int getNotificationCount() {
    try {
      final homeController = Get.find<HomeController>();
      return homeController.getUnreadNotificationsCount();
    } catch (e) {}
    return 0;
  }
}
