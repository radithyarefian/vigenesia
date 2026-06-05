import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/beranda_controller.dart';
import 'package:vigenesia/routes/app_routes.dart';
import 'package:vigenesia/theme/app_theme.dart';
import 'package:vigenesia/views/widgets/motivation_card.dart';

class BerandaView extends GetView<BerandaController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshMotivations,
                color: AppTheme.primaryColor,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }
                  if (controller.filteredMotivations.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: controller.filteredMotivations.length,
                    itemBuilder: (context, index) {
                      final motivation = controller.filteredMotivations[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: MotivationCard(
                          motivation: motivation,
                          timeAgo: controller.formatTimeAgo(
                            motivation.createdAt,
                          ),
                          onLike: () => controller.toggleLike(motivation),
                          onTap: () => Get.toNamed(
                            AppRoutes.motivationDetail,
                            arguments: {
                              'motivation': motivation,
                              'timeAgo': controller.formatTimeAgo(
                                motivation.createdAt,
                              ),
                            },
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openCreateMotivation,
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.greeting,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
          SizedBox(height: 2),
          Obx(
            () => Text(
              controller.currentUserName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.filters.map((filter) {
              final isSelected = controller.activeFilter.value == filter;
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.setFilter(filter),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[400]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.transparent,
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: Get.height * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Belum ada motivasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Jadilah yang pertama berbagi motivasi!',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: controller.openCreateMotivation,
                icon: Icon(Icons.add),
                label: Text('Buat Motivasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
