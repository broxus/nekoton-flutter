package com.broxus.nekoton_flutter

import android.content.Context
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class NekotonFlutterPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nekoton_native_library")
        channel!!.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method.equals("getNativeLibraryDir")) {
            val info = context!!.applicationInfo
            if (info != null) {
                result.success(info.nativeLibraryDir)
            } else {
                result.success(null)
            }
        } else if (call.method.equals("loadLibrary")) {
            try {
                System.loadLibrary(call.arguments as String)
                result.success(null)
            } catch (e: Throwable) {
                result.error("1", "could not load: $e", null)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
    }
}
