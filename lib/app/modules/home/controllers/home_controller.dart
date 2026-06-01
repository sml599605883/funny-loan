import 'package:get/get.dart';

import '../../../network/api/api_service.dart';
import '../models/app_home_model.dart';

class HomeController extends GetxController {
  ApiService? _apiService;

  final isLoading = false.obs;
  final homeResponse = Rxn<AppHomeModel>();
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
      final data = response.data;
      if (data != null && data.mapOrNull != null) {
        homeResponse.value = AppHomeModel.fromJson(data);
      } else {
        homeResponse.value = null;
        errorMessage.value = 'Illegal response format';
      }
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
