import 'package:get/get.dart';

import '../../network/config/network_config.dart';
import '../../routes/navigation_helper.dart';

class WebPageOpener {
  WebPageOpener._();

  static void openPath(String path) {
    if (!Get.isRegistered<MutableNetworkState>()) {
      return;
    }
    final baseUrl = Get.find<MutableNetworkState>().webBaseUrl.trim();
    if (baseUrl.isEmpty) {
      return;
    }
    NavigationHelper.toWebView(
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path',
    );
  }
}
