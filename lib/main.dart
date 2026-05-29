import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/network/debug/network_proxy_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NetworkProxyManager.syncFromSystemProxy();
  runApp(const FunnyLoanApp());
}
