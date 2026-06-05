import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/users_list_controller.dart';
import 'package:vigenesia/theme/app_theme.dart';
import 'package:vigenesia/views/widgets/user_list_item.dart';

class FindPeopleView extends GetView<UsersListController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cari Orang'), leading: SizedBox()),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              if (controller.filteredUsers.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                padding: EdgeInsets.all(16),
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemCount: controller.filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = controller.filteredUsers[index];
                  return UserListItem(
                    user: user,
                    onTap: () => controller.handleRelationshipAction(user),
                    controller: controller,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: TextField(
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Cari Orang',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Obx(() {
            return controller.seacrhQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      controller.clearSearch();
                    },
                  )
                : SizedBox.shrink();
          }),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: AppTheme.cardColor,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsetsGeometry.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.people_outline,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              controller.seacrhQuery.isNotEmpty
                  ? 'Tidak ada hasil ditemukan'
                  : 'Tidak ada pengguna ditemukan',
              style: Theme.of(Get.context!).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              controller.seacrhQuery.isNotEmpty
                  ? 'Coba kata kunci pencarian lain'
                  : 'Semua pengguna akan ditampilkan di sini',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}