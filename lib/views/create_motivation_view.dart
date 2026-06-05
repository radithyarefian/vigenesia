import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/create_motivation_controller.dart';
import 'package:vigenesia/theme/app_theme.dart';
import 'package:vigenesia/views/widgets/motivation_card.dart';

class CreateMotivationView extends GetView<CreateMotivationController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Membuat Motivasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.isPosting.value
                    ? null
                    : controller.postMotivation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: controller.isPosting.value
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Pos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview card
            Obx(
              () => MotivationCard(
                motivation: controller.previewMotivation,
                timeAgo: 'Baru saja',
                onLike: null,
                isPreview: true,
              ),
            ),
            SizedBox(height: 20),

            // Kategori
            Text(
              'kategori',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 8),
            Obx(
              () => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedCategory.value.isEmpty
                        ? null
                        : controller.selectedCategory.value,
                    hint: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Pilih Kategori untuk Motivasimu',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    items: controller.categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(cat),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedCategory.value = value;
                      }
                    },
                    icon: Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Motivasi
            Text(
              'Motivasi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: TextField(
                controller: controller.motivationController,
                decoration: InputDecoration(
                  hintText: 'Berikan Motivasi Terbaikmu ...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            SizedBox(height: 16),

            // Upload gambar
            Center(
              child: Text(
                'Mengunggah Gambar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            SizedBox(height: 8),
            Obx(
              () => GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: controller.selectedImage.value != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                controller.selectedImage.value!,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: controller.removeImage,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Unggah Gambar untuk Motivasimu',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}