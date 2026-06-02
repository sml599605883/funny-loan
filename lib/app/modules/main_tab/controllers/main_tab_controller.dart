import 'package:get/get.dart';

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
        AppDataStore.getPersistentString(AppDataStore.persistedTokenKey)
            ?.trim() ??
        '';
    if (token.isEmpty) {
      if (Get.currentRoute != AppRoutes.login) {
        NavigationHelper.toLogin();
      }
      return;
    }
    currentIndex.value = index;
  }
}
