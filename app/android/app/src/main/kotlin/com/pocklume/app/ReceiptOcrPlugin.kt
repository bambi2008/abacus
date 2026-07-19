package com.pocklume.app

import android.graphics.BitmapFactory
import androidx.annotation.NonNull
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * On-device receipt text recognition via Google ML Kit — the Android
 * counterpart to ios/Runner/ReceiptOcrPlugin.swift's Vision framework
 * plugin. Same method channel name and result shape ({"lines": [...]})
 * so the Dart side (receipt_ocr_service.dart) needs no platform branching.
 * Recognition runs on-device; the photo is never uploaded anywhere.
 */
class ReceiptOcrPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.pocklume.app/receipt_ocr")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        recognizer.close()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "recognizeText" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "Missing 'path'", null)
                    return
                }
                recognizeText(path, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun recognizeText(path: String, result: Result) {
        val bitmap = BitmapFactory.decodeFile(path)
        if (bitmap == null) {
            result.error("bad_image", "Could not load image at $path", null)
            return
        }
        val image = InputImage.fromBitmap(bitmap, 0)
        recognizer.process(image)
            .addOnSuccessListener { visionText ->
                val lines = visionText.textBlocks.flatMap { block -> block.lines.map { it.text } }
                result.success(mapOf("lines" to lines))
            }
            .addOnFailureListener { e ->
                result.error("recognition_failed", e.localizedMessage, null)
            }
    }
}
