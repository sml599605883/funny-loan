import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CertificationStepPage extends StatelessWidget {
  const CertificationStepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments;
    final routeKey = arguments is Map
        ? (arguments['routeKey'] as String? ?? '')
        : '';
    final payload = arguments is Map ? arguments['payload'] : null;
    final title = payload is Map
        ? (payload['nextStepTitle'] as String? ?? '').trim()
        : '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title.isNotEmpty ? title : routeKey),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '当前认证步骤路由: ${routeKey.isEmpty ? 'unknown' : routeKey}',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
