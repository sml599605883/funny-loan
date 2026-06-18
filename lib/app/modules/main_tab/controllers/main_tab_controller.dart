import 'package:get/get.dart';

import '../../home/controllers/home_controller.dart';
import '../../mine/controllers/mine_controller.dart';
import '../../../core/storage/app_data_store.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/navigation_helper.dart';

class MainTabController extends GetxController {
  final currentIndex = 0.obs;

  void backToHomeTab() {
    currentIndex.value = 0;
  }

  void changeTab(int index) {
    if (index == currentIndex.value) {
      return;
    }
    final token =
        AppDataStore.getPersistentString(
          AppDataStore.persistedTokenKey,
        )?.trim() ??
        '';
    if (token.isEmpty) {
      if (Get.currentRoute != AppRoutes.login) {
        NavigationHelper.toLogin();
      }
      return;
    }
    final previousIndex = currentIndex.value;
    currentIndex.value = index;
    if (index == 0 && previousIndex != 0) {
      _refreshHomeData();
    } else if (index == 2 && previousIndex != 2) {
      _refreshMinePopup();
    }
  }

  void onHomeRouteVisible() {
    _refreshHomeData();
    _refreshMinePopup();
  }

  void onAppResumed() {
    _refreshHomeData();
    _refreshMinePopup();
  }

  void _refreshHomeData() {
    if (currentIndex.value != 0 || Get.currentRoute != AppRoutes.home) {
      return;
    }
    if (!Get.isRegistered<HomeController>()) {
      return;
    }
    Get.find<HomeController>().fetchHomeData();
  }

  void _refreshMinePopup() {
    if (currentIndex.value != 2 || Get.currentRoute != AppRoutes.home) {
      return;
    }
    if (!Get.isRegistered<MineController>()) {
      return;
    }
    Get.find<MineController>().fetchPopup();
  }
}
