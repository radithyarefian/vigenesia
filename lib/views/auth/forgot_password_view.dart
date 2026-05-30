import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:vigenesia/controllers/forgot_password_controller.dart';
import 'package:vigenesia/theme/app_theme.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.goBackToLogin,
                      icon: Icon(Icons.arrow_back_ios),
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Lupa Password",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          child: Text(
                            "Masukkan alamat email Anda untuk menerima tautan reset kata sandi",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondaryColor),
                          ),
                        ),
                      ),

                      SizedBox(height: 60),

                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            size: 50,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),

                      SizedBox(height: 40),

                      Obx(() {
                        if (controller.emailSent) {
                          return _buildEmailSentContent(controller);
                        } else {
                          return _buildEmailForm(controller);
                        }
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(ForgotPasswordController controller) {
    return Column(
      children: [
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Alamat Email',
            prefixIcon: Icon(Icons.email_outlined),
            hintText: 'Masukkan Alamat Email Anda',
          ),
          validator: controller.validateEmail,
        ),
        SizedBox(height: 32),
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : controller.sentPasswordResetEmail,
              icon: controller.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.send),
              label: Text(
                controller.isLoading ? 'Mengirim...' : 'Kirim Tautan Reset',
              ),
            ),
          ),
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Ingat Kata Sandi Anda?",
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: controller.goBackToLogin,
              child: Text(
                'Masuk',
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailSentContent(ForgotPasswordController controller) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read_rounded,
                size: 60,
                color: AppTheme.successColor,
              ),
              SizedBox(height: 16),
              Text(
                "Kami telah mengirimkan tautan untuk mengatur ulang kata sandi ke:",
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                controller.emailController.text,
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Periksa email Anda dan ikuti petunjuk untuk mengatur ulang kata sandi Anda",
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.resendEmail,
            icon: Icon(Icons.refresh),
            label: Text("kirim ulang email"),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.goBackToLogin,
            icon: Icon(Icons.arrow_back_ios),
            label: Text("kembali untuk masuk"),
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: AppTheme.secondaryColor,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Belum menerima emailnya? Periksa folder spam Anda atau coba lagi",
                  style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
