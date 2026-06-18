import 'package:get/get.dart';

import '../modules/home/controllers/home_controller.dart';
import '../modules/main_tab/controllers/main_tab_controller.dart';
import '../modules/mine/controllers/mine_controller.dart';
import '../network/api/api_service.dart';
import '../network/core/common_params_builder.dart';
import '../network/config/network_config.dart';
import '../network/errors/network_error_mapper.dart';
import '../network/network_module.dart';
import '../report/report_manager.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MainTabController());
    Get.put(ReportManager(), permanent: true);
    final homeController = Get.put(HomeController());
    final mineController = Get.put(MineController());
    _initNetwork(homeController, mineController);
  }

  void _initNetwork(
    HomeController homeController,
    MineController mineController,
  ) {
    NetworkModule.create(
          NetworkConfig.funnyLoanIos(
            defaultApiBaseUrl: 'http://47.80.83.200/l-funny',
            defaultWebBaseUrl: 'http://47.80.83.200',
            remoteConfigUrl: '',
            signatureSecret: '2ad42edd9ae3951b56b527ddc6b054d0',
            cryptoKey: 'db4847de8fafb26c',
            cryptoIv: '4b70df05b1c9990b',
            asyncCommonParamsProvider: CommonParamsBuilder.build,
          ),
        )
        .then((networkModule) {
          Get.put(networkModule, permanent: true);
          Get.put<ApiService>(networkModule.apiService, permanent: true);
          Get.put<MutableNetworkState>(networkModule.state, permanent: true);
          homeController.onNetworkReady(networkModule.apiService);
          mineController.onNetworkReady(networkModule.apiService);
        })
        .catchError((Object error) {
          homeController.errorMessage.value = NetworkErrorMapper.map(error);
        });
  }
}
