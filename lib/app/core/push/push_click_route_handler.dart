import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../routes/api_navigation_helper.dart';
import '../json/json.dart';
import '../native/native_bridge.dart';

typedef PushRouteEventStream = Stream<Json> Function();
typedef PushRouteReadyCheck = bool Function();
typedef PushRouteOpener = Future<void> Function(String rawUrl);
typedef PushRouteRetryScheduler = void Function(VoidCallback retry);

class PushClickRouteHandler {
  PushClickRouteHandler({
    PushRouteEventStream? nativeEvents,
    PushRouteReadyCheck? isNavigationReady,
    PushRouteOpener? openRoute,
    PushRouteRetryScheduler? scheduleRetry,
  }) : _nativeEvents = nativeEvents ?? NativeBridge.nativeEvents,
       _isNavigationReady = isNavigationReady ?? _defaultNavigationReady,
       _openRoute = openRoute ?? ApiNavigationHelper.navigateRawTarget,
       _scheduleRetry = scheduleRetry ?? _defaultScheduleRetry;

  static final PushClickRouteHandler instance = PushClickRouteHandler();

  final PushRouteEventStream _nativeEvents;
  final PushRouteReadyCheck _isNavigationReady;
  final PushRouteOpener _openRoute;
  final PushRouteRetryScheduler _scheduleRetry;
  final List<String> _pendingRoutes = <String>[];

  StreamSubscription<Json>? _nativeEventSubscription;
  bool _retryScheduled = false;
  bool _isHandlingRoute = false;

  void bind() {
    _nativeEventSubscription ??= _nativeEvents().listen((event) {
      if (event['type'].stringValue != 'push_route') {
        return;
      }
      _enqueue(event['url'].stringValue);
    });
    unawaited(_flushPendingRoutesIfPossible());
  }

  @visibleForTesting
  void enqueueForTest(String url) {
    _enqueue(url, flush: false);
  }

  @visibleForTesting
  int get pendingRouteCount => _pendingRoutes.length;

  @visibleForTesting
  Future<void> flushPendingRoutesForTest() => _flushPendingRoutesIfPossible();

  Future<void> dispose() async {
    await _nativeEventSubscription?.cancel();
    _nativeEventSubscription = null;
    _pendingRoutes.clear();
    _retryScheduled = false;
    _isHandlingRoute = false;
  }

  void _enqueue(String rawUrl, {bool flush = true}) {
    final url = rawUrl.trim();
    if (url.isEmpty) {
      return;
    }
    _pendingRoutes.add(url);
    if (flush) {
      unawaited(_flushPendingRoutesIfPossible());
    }
  }

  Future<void> _flushPendingRoutesIfPossible() async {
    if (_isHandlingRoute) {
      return;
    }
    if (!_isNavigationReady()) {
      _scheduleFlushRetry();
      return;
    }

    _isHandlingRoute = true;
    try {
      while (_pendingRoutes.isNotEmpty && _isNavigationReady()) {
        final url = _pendingRoutes.removeAt(0);
        await _openRoute(url);
      }
      if (_pendingRoutes.isNotEmpty) {
        _scheduleFlushRetry();
      }
    } finally {
      _isHandlingRoute = false;
    }
  }

  void _scheduleFlushRetry() {
    if (_retryScheduled) {
      return;
    }
    _retryScheduled = true;
    _scheduleRetry(() {
      _retryScheduled = false;
      unawaited(_flushPendingRoutesIfPossible());
    });
  }

  static bool _defaultNavigationReady() {
    final context = Get.context;
    return context != null && context.mounted;
  }

  static void _defaultScheduleRetry(VoidCallback retry) {
    WidgetsBinding.instance.addPostFrameCallback((_) => retry());
  }
}
