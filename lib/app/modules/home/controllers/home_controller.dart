import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/api_navigation_helper.dart';
import '../../../routes/navigation_helper.dart';
import 'home_popup_coordinator.dart';
import '../models/app_home_model.dart';

class HomeController extends GetxController {
  static const popupScene = 1;

  ApiService? _apiService;
  bool _isApplyingTopHeroProduct = false;
  bool _isHandlingBannerTap = false;
  bool _isHandlingOrderStatusTap = false;
  bool _isHandlingRecommendationTap = false;

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

  Future<void> handleOrderStatusButtonTap(
    HomeProcessModel process,
    HomeProcessButtonModel button,
  ) async {
    final linkUrl = process.linkUrl.trim();
    final rawAction = button.action.trim();
    final action = rawAction.toLowerCase();
    if (_isHandlingOrderStatusTap || action.isEmpty) {
      return;
    }
    _isHandlingOrderStatusTap = true;
    EasyLoading.show();
    try {
      if (action == 'retry') {
        final orderNo = process.orderNo.trim();
        final apiService = _apiService;
        if (orderNo.isNotEmpty && apiService != null) {
          final response = await apiService.retryCardConfirmOrder(
            <String, dynamic>{'rejectee': orderNo},
          );
          EasyLoading.dismiss();
          final copybooks = response.data['copybooks'].stringValue;
          if (copybooks.isNotEmpty) {
            await ApiNavigationHelper.navigateRawTarget(copybooks);
          }
        }
        return;
      }
      if (action == 'change') {
        final productId = process.productId.trim();
        final orderNo = process.orderNo.trim();
        final apiService = _apiService;
        if (productId.isNotEmpty && apiService != null) {
          final response = await apiService.fetchUserAccountList(
            <String, dynamic>{'cohabiter': productId},
          );
          final keelboat = response.data['keelboat'].listValue;
          final arguments = <String, dynamic>{
            'productId': productId,
            'orderNo': orderNo,
            'ischange': true,
            'keelboat': keelboat,
          };
          if (keelboat.isNotEmpty) {
            NavigationHelper.toCardList(arguments: arguments);
          } else {
            NavigationHelper.toCertificationBindCard(
              routeKey: 'bank',
              pruneHistory: false,
              arguments: <String, dynamic>{'payload': arguments},
            );
          }
        }
        EasyLoading.dismiss();
        return;
      }
      if (linkUrl.isEmpty) {
        return;
      }
      await ApiNavigationHelper.navigateRawTarget(
        linkUrl,
        detailArguments: <String, dynamic>{
          'productId': process.productId,
          'orderNo': process.orderNo,
          'action': rawAction,
        },
      );
    } catch (error) {
      EasyLoading.showError(NetworkErrorMapper.map(error));
    } finally {
      _isHandlingOrderStatusTap = false;
    }
  }

  Future<void> handleRecommendationTap(HomeProductModel product) async {
    final linkUrl = product.linkUrl.trim();
    final productId = product.id.trim();
    if (_isHandlingRecommendationTap ||
        (linkUrl.isEmpty && productId.isEmpty)) {
      return;
    }
    _isHandlingRecommendationTap = true;
    try {
      if (linkUrl.isNotEmpty) {
        await ApiNavigationHelper.navigateRawTarget(linkUrl);
        return;
      }
      EasyLoading.show();
      await ApiNavigationHelper.applyProductAndNavigate(productId);
      EasyLoading.dismiss();
    } catch (error) {
      EasyLoading.showError(NetworkErrorMapper.map(error));
    } finally {
      _isHandlingRecommendationTap = false;
    }
  }
}
