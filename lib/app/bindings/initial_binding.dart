import 'package:get/get.dart';

import '../modules/home/controllers/home_controller.dart';
import '../modules/main_tab/controllers/main_tab_controller.dart';
import '../network/api/api_service.dart';
import '../network/core/common_params_builder.dart';
import '../network/config/network_config.dart';
import '../network/network_module.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MainTabController());
    final homeController = Get.put(HomeController());
    _initNetwork(homeController);
  }

  void _initNetwork(HomeController homeController) {
    NetworkModule.create(
          NetworkConfig.funnyLoanIos(
            defaultApiBaseUrl: 'http://47.80.83.200/l-funny',
            defaultWebBaseUrl: 'http://47.80.83.200',
            remoteConfigUrl: '',
            signatureSecret: '2ad42edd9ae3951b56b527ddc6b054d0',
            cryptoKey: '1234567890abcdef',
            cryptoIv: 'abcdef1234567890',
            asyncCommonParamsProvider: CommonParamsBuilder.build,
          ),
        )
        .then((networkModule) {
          Get.put(networkModule, permanent: true);
          Get.put<ApiService>(networkModule.apiService, permanent: true);
          Get.put<MutableNetworkState>(networkModule.state, permanent: true);
          homeController.onNetworkReady(networkModule.apiService);
        })
        .catchError((Object error) {
          homeController.errorMessage.value = error.toString();
        });
  }
}
