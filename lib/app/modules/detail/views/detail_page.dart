import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String sourceTitle = Get.arguments as String? ?? '详情';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('$sourceTitle详情')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '当前页面通过 GetX 命名路由 push 进入，iOS 左侧滑动返回已全局禁用。',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
