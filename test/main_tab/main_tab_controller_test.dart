import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:funny_loan/app/app.dart';
import 'package:funny_loan/app/core/storage/app_data_store.dart';
import 'package:funny_loan/app/modules/home/controllers/home_controller.dart';
import 'package:funny_loan/app/modules/main_tab/controllers/main_tab_controller.dart';
import 'package:funny_loan/app/modules/mine/controllers/mine_controller.dart';
import 'package:funny_loan/app/report/report_manager.dart';
import 'package:funny_loan/app/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppDataStore.persistedTokenKey: 'token-1',
    });
    await AppDataStore.init();
    await AppDataStore.setPersistentString(
      AppDataStore.persistedTokenKey,
      'token-1',
    );
  });

  testWidgets('changing to mine tab refreshes mine popup', (tester) async {
    final mineController = _FakeMineController();
    Get.put<MineController>(mineController);
    final controller = MainTabController();

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.home,
        getPages: <GetPage<dynamic>>[
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    controller.changeTab(2);

    expect(controller.currentIndex.value, 2);
    expect(mineController.popupRefreshCount, 1);
  });

  testWidgets('foreground permission resume refreshes visible home tab', (
    tester,
  ) async {
    await tester.pumpWidget(const FunnyLoanApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final homeController = _FakeHomeController();
    Get.replace<HomeController>(homeController);
    final reportManager = Get.find<ReportManager>();
    reportManager.isRequestingForegroundPermission = true;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    reportManager.isRequestingForegroundPermission = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(homeController.refreshCount, 1);
  });
}

class _FakeHomeController extends HomeController {
  int refreshCount = 0;

  @override
  Future<void> fetchHomeData() async {
    refreshCount += 1;
  }
}

class _FakeMineController extends MineController {
  int popupRefreshCount = 0;

  @override
  Future<void> fetchPopup() async {
    popupRefreshCount += 1;
  }
}
