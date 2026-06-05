import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/motivation_detail_controller.dart';
import 'package:vigenesia/theme/app_theme.dart';

class MotivationDetailView extends GetView<MotivationDetailController> {
  const MotivationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Detail Motivasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildMotivationCard(context),
              // ✅ Hanya tampilkan section teman jika bukan post sendiri
              if (controller.relationshipStatus.value !=
                  MotivationDetailRelationshipStatus.isCurrentUser)
                _buildFriendSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMotivationCard(BuildContext context) {
    final motivation = controller.motivation;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + nama + profesi + waktu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: motivation.userPhotoURL.isNotEmpty
                      ? NetworkImage(motivation.userPhotoURL)
                      : null,
                  child: motivation.userPhotoURL.isEmpty
                      ? Text(
                          motivation.userDisplayName.isNotEmpty
                              ? motivation.userDisplayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        motivation.userDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      if (motivation.userProfession.isNotEmpty)
                        Text(
                          motivation.userProfession,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  controller.timeAgo,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Konten teks (full, tidak dibatasi maxLines)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              motivation.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),

          // Gambar (jika ada)
          if (motivation.imageURL != null && motivation.imageURL!.isNotEmpty)
            _buildImage(motivation.imageURL!),

          // Footer: like, komentar, kategori
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  motivation.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: motivation.isLiked
                      ? AppTheme.primaryColor
                      : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${motivation.likesCount}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${motivation.commentsCount}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primaryColor.withOpacity(0.05),
                  ),
                  child: Text(
                    motivation.category,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final bytes = base64Decode(imageUrl.split(',').last);
      return ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    } else if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      return Image.file(
        File(imageUrl),
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
  }

  Widget _buildFriendSection() {
    return Obx(() {
      final status = controller.relationshipStatus.value;
      final subtitle = controller.actionButtonSubtitle;
      final label = controller.actionButtonLabel;
      final isBlocked =
          status == MotivationDetailRelationshipStatus.blocked;

      // ✅ Warna tombol sesuai status
      Color buttonColor;
      switch (status) {
        case MotivationDetailRelationshipStatus.friendRequestSent:
          buttonColor = Colors.orange;
          break;
        case MotivationDetailRelationshipStatus.friendRequestReceived:
          buttonColor = Colors.green;
          break;
        case MotivationDetailRelationshipStatus.friends:
          buttonColor = AppTheme.primaryColor;
          break;
        case MotivationDetailRelationshipStatus.blocked:
          buttonColor = Colors.grey;
          break;
        default:
          buttonColor = Colors.blue;
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          children: [
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            if (!isBlocked && label.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.handleFriendAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
          ],
        ),
      );
    });
  }
}