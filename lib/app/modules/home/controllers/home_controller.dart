import 'package:get/get.dart';

import '../../../network/api/api_service.dart';

class HomeController extends GetxController {
  ApiService? _apiService;

  final isLoading = false.obs;
  final homeResponse = Rxn<Map<String, dynamic>>();
  final errorMessage = RxnString();

  void onNetworkReady(ApiService apiService) {
    _apiService = apiService;
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    final apiService = _apiService;
    if (apiService == null) {
      return;
    }
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final response = await apiService.fetchAppHome({});
      homeResponse.value = Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
