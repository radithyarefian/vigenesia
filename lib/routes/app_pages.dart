import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/beranda_controller.dart';
import 'package:vigenesia/controllers/change_password_controller.dart';
import 'package:vigenesia/controllers/chat_controller.dart';
import 'package:vigenesia/controllers/create_motivation_controller.dart';
import 'package:vigenesia/controllers/friend_requests_controller.dart';
import 'package:vigenesia/controllers/friends_controller.dart';
import 'package:vigenesia/controllers/main_controller.dart';
import 'package:vigenesia/controllers/motivation_detail_controller.dart';
import 'package:vigenesia/controllers/notification_controller.dart';
import 'package:vigenesia/controllers/profile_controller.dart';
import 'package:vigenesia/controllers/users_list_controller.dart';
import 'package:vigenesia/routes/app_routes.dart';
import 'package:vigenesia/views/auth/forgot_password_view.dart';
import 'package:vigenesia/views/auth/login_view.dart';
import 'package:vigenesia/views/auth/register_view.dart';
import 'package:vigenesia/views/beranda_view.dart';
import 'package:vigenesia/views/chat_view.dart';
import 'package:vigenesia/views/create_motivation_view.dart';
import 'package:vigenesia/views/find_people_view.dart';
import 'package:vigenesia/views/friend_requests_view.dart';
import 'package:vigenesia/views/friends_view.dart';
import 'package:vigenesia/views/main_view.dart';
import 'package:vigenesia/views/motivation_detail_view.dart';
import 'package:vigenesia/views/notification_view.dart';
import 'package:vigenesia/views/profile/change_password_view.dart';
import 'package:vigenesia/views/profile/edit_profile_view.dart';
import 'package:vigenesia/views/profile/profile_view.dart';
import 'package:vigenesia/views/splash_view.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
    ),
   GetPage(
  name: AppRoutes.main,
  page: () => MainView(),
  binding: BindingsBuilder(() {
    Get.put(MainController());
    Get.put(BerandaController());
  }),
),
    // ✅ Hapus duplikat AppRoutes.home — gunakan BerandaView saja
    GetPage(
      name: AppRoutes.home,
      page: () => BerandaView(),
      binding: BindingsBuilder(() {
        Get.put(BerandaController());
      }),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatView(),
      binding: BindingsBuilder(() {
        Get.put(ChatController());
      }),
    ),
    GetPage(
      name: AppRoutes.usersList,
      page: () => FindPeopleView(),
      binding: BindingsBuilder(() {
        Get.put(UsersListController());
      }),
    ),
    GetPage(
      name: AppRoutes.friends,
      page: () => FriendsView(),
      binding: BindingsBuilder(() {
        Get.put(FriendsController());
      }),
    ),
    GetPage(
      name: AppRoutes.friendRequest,
      page: () => FriendRequestsView(),
      binding: BindingsBuilder(() {
        Get.put(FriendRequestsController());
      }),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => NotificationView(),
      binding: BindingsBuilder(() {
        Get.put(NotificationController());
      }),
    ),
    GetPage(
      name: '/create-motivation',
      page: () => CreateMotivationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CreateMotivationController());
      }),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => EditProfileView(),
    ),
    // ✅ Route baru detail motivasi
    GetPage(
      name: AppRoutes.motivationDetail,
      page: () => const MotivationDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MotivationDetailController());
      }),
    ),
  ];
}