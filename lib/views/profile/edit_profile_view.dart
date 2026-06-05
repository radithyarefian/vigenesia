import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:vigenesia/controllers/profile_controller.dart';
import 'package:vigenesia/routes/app_routes.dart';
import 'package:vigenesia/theme/app_theme.dart';

class EditProfileView extends GetView<ProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Edit Profil'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (controller.isEditing) controller.toggleEditing();
            Get.back();
          },
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.toggleEditing,
              child: Text(
                controller.isEditing ? 'Batal' : 'Edit',
                style: TextStyle(
                  color: controller.isEditing
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final user = controller.currentuser;
        if (user == null) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        final isEditing = controller.isEditing;

        return SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama Tampilan
              _buildSectionLabel('Nama Tampilan'),
              SizedBox(height: 8),
              TextFormField(
                controller: controller.displayNameController,
                enabled: isEditing,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama Anda',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 16),

              // Email
              _buildSectionLabel('Email'),
              SizedBox(height: 8),
              TextFormField(
                controller: controller.emailController,
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Email Anda',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'Email tidak dapat diubah',
                ),
              ),
              SizedBox(height: 16),

              // Profesi
              _buildSectionLabel('Profesi'),
              SizedBox(height: 8),
              TextFormField(
                controller: controller.professionController,
                enabled: isEditing,
                decoration: InputDecoration(
                  hintText: 'Contoh: IT Developer',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              SizedBox(height: 16),

              // Bio
              _buildSectionLabel('Bio'),
              SizedBox(height: 8),
              TextFormField(
                controller: controller.bioController,
                enabled: isEditing,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ceritakan tentang diri Anda',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              SizedBox(height: 16),

              // Lokasi
              _buildSectionLabel('Lokasi'),
              SizedBox(height: 8),
              Text(
                'Alamat',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              TextFormField(
                controller: controller.addressController,
                readOnly: true,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: controller.addressController.text.isEmpty
                      ? 'Belum ada lokasi tersimpan'
                      : null,
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              SizedBox(height: 12),

              // Saat EDITING: tampilkan peta + tombol GPS + tombol simpan
              if (isEditing) ...[
                Obx(() {
                  final lat = controller.mapLatitude.value;
                  final lng = controller.mapLongitude.value;

                  return Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: FlutterMap(
                      key: ValueKey('map_${lat}_$lng'),
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 16,
                        onTap: (tapPosition, point) {
                          controller.mapLatitude.value = point.latitude;
                          controller.mapLongitude.value = point.longitude;
                          controller.latitudeController.text =
                              point.latitude.toStringAsFixed(6);
                          controller.longitudeController.text =
                              point.longitude.toStringAsFixed(6);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.vigenesia',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.location_pin,
                                color: AppTheme.primaryColor,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 8),
                Text(
                  '💡 Tap peta untuk pilih lokasi, atau gunakan tombol GPS',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 12),
                _buildGpsButton(),
                SizedBox(height: 12),
                _buildSaveButton(),
              ],

              // Saat TIDAK editing: tampilkan card 3 tombol
              if (!isEditing) ...[
                SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      // ✅ Ubah Kata Sandi — sekarang bisa diklik
                      ListTile(
                        leading: Icon(
                          Icons.security,
                          color: Colors.deepPurple,
                        ),
                        title: Text('Ubah Kata Sandi'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Get.toNamed(AppRoutes.changePassword),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.delete_forever,
                          color: AppTheme.errorColor,
                        ),
                        title: Text('Hapus Akun'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: controller.deleteAccount,
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: AppTheme.errorColor,
                        ),
                        title: Text('Keluar'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: controller.signOut,
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 24),
              Center(
                child: Text(
                  'Vigenesia v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildGpsButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: controller.isGettingLocation
              ? null
              : controller.getCurrentLocation,
          icon: controller.isGettingLocation
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                )
              : Icon(Icons.my_location),
          label: Text(
            controller.isGettingLocation
                ? 'Mengambil lokasi...'
                : 'Ambil Lokasi GPS',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.isSaving ? null : controller.updateProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
          child: controller.isSaving
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Simpan Perubahan'),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }
}