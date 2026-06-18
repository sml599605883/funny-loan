import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/navigation_helper.dart';
import '../../home/views/home_page.dart';
import '../../mine/views/mine_page.dart';
import '../../order_list/views/order_list_page.dart';
import '../controllers/main_tab_controller.dart';

class MainTabPage extends GetView<MainTabController> {
  const MainTabPage({super.key});

  static const _tabIconSize = 30.0;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: <Widget>[
            const HomePage(),
            OrderListPage(isVisible: controller.currentIndex.value == 1),
            const MinePage(),
          ],
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: controller.currentIndex.value,
              onTap: controller.changeTab,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: _TabBarIcon(
                    assetPath: 'assets/tabbar/tab_home_normal.png',
                  ),
                  activeIcon: _TabBarIcon(
                    assetPath: 'assets/tabbar/tab_home_selected.png',
                  ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _TabBarIcon(
                    assetPath: 'assets/tabbar/tab_product_normal.png',
                  ),
                  activeIcon: _TabBarIcon(
                    assetPath: 'assets/tabbar/tab_product_selected.png',
                  ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _TabBarIcon(
                    assetPath: 'assets/tabbar/tab_profile_normal.png',
                  ),
                  activeIcon: _TabBarIcon(
                    assetPath: 'assets/tabbar/tab_profile_selected.png',
                  ),
                  label: '',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBarIcon extends StatelessWidget {
  const _TabBarIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: MainTabPage._tabIconSize,
      height: MainTabPage._tabIconSize,
      fit: BoxFit.contain,
    );
  }
}

class TabRootPage extends StatelessWidget {
  const TabRootPage({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
  });

  final String title;
  final String description;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => NavigationHelper.toDetail(arguments: title),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
