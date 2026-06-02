import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/core/storage/app_data_store.dart';
import 'app/network/debug/network_proxy_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDataStore.init();
  await NetworkProxyManager.syncFromSystemProxy();
  runApp(const FunnyLoanApp());
}
