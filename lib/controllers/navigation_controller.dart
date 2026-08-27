import 'package:get/get.dart';

/// Alt navigasyondaki (Home/Market) aktif sekme durumunu tutar.
/// Başka ekranlardan (örn. favoriler kısayolu) sekme değiştirmek
/// istediğimizde bu controller üzerinden yapılır.
class NavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void goToTab(int index) {
    currentIndex.value = index;
  }
}