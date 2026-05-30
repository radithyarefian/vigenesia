import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:vigenesia/controllers/change_password_controller.dart';
import 'package:vigenesia/theme/app_theme.dart';

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());
    return Scaffold(
      appBar: AppBar(title: Text("Ubah Kata Sandi")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'perbarui kata sandi Anda',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Masukkan kata sandi Anda saat ini dan pilih kata sandi baru yang aman',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: 40),
                Obx(
                  () => TextFormField(
                    controller: controller.currentPasswordController,
                    obscureText: controller.obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'kata sandi saat ini',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: controller.toggleCurrentPasswordVisibilty,
                        icon: Icon(
                          controller.obscureCurrentPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      hintText: 'masukkan kata sandi Anda saat ini',
                    ),
                    validator: controller.validateCurrentPassword,
                  ),
                ),
                SizedBox(height: 20),
                Obx(
                  () => TextFormField(
                    controller: controller.newPasswordController,
                    obscureText: controller.obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'kata sandi Baru',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: controller.toggleNewPasswordVisibilty,
                        icon: Icon(
                          controller.obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      hintText: 'masukkan kata sandi Baru Anda',
                    ),
                    validator: controller.validateNewPassword,
                  ),
                ),
                SizedBox(height: 20),
                Obx(
                  () => TextFormField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'konfirmasi kata sandi baru',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: controller.toggleConfirmPasswordVisibilty,
                        icon: Icon(
                          controller.obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      hintText: 'konfirmasikan kata sandi baru Anda',
                    ),
                    validator: controller.validateConfirmPassword,
                  ),
                ),
                SizedBox(height: 40),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : controller.changePassword,
                      icon: controller.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.security),
                      label: Text(
                        controller.isLoading
                            ? 'Updating...'
                            : 'Update Password',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
