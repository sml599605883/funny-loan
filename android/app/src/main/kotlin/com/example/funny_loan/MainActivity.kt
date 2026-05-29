package com.example.funny_loan

import android.net.Proxy
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val proxyChannelName = "funny_loan/network_proxy"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            proxyChannelName,
        ).setMethodCallHandler { call, result ->
            if (call.method != "getSystemProxy") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val host = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH -> {
                    Proxy.getHost(this)
                        ?: System.getProperty("http.proxyHost")
                        ?: System.getProperty("https.proxyHost")
                        ?: ""
                }
                else -> {
                    @Suppress("DEPRECATION")
                    Proxy.getDefaultHost()
                        ?: System.getProperty("http.proxyHost")
                        ?: System.getProperty("https.proxyHost")
                        ?: ""
                }
            }
            val port = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH -> {
                    Proxy.getPort(this)
                        .takeIf { it > 0 }
                        ?: System.getProperty("http.proxyPort")?.toIntOrNull()
                        ?: System.getProperty("https.proxyPort")?.toIntOrNull()
                        ?: 0
                }
                else -> {
                    @Suppress("DEPRECATION")
                    Proxy.getDefaultPort()
                        .takeIf { it > 0 }
                        ?: System.getProperty("http.proxyPort")?.toIntOrNull()
                        ?: System.getProperty("https.proxyPort")?.toIntOrNull()
                        ?: 0
                }
            }

            if (host.isBlank() || port <= 0) {
                result.success(null)
                return@setMethodCallHandler
            }

            result.success(
                mapOf(
                    "host" to host,
                    "port" to port,
                ),
            )
        }
    }
}
