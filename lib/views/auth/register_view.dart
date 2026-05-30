import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:vigenesia/controllers/auth_controller.dart';
import 'package:vigenesia/routes/app_routes.dart';
import 'package:vigenesia/theme/app_theme.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  bool _obsecurePassword = true;
  bool _obsecureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.arrow_back_ios),
                    ),
                    SizedBox(width: 3),
                    Text(
                      "Buat Akun",
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
                      Center(
                        child: Text(
                          "Isi detail Anda untuk memulai",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                      SizedBox(height: 40),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Tampilan',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'Masukkan Nama Anda',
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Silahkan Masukan Nama Anda';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'email',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'Masukkan Email Anda',
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Silahkan Masukan Email Anda';
                          }
                          if (!GetUtils.isEmail(value!)) {
                            return 'Silahkan Masukkan Email Yang Valid';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obsecurePassword,
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          prefixIcon: Icon(Icons.lock_outline),
                          hintText: 'Masukkan Kata Sandi Anda',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obsecurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obsecurePassword = !_obsecurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Silahkan Masukan Kata Sandi Anda';
                          }
                          if (value!.length < 8) {
                            return 'Kata sandi harus minimal 8 karakter';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obsecureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Kata Sandi',
                          prefixIcon: Icon(Icons.lock_outline),
                          hintText: 'Konfirmasi Kata Sandi Anda',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obsecureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obsecureConfirmPassword =
                                    !_obsecureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Harap Konfirmasi kata sandi Anda';
                          }
                          if (value != _passwordController.text) {
                            return 'kata sandi tidak cocok';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24),

                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _authController.isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      _authController
                                          .registerWithEmailAndPassword(
                                            _emailController.text.trim(),
                                            _passwordController.text,
                                            _displayNameController.text,
                                          );
                                    }
                                  },
                            child: _authController.isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text("Buat Akun"),
                          ),
                        ),
                      ),

                      SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.borderColor)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Atau",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Expanded(child: Divider(color: AppTheme.borderColor)),
                        ],
                      ),

                      SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Sudah Memiliki Akun?",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(width: 5),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.login),
                            child: Text(
                              'Masuk',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
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
}
