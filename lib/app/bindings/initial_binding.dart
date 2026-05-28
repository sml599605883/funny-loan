import 'package:get/get.dart';

import '../modules/main_tab/controllers/main_tab_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MainTabController());
  }
}
