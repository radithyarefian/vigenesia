import 'package:get/get.dart';
import 'package:vigenesia/controllers/auth_controller.dart';
import 'package:vigenesia/models/motivation_model.dart';
import 'package:vigenesia/services/firestore_service.dart';

class BerandaController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();

  final RxList<MotivationModel> motivations = <MotivationModel>[].obs;
  final RxString activeFilter = 'Terbaru'.obs;
  final RxBool isLoading = true.obs;

  // ✅ Filter mencakup semua kategori yang ada di create
  final List<String> filters = [
    'Terbaru',
    'Semangat',
    'Tujuan',
    'Inspirasi',
    'Kehidupan',
    'Karir',
  ];

  @override
  void onInit() {
    super.onInit();
    // ✅ Pakai stream agar otomatis update saat ada post baru
    _listenMotivations();
  }

  void _listenMotivations() {
    isLoading.value = true;
    // ✅ bindStream ke Firestore — otomatis update realtime
    motivations.bindStream(
      _firestoreService.getMotivationsStream().handleError((e) {
        Get.snackbar('Error', 'Gagal memuat motivasi: ${e.toString()}');
      }),
    );
    // Setelah stream pertama kali subscribe, matikan loading
    ever(motivations, (_) => isLoading.value = false);
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String get currentUserName =>
      _authController.user?.displayName ?? 'Pengguna';

  List<MotivationModel> get filteredMotivations {
    if (activeFilter.value == 'Terbaru') return motivations.toList();
    return motivations
        .where((m) => m.category == activeFilter.value)
        .toList();
  }

  void setFilter(String filter) => activeFilter.value = filter;

  // ✅ Refresh cukup reset stream ulang
  Future<void> refreshMotivations() async {
    isLoading.value = true;
    _listenMotivations();
  }

  Future<void> toggleLike(MotivationModel motivation) async {
    final index = motivations.indexWhere((m) => m.id == motivation.id);
    if (index == -1) return;

    // ✅ Update UI optimistik dulu
    motivations[index] = motivation.copyWith(
      isLiked: !motivation.isLiked,
      likesCount: motivation.isLiked
          ? motivation.likesCount - 1
          : motivation.likesCount + 1,
    );

    // TODO: simpan like ke Firestore jika perlu
  }

  String formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu yang lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan yang lalu';
    return '${(diff.inDays / 365).floor()} tahun yang lalu';
  }

  void openCreateMotivation() => Get.toNamed('/create-motivation');
}