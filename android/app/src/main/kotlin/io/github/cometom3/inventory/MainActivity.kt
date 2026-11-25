package io.github.cometom3.inventory

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val channelName = "io.github.cometom3.inventory/documents"
    private val createDocumentRequest = 39121
    private val openDocumentRequest = 39122
    private var pendingPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createDocument" -> {
                        if (pendingPickerResult != null) {
                            result.error("BUSY", "A document picker is already open.", null)
                            return@setMethodCallHandler
                        }
                        val suggestedName = call.argument<String>("suggestedName")
                        val mimeType =
                            call.argument<String>("mimeType") ?: "application/octet-stream"
                        if (suggestedName.isNullOrBlank()) {
                            result.error("INVALID", "suggestedName is required.", null)
                            return@setMethodCallHandler
                        }
                        pendingPickerResult = result
                        val intent =
                            Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = mimeType
                                putExtra(Intent.EXTRA_TITLE, suggestedName)
                            }
                        startActivityForResult(intent, createDocumentRequest)
                    }

                    "openDocument" -> {
                        if (pendingPickerResult != null) {
                            result.error("BUSY", "A document picker is already open.", null)
                            return@setMethodCallHandler
                        }
                        val mimeTypes =
                            call.argument<List<String>>("mimeTypes")
                                ?: listOf("application/octet-stream", "*/*")
                        pendingPickerResult = result
                        val intent =
                            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "*/*"
                                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
                            }
                        startActivityForResult(intent, openDocumentRequest)
                    }

                    "writeDocument" -> {
                        val uriValue = call.argument<String>("uri")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (uriValue.isNullOrBlank() || bytes == null) {
                            result.error("INVALID", "uri and bytes are required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriValue)
                            contentResolver.openOutputStream(uri, "wt").use { output ->
                                if (output == null) {
                                    result.error("WRITE_FAILED", "Unable to open output stream.", null)
                                    return@setMethodCallHandler
                                }
                                output.write(bytes)
                                output.flush()
                            }
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("WRITE_FAILED", error.message, null)
                        }
                    }

                    "writeDocumentFromPath" -> {
                        val uriValue = call.argument<String>("uri")
                        val path = call.argument<String>("path")
                        if (uriValue.isNullOrBlank() || path.isNullOrBlank()) {
                            result.error("INVALID", "uri and path are required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val source = File(path)
                            if (!source.isFile) {
                                result.error("WRITE_FAILED", "Source file missing.", null)
                                return@setMethodCallHandler
                            }
                            val uri = Uri.parse(uriValue)
                            contentResolver.openOutputStream(uri, "wt").use { output ->
                                if (output == null) {
                                    result.error("WRITE_FAILED", "Unable to open output stream.", null)
                                    return@setMethodCallHandler
                                }
                                FileInputStream(source).use { input ->
                                    val chunk = ByteArray(64 * 1024)
                                    while (true) {
                                        val read = input.read(chunk)
                                        if (read < 0) break
                                        output.write(chunk, 0, read)
                                    }
                                }
                                output.flush()
                            }
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("WRITE_FAILED", error.message, null)
                        }
                    }

                    "copyDocumentToPath" -> {
                        val uriValue = call.argument<String>("uri")
                        val path = call.argument<String>("path")
                        val maxBytes =
                            call.argument<Int>("maxBytes") ?: (512 * 1024 * 1024)
                        if (uriValue.isNullOrBlank() || path.isNullOrBlank()) {
                            result.error("INVALID", "uri and path are required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriValue)
                            val target = File(path)
                            target.parentFile?.mkdirs()
                            contentResolver.openInputStream(uri).use { input ->
                                if (input == null) {
                                    result.error("UNREADABLE", "Unable to open input stream.", null)
                                    return@setMethodCallHandler
                                }
                                FileOutputStream(target).use { output ->
                                    val chunk = ByteArray(64 * 1024)
                                    var total = 0L
                                    while (true) {
                                        val read = input.read(chunk)
                                        if (read < 0) break
                                        total += read
                                        if (total > maxBytes) {
                                            result.error(
                                                "TOO_LARGE",
                                                "Document exceeds size limit.",
                                                null,
                                            )
                                            return@setMethodCallHandler
                                        }
                                        output.write(chunk, 0, read)
                                    }
                                    output.flush()
                                }
                            }
                            result.success(target.absolutePath)
                        } catch (error: IOException) {
                            result.error("UNREADABLE", error.message, null)
                        } catch (error: Exception) {
                            result.error("UNREADABLE", error.message, null)
                        }
                    }

                    "readDocument" -> {
                        val uriValue = call.argument<String>("uri")
                        if (uriValue.isNullOrBlank()) {
                            result.error("INVALID", "uri is required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriValue)
                            contentResolver.openInputStream(uri).use { input ->
                                if (input == null) {
                                    result.error("UNREADABLE", "Unable to open input stream.", null)
                                    return@setMethodCallHandler
                                }
                                result.success(input.readBytes())
                            }
                        } catch (error: IOException) {
                            result.error("UNREADABLE", error.message, null)
                        } catch (error: Exception) {
                            result.error("UNREADABLE", error.message, null)
                        }
                    }

                    "readDocumentLimited" -> {
                        val uriValue = call.argument<String>("uri")
                        val maxBytes = call.argument<Int>("maxBytes") ?: (512 * 1024 * 1024)
                        if (uriValue.isNullOrBlank()) {
                            result.error("INVALID", "uri is required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriValue)
                            contentResolver.openInputStream(uri).use { input ->
                                if (input == null) {
                                    result.error("UNREADABLE", "Unable to open input stream.", null)
                                    return@setMethodCallHandler
                                }
                                val buffer = ByteArrayOutputStream()
                                val chunk = ByteArray(8192)
                                var total = 0
                                while (true) {
                                    val read = input.read(chunk)
                                    if (read < 0) break
                                    total += read
                                    if (total > maxBytes) {
                                        result.error("TOO_LARGE", "Document exceeds size limit.", null)
                                        return@setMethodCallHandler
                                    }
                                    buffer.write(chunk, 0, read)
                                }
                                result.success(buffer.toByteArray())
                            }
                        } catch (error: IOException) {
                            result.error("UNREADABLE", error.message, null)
                        } catch (error: Exception) {
                            result.error("UNREADABLE", error.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != createDocumentRequest && requestCode != openDocumentRequest) {
            return
        }
        val pending = pendingPickerResult
        pendingPickerResult = null
        if (pending == null) return
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pending.success(null)
        } else {
            pending.success(data.data.toString())
        }
    }
}
