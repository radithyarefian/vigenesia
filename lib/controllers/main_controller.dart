import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:vigenesia/controllers/friends_controller.dart';
import 'package:vigenesia/controllers/home_controller.dart';
import 'package:vigenesia/controllers/profile_controller.dart';
import 'package:vigenesia/controllers/users_list_controller.dart';

class MainController extends GetxController {
  final RxInt _currentindex = 0.obs;
  final PageController pageController = PageController();

  int get currentIndex => _currentindex.value;

  @override
  void onInit() {
    super.onInit();

    // Init all required controllers

    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => FriendsController());
    Get.lazyPut(() => UsersListController());
    Get.lazyPut(() => ProfileController());
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
