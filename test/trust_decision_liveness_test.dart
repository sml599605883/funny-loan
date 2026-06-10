import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funny_loan/app/core/native/native_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('funny_loan/native_bridge');
  final calls = <MethodCall>[];

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    calls.clear();
  });

  test('showLiveness returns successful result map from native side', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return <String, dynamic>{
            'success': true,
            'code': 0,
            'message': 'ok',
            'image': 'image-base64',
            'sequence_id': 'seq-1',
            'liveness_id': 'live-1',
            'raw': <String, dynamic>{
              'code': 0,
              'message': 'ok',
              'image': 'image-base64',
              'sequence_id': 'seq-1',
              'liveness_id': 'live-1',
            },
          };
        });

    final result = await NativeBridge.showTrustDecisionLiveness('td-token');

    expect(calls, hasLength(1));
    expect(calls.single.method, 'showTrustDecisionLiveness');
    expect(calls.single.arguments, 'td-token');
    expect(result.success, isTrue);
    expect(result.code, 0);
    expect(result.message, 'ok');
    expect(result.image, 'image-base64');
    expect(result.sequenceId, 'seq-1');
    expect(result.livenessId, 'live-1');
    expect(result.raw, <String, dynamic>{
      'code': 0,
      'message': 'ok',
      'image': 'image-base64',
      'sequence_id': 'seq-1',
      'liveness_id': 'live-1',
    });
  });

  test('showLiveness falls back to failure when native result is empty', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });

    final result = await NativeBridge.showTrustDecisionLiveness('td-token');

    expect(result.success, isFalse);
    expect(result.code, -1);
    expect(result.message, 'Liveness returned no result');
    expect(result.image, '');
    expect(result.sequenceId, '');
    expect(result.livenessId, '');
    expect(result.raw, isEmpty);
  });
}
