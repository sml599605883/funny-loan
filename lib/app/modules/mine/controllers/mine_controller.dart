import 'package:get/get.dart';

import '../../../network/api/api_service.dart';
import '../../home/controllers/home_popup_coordinator.dart';

class MineController extends GetxController {
  static const popupScene = 2;

  ApiService? _apiService;
  bool _isFetchingPopup = false;

  void onNetworkReady(ApiService apiService) {
    _apiService = apiService;
  }

  Future<void> fetchPopup() async {
    final apiService = _apiService;
    if (apiService == null || _isFetchingPopup) {
      return;
    }
    _isFetchingPopup = true;
    try {
      await HomePopupCoordinator(
        apiService: apiService,
      ).requestAndShow(scene: popupScene);
    } finally {
      _isFetchingPopup = false;
    }
  }
}
