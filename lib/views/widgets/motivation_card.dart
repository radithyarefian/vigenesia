import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vigenesia/models/motivation_model.dart';
import 'package:vigenesia/theme/app_theme.dart';

class MotivationCard extends StatelessWidget {
  final MotivationModel motivation;
  final String timeAgo;
  final VoidCallback? onLike;
  final bool isPreview;
  final VoidCallback? onTap;

  const MotivationCard({
    super.key,
    required this.motivation,
    required this.timeAgo,
    this.onLike,
    this.onTap,        // ✅ Tambah ini
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPreview ? null : onTap,
      child: Card(
        elevation: 1.5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildContent(),
            if (motivation.imageURL != null && motivation.imageURL!.isNotEmpty)
              _buildImage(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
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
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  motivation.userDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (motivation.userProfession.isNotEmpty)
                  Text(
                    motivation.userProfession,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        motivation.content,
        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
        maxLines: isPreview ? null : 3,
        overflow: isPreview ? null : TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = motivation.imageURL!;

    // ✅ Deteksi tipe gambar: base64, file lokal, atau URL network
    if (imageUrl.startsWith('data:image')) {
      // Base64 dari Firestore
      final base64Str = imageUrl.split(',').last;
      final bytes = base64Decode(base64Str);
      return ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    } else if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      // File lokal (preview sebelum upload)
      return ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Image.file(
          File(imageUrl),
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // URL network biasa
      return ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLike,
            child: Row(
              children: [
                Icon(
                  motivation.isLiked ? Icons.favorite : Icons.favorite_border,
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
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  color: Colors.grey[600], size: 20),
              const SizedBox(width: 4),
              Text(
                '${motivation.commentsCount}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.4)),
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
    );
  }
}