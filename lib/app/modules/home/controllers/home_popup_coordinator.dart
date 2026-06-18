import '../../../network/api/api_service.dart';
import '../models/home_popup_data.dart';
import '../views/widgets/home_popup.dart';

class HomePopupCoordinator {
  const HomePopupCoordinator({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;

  Future<void> requestAndShow({required int scene}) async {
    try {
      final response = await _apiService.fetchPopup(<String, dynamic>{
        'interferons': scene,
      });
      final popup = HomePopupData.fromJson(response.data);
      if (popup.shouldShow) {
        await HomePopup.show(popup);
      }
    } catch (_) {}
  }
}
