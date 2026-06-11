import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/api_navigation_helper.dart';
import '../models/app_home_model.dart';

class HomeController extends GetxController {
  ApiService? _apiService;
  bool _isApplyingTopHeroProduct = false;

  final isLoading = false.obs;
  final homeResponse = Rxn<AppHomeModel>();
  final errorMessage = RxnString();

  void onNetworkReady(ApiService apiService) {
    _apiService = apiService;
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    final apiService = _apiService;
    if (apiService == null || isLoading.value) {
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
      final message = NetworkErrorMapper.map(error);
      EasyLoading.showError(message);
      errorMessage.value = message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> applyTopHeroProduct(HomeCardModel card) async {
    final productId = card.id.trim();
    if (_isApplyingTopHeroProduct || productId.isEmpty) {
      return;
    }
    _isApplyingTopHeroProduct = true;
    try {
      EasyLoading.show();
      await ApiNavigationHelper.applyProductAndNavigate(productId);
      EasyLoading.dismiss();
    } catch (error) {
      EasyLoading.showError(NetworkErrorMapper.map(error));
    } finally {
      _isApplyingTopHeroProduct = false;
    }
  }
}
