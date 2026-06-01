import 'package:flutter_easyloading/flutter_easyloading.dart';
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
      EasyLoading.show();
      final response = await apiService.fetchAppHome({});
      final data = response.data;
      EasyLoading.dismiss();
      homeResponse.value = AppHomeModel.fromJson(data);
    } catch (error) {
      EasyLoading.showError(error.toString());
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
