import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/json/json.dart';
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

  InAppWebViewController? _controller;
  late final WebViewBridgeDispatcher _dispatcher =
      widget._bridgeDispatcher ?? WebViewBridgeDispatcher();
  bool _appForeground = true;
  bool _bridgeEnabled = false;
  bool _isLoading = true;
  bool _routeActive = true;
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
                        _syncJsBridgeState();
                      },
                      onLoadStart: (controller, url) {
                        if (mounted) {
                          setState(() => _isLoading = true);
                        }
                      },
                      onLoadStop: (controller, url) async {
                        await _syncTitleFromWebPage();
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                      onReceivedError: (controller, request, error) {},
                      onReceivedHttpError: (controller, request, response) {},
                      onConsoleMessage: (controller, consoleMessage) {},
                      onTitleChanged: (controller, title) {
                        final normalized = title?.trim() ?? '';
                        if (!mounted || normalized.isEmpty) {
                          return;
                        }
                        setState(() => _title = normalized);
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
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }
    if (mounted) {
      NavigationHelper.back<void>();
    }
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
}
