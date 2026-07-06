import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/json/json.dart';
import '../../../core/widgets/retention_popup.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../webview_bridge_dispatcher.dart';

class FunnyLoanWebViewPage extends StatefulWidget {
  const FunnyLoanWebViewPage({
    super.key,
    this.initialUrl = '',
    this.initialTitle = '',
    WebViewBridgeDispatcher? bridgeDispatcher,
  }) : _bridgeDispatcher = bridgeDispatcher;

  final String initialUrl;
  final String initialTitle;
  final WebViewBridgeDispatcher? _bridgeDispatcher;

  @override
  State<FunnyLoanWebViewPage> createState() => _FunnyLoanWebViewPageState();
}

class _FunnyLoanWebViewPageState extends State<FunnyLoanWebViewPage>
    with WidgetsBindingObserver {
  static const String _bridgeHandlerName = 'ph_funny_loan_ios';
  static const String _historyConsolePrefix = '[FunnyLoanWebViewHistory]';
  static final UnmodifiableListView<UserScript> _debugHistoryScripts =
      UnmodifiableListView<UserScript>(<UserScript>[
        UserScript(
          source:
              '''
(function() {
  if (window.__funnyLoanHistoryProbeInstalled) {
    return;
  }
  window.__funnyLoanHistoryProbeInstalled = true;
  const log = function(type, args) {
    try {
      const target = args && args.length > 2 ? args[2] : null;
      console.log('$_historyConsolePrefix ' + type + ' from=' + location.href + ' target=' + target);
    } catch (error) {
      console.log('$_historyConsolePrefix log-error ' + error);
    }
  };
  const rawPushState = history.pushState;
  const rawReplaceState = history.replaceState;
  history.pushState = function() {
    log('pushState', arguments);
    return rawPushState.apply(this, arguments);
  };
  history.replaceState = function() {
    log('replaceState', arguments);
    return rawReplaceState.apply(this, arguments);
  };
  window.addEventListener('popstate', function() {
    console.log('$_historyConsolePrefix popstate url=' + location.href);
  });
})();
''',
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]);

  InAppWebViewController? _controller;
  late final WebViewBridgeDispatcher _dispatcher =
      widget._bridgeDispatcher ?? WebViewBridgeDispatcher();
  bool _appForeground = true;
  bool _backInFlight = false;
  bool _bridgeEnabled = false;
  bool _isLoading = true;
  bool _routeActive = true;
  int _backPressSerial = 0;
  String _title = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _title = 'Loading...';
  }

  @override
  void dispose() {
    _routeActive = false;
    _appForeground = false;
    _syncJsBridgeState();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appForeground = state == AppLifecycleState.resumed;
    _syncJsBridgeState();
  }

  @override
  Widget build(BuildContext context) {
    _routeActive = ModalRoute.of(context)?.isCurrent ?? true;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.certificationUploadBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppPageHeader(title: _title, onBack: _handleBackPressed),
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri.uri(Uri.parse(widget.initialUrl)),
                      ),
                      initialUserScripts: kDebugMode
                          ? _debugHistoryScripts
                          : null,
                      initialSettings: InAppWebViewSettings(
                        allowsInlineMediaPlayback: true,
                        javaScriptEnabled: true,
                        mediaPlaybackRequiresUserGesture: false,
                        mixedContentMode:
                            MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                        useShouldOverrideUrlLoading: true,
                        isInspectable: true,
                      ),
                      onWebViewCreated: (controller) {
                        _controller = controller;
                        _debugLog('created initialUrl=${widget.initialUrl}');
                        _syncJsBridgeState();
                      },
                      onLoadStart: (controller, url) {
                        _debugLog('loadStart url=$url');
                        if (mounted) {
                          setState(() => _isLoading = true);
                        }
                      },
                      onLoadStop: (controller, url) async {
                        _debugLog('loadStop url=$url');
                        await _debugDumpWebHistory('loadStop');
                        await _syncTitleFromWebPage();
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                      onReceivedError: (controller, request, error) {
                        _debugLog(
                          'receivedError url=${request.url} '
                          'code=${error.type} description=${error.description}',
                        );
                      },
                      onReceivedHttpError: (controller, request, response) {
                        _debugLog(
                          'receivedHttpError url=${request.url} '
                          'status=${response.statusCode}',
                        );
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        final message = consoleMessage.message;
                        if (message.contains(_historyConsolePrefix)) {
                          _debugLog('console $message');
                        }
                      },
                      onTitleChanged: (controller, title) {
                        final normalized = title?.trim() ?? '';
                        if (!mounted || normalized.isEmpty) {
                          return;
                        }
                        setState(() => _title = normalized);
                      },
                      onUpdateVisitedHistory: (controller, url, isReload) {
                        _debugLog(
                          'updateVisitedHistory url=$url isReload=$isReload',
                        );
                        unawaited(_debugDumpWebHistory('visitedHistory'));
                      },
                      onReceivedServerTrustAuthRequest:
                          (controller, challenge) async {
                            return ServerTrustAuthResponse(
                              action: ServerTrustAuthResponseAction.PROCEED,
                            );
                          },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                            final uri = navigationAction.request.url;
                            _debugLog(
                              'shouldOverride url=$uri '
                              'navType=${navigationAction.navigationType} '
                              'isRedirect=${navigationAction.isRedirect}',
                            );
                            if (uri == null) {
                              return NavigationActionPolicy.ALLOW;
                            }
                            const allowedSchemes = <String>{
                              'http',
                              'https',
                              'file',
                              'chrome',
                              'data',
                              'javascript',
                              'about',
                            };
                            if (!allowedSchemes.contains(uri.scheme)) {
                              _debugLog('externalScheme cancel url=$uri');
                              await launchUrl(uri);
                              return NavigationActionPolicy.CANCEL;
                            }
                            return NavigationActionPolicy.ALLOW;
                          },
                    ),
                    if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackPressed() async {
    final serial = ++_backPressSerial;
    if (_backInFlight) {
      _debugLog('back#$serial entered while another back is in flight');
    }
    _backInFlight = true;
    final controller = _controller;
    final canGoBack = controller != null && await controller.canGoBack();
    Future<void> defaultBack() async {
      if (canGoBack) {
        await _goBackOneHistoryEntry(controller, serial);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return;
      }
      if (mounted) {
        _debugLog('back#$serial Flutter route back');
        NavigationHelper.back<void>();
      }
    }

    try {
      final currentUrl =
          (await controller?.getUrl())?.toString().trim() ??
          widget.initialUrl.trim();
      _debugLog('back#$serial currentUrl=$currentUrl canGoBack=$canGoBack');
      final productId = WebViewOperateRetention.productIdFromUrl(currentUrl);
      if (productId.isNotEmpty) {
        _debugLog('back#$serial retention productId=$productId');
        final shown = await RetentionPopup.show(
          type: WebViewOperateRetention.type,
          productId: productId,
          onLeftTap: () {
            _debugLog('back#$serial retention left tap');
            unawaited(defaultBack());
          },
        );
        _debugLog('back#$serial retention shown=$shown');
        if (shown) {
          return;
        }
      }
      await defaultBack();
    } finally {
      _backInFlight = false;
    }
  }

  Future<void> _goBackOneHistoryEntry(
    InAppWebViewController controller,
    int serial,
  ) async {
    await _debugDumpWebHistory('back#$serial before goBack');
    final history = await controller.getCopyBackForwardList();
    if (WebViewBackHistory.shouldUsePageHistoryGo(history)) {
      _debugLog('back#$serial page history.go(-1)');
      await controller.evaluateJavascript(source: 'window.history.go(-1);');
    } else {
      _debugLog('back#$serial native goBack');
      await controller.goBack();
    }
    await _debugDumpWebHistory('back#$serial after goBack');
  }

  void _syncJsBridgeState() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final shouldEnable = _routeActive && _appForeground;
    if (shouldEnable == _bridgeEnabled) {
      return;
    }
    if (shouldEnable) {
      controller.addJavaScriptHandler(
        handlerName: _bridgeHandlerName,
        callback: _handleJsBridgeCall,
      );
      _bridgeEnabled = true;
      return;
    }
    controller.removeJavaScriptHandler(handlerName: _bridgeHandlerName);
    _bridgeEnabled = false;
  }

  Future<dynamic> _handleJsBridgeCall(List<dynamic> arguments) async {
    if (!_routeActive || !_appForeground || !mounted) {
      return <String, dynamic>{'ignored': true};
    }
    final raw = arguments.isNotEmpty ? arguments.first : null;
    final request = WebViewBridgeRequest.fromMessage(raw);
    final result = await _dispatcher.dispatch(request);
    if (!mounted || !_routeActive || !_appForeground || !result.success) {
      return null;
    }
    final callback = result.callback?.trim() ?? '';
    if (callback.isEmpty || result.callbackData.isEmpty) {
      return null;
    }

    final jsonStr = Json(<String, dynamic>{
      'callbackId': callback,
      'data': result.callbackData,
    }).rawString();
    await _controller?.evaluateJavascript(
      source: 'window.$_bridgeHandlerName.handleMessage($jsonStr);',
    );
    return null;
  }

  Future<void> _syncTitleFromWebPage() async {
    final title = (await _controller?.getTitle())?.trim() ?? '';
    if (!mounted || title.isEmpty) {
      return;
    }
    setState(() => _title = title);
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[FunnyLoanWebView] $message');
    }
  }

  Future<void> _debugDumpWebHistory(String stage) {
    if (!kDebugMode) {
      return Future<void>.value();
    }
    return _debugDumpWebHistoryInternal(stage);
  }

  Future<void> _debugDumpWebHistoryInternal(String stage) async {
    final controller = _controller;
    if (controller == null) {
      _debugLog('$stage history controller=null');
      return;
    }
    final url = await controller.getUrl();
    final canGoBack = await controller.canGoBack();
    final canGoForward = await controller.canGoForward();
    final history = await controller.getCopyBackForwardList();
    final items = history?.list ?? const <WebHistoryItem>[];
    final historyText = items
        .map((item) {
          final marker = item.index == history?.currentIndex ? '*' : '';
          return '$marker${item.index}:${item.url}';
        })
        .join(' <= ');
    _debugLog(
      '$stage history url=$url canGoBack=$canGoBack '
      'canGoForward=$canGoForward currentIndex=${history?.currentIndex} '
      'size=${items.length} stack=$historyText',
    );
  }
}

class WebViewOperateRetention {
  WebViewOperateRetention._();

  static const String type = '5';

  static String productIdFromUrl(String rawUrl) {
    final url = rawUrl.trim();
    if (!url.contains('Operate')) {
      return '';
    }
    final uri = Uri.tryParse(url);
    final productId = _queryValue(uri, 'skoals');
    if (productId.isNotEmpty) {
      return productId;
    }
    final fragmentUri = Uri.tryParse(uri?.fragment ?? '');
    final fragmentProductId = _queryValue(fragmentUri, 'skoals');
    if (fragmentProductId.isNotEmpty) {
      return fragmentProductId;
    }
    return RegExp(
          r'(?:[?&#]|^)skoals=([^&#]+)',
        ).firstMatch(url)?.group(1)?.trim() ??
        '';
  }

  static String _queryValue(Uri? uri, String key) {
    return uri?.queryParameters[key]?.trim() ?? '';
  }
}

class WebViewBackHistory {
  WebViewBackHistory._();

  static bool shouldUsePageHistoryGo(WebHistory? history) {
    final currentItem = _currentItem(history);
    final previousItem = _previousItem(history);
    if (currentItem == null || previousItem == null) {
      return false;
    }
    final currentUri = Uri.tryParse(currentItem.url?.toString() ?? '');
    final previousUri = Uri.tryParse(previousItem.url?.toString() ?? '');
    if (currentUri == null || previousUri == null) {
      return false;
    }
    return currentUri.fragment.isNotEmpty &&
        previousUri.fragment.isNotEmpty &&
        currentUri.removeFragment() == previousUri.removeFragment();
  }

  static WebHistoryItem? previousItem(WebHistory? history) {
    return _previousItem(history);
  }

  static WebHistoryItem? _currentItem(WebHistory? history) {
    final currentIndex = history?.currentIndex;
    final items = history?.list;
    if (currentIndex == null || items == null || currentIndex < 0) {
      return null;
    }
    if (currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex];
  }

  static WebHistoryItem? _previousItem(WebHistory? history) {
    final currentIndex = history?.currentIndex;
    final items = history?.list;
    if (currentIndex == null || items == null || currentIndex <= 0) {
      return null;
    }
    if (currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex - 1];
  }
}
