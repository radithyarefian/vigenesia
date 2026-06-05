import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/profile_controller.dart';
import 'package:vigenesia/routes/app_routes.dart';
import 'package:vigenesia/theme/app_theme.dart';
import 'package:vigenesia/views/widgets/motivation_card.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        final user = controller.currentuser;
        if (user == null) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 3,
                    ),
                  ),
                  child: user.photoURL.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            user.photoURL,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildDefaultAvatar(user),
                          ),
                        )
                      : Center(child: _buildDefaultAvatar(user)),
                ),
              ),
              SizedBox(height: 16),

              // Nama
              Text(
                user.displayName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),

              // Bio
              Text(
                user.bio.isEmpty ? 'Tambahkan bio Anda' : user.bio,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(
                    () => Column(
                      children: [
                        Text(
                          '${controller.postsCount}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'POS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 60),
                  Obx(
                    () => Column(
                      children: [
                        Text(
                          '${controller.likesCount}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'SUKA',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Edit Profil Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed(AppRoutes.editProfile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Postingan Sebelumnya
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Postingan Sebelumnya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),

              Obx(
                () => controller.userPosts.isEmpty
                    ? SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'Belum ada postingan',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: controller.userPosts.length,
                        itemBuilder: (context, index) {
                          final motivation = controller.userPosts[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: MotivationCard(
                              motivation: motivation,
                              timeAgo: controller.formatTimeAgo(
                                motivation.createdAt,
                              ),
                              onLike: null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDefaultAvatar(dynamic user) {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
      style: TextStyle(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 40,
      ),
    );
  }
}