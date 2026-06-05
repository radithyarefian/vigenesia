import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/main_controller.dart';
import 'package:vigenesia/theme/app_theme.dart';
import 'package:vigenesia/views/beranda_view.dart';
import 'package:vigenesia/views/find_people_view.dart';
import 'package:vigenesia/views/friends_view.dart';
import 'package:vigenesia/views/home_view.dart';
import 'package:vigenesia/views/profile/profile_view.dart';

class MainView extends GetView<MainController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        children: [
          BerandaView(),
          HomeView(),
          FriendsView(),
          FindPeopleView(),
          ProfileView(),
        ],
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex,
          onTap: controller.changeTabIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondaryColor,
          backgroundColor: Colors.white,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: _buildIconWithBadge(
                Icons.chat_outlined,
                controller.getUnreadCount(),
              ),
              activeIcon: _buildIconWithBadge(
                Icons.chat,
                controller.getUnreadCount(),
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Teman',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_outlined),
              activeIcon: Icon(Icons.person_search),
              label: 'Cari Teman',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithBadge(IconData icon, int count) {
    return Stack(
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: BoxConstraints(minWidth: 12, minHeight: 12),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(color: Colors.white, fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
