import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/api_navigation_helper.dart';
import 'home_popup_coordinator.dart';
import '../models/app_home_model.dart';

class HomeController extends GetxController {
  static const popupScene = 1;

  ApiService? _apiService;
  bool _isApplyingTopHeroProduct = false;
  bool _isHandlingBannerTap = false;
  bool _isHandlingOrderStatusTap = false;

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
      await _fetchPopup(apiService);
    } catch (error) {
      final message = NetworkErrorMapper.map(error);
      EasyLoading.showError(message);
      errorMessage.value = message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchPopup(ApiService apiService) async {
    await HomePopupCoordinator(
      apiService: apiService,
    ).requestAndShow(scene: popupScene);
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

  Future<void> handleBannerTap(HomeBannerModel banner) async {
    final linkUrl = banner.linkUrl.trim();
    if (_isHandlingBannerTap || linkUrl.isEmpty) {
      return;
    }
    _isHandlingBannerTap = true;
    try {
      final apiService = _apiService;
      final bannerId = banner.id.trim();
      if (apiService != null && bannerId.isNotEmpty) {
        await apiService.uploadBannerClickRecord(<String, dynamic>{
          'mislodges': bannerId,
        });
      }
      await ApiNavigationHelper.navigateRawTarget(linkUrl);
    } catch (error) {
      EasyLoading.showError(NetworkErrorMapper.map(error));
    } finally {
      _isHandlingBannerTap = false;
    }
  }

  Future<void> handleOrderStatusTap(HomeProcessModel process) async {
    final linkUrl = process.linkUrl.trim();
    if (_isHandlingOrderStatusTap || linkUrl.isEmpty) {
      return;
    }
    _isHandlingOrderStatusTap = true;
    try {
      await ApiNavigationHelper.navigateRawTarget(
        linkUrl,
        detailArguments: <String, dynamic>{
          'productId': process.productId,
          'orderNo': process.orderNo,
        },
      );
    } catch (error) {
      EasyLoading.showError(NetworkErrorMapper.map(error));
    } finally {
      _isHandlingOrderStatusTap = false;
    }
  }
}
