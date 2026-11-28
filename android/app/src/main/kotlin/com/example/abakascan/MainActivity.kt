package com.example.abakascan

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val completionNotifier by lazy { CompletionNotifier(this) }
    private val worker = Executors.newSingleThreadExecutor()
    private val engine by lazy { OfflineEngine(applicationContext) }
    private val store by lazy { OfflineStore(applicationContext) }
    @Volatile private var owner: String? = null
    private var unlockResult: MethodChannel.Result? = null
    private var pendingOwner: String? = null
    private var cancellation: CancellationSignal? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"abakascan/completion_notifications").setMethodCallHandler { call, result ->
            when (call.method) {
                "prepare" -> completionNotifier.prepare(result)
                "done" -> { completionNotifier.show(); result.success(null) }
                "setAnalyzeVisible" -> {
                    completionNotifier.analyzeVisible = call.argument<Boolean>("visible") == true
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"abakascan/offline_v3").setMethodCallHandler { call, result ->
            if (call.method == "unlock") {
                val key = call.argument<String>("owner")
                if (key.isNullOrBlank()) result.error("invalid_account","Log in online first.",null)
                else unlock(key,result)
            } else if (call.method == "lock") {
                owner = null; result.success(null)
            } else {
                val account = owner
                if (account == null) { result.error("locked","Unlock this phone to continue.",null); return@setMethodCallHandler }
                worker.execute {
                    try {
                        // A classification is authorized when submitted, with its owner captured.
                        // Let that job finish if the phone locks; other reads stay locked.
                        if (call.method != "classify") check(owner == account) { "The workspace was locked." }
                        val response: Any? = when (call.method) {
                            "selfTest" -> engine.selfTest()
                            "history" -> store.history(account)
                            "get" -> store.get(account,call.argument<String>("id")!!)
                            "image" -> store.image(account,call.argument<String>("id")!!,call.argument<Boolean>("full") == true)
                            "delete" -> { store.delete(account,call.argument<String>("id")!!); null }
                            "classify" -> {
                                val bytes = call.argument<ByteArray>("bytes") ?: error("Select an image first.")
                                val (prediction,thumb) = engine.classify(bytes)
                                if (prediction["saved_to_history"] == true) store.save(account,prediction,bytes,thumb) else prediction
                            }
                            else -> error("Unsupported offline operation.")
                        }
                        if (call.method == "classify") completionNotifier.show(workspaceVisible = owner == account)
                        runOnUiThread {
                            if (owner == account || call.method == "classify") result.success(response)
                            else result.error("locked","The workspace was locked. Unlock and try again.",null)
                        }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("offline_error", e.message ?: "Offline operation failed.",null) }
                    } catch (_: OutOfMemoryError) {
                        runOnUiThread { result.error("image_too_large","Not enough memory. Select a smaller image and try again.",null) }
                    }
                }
            }
        }
    }
    private fun finishUnlock(success: Boolean, message: String = "Unlock cancelled. Try again.") {
        val result = unlockResult ?: return
        if (success) owner = pendingOwner
        else owner = null
        unlockResult = null;pendingOwner = null;cancellation = null
        if (success) result.success(true) else result.error("unlock_cancelled",message,null)
    }
    @Suppress("DEPRECATION")
    private fun unlock(key: String, result: MethodChannel.Result) {
        if (unlockResult != null) { result.error("unlock_busy","An unlock request is already open.",null);return }
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (!keyguard.isDeviceSecure) {
            result.error("screen_lock_required","Set a PIN, pattern, or password in your phone's lock-screen settings, then try again.",null);return
        }
        unlockResult = result;pendingOwner = key
        try {
            if (Build.VERSION.SDK_INT >= 30) {
                cancellation = CancellationSignal()
                BiometricPrompt.Builder(this)
                    .setTitle("Unlock AbakaScan")
                    .setSubtitle("Access analyses saved on this phone")
                    .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)
                    .build().authenticate(cancellation!!,mainExecutor,object: BiometricPrompt.AuthenticationCallback() {
                        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) { finishUnlock(true) }
                        override fun onAuthenticationError(code: Int, message: CharSequence) { finishUnlock(false,message.toString()) }
                    })
            } else {
                val intent = keyguard.createConfirmDeviceCredentialIntent("Unlock AbakaScan","Access analyses saved on this phone")
                    ?: error("Phone screen lock is unavailable.")
                startActivityForResult(intent,4102)
            }
        } catch (e: Exception) { finishUnlock(false,e.message ?: "Unable to unlock.") }
    }
    @Deprecated("Legacy screen-lock fallback for Android 7–10")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode,resultCode,data)
        if (requestCode == 4102) finishUnlock(resultCode == RESULT_OK)
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        completionNotifier.permissionResult(requestCode, grantResults)
    }
    override fun onResume() {
        super.onResume()
        completionNotifier.foreground = true
    }
    override fun onPause() {
        completionNotifier.foreground = false
        super.onPause()
    }
    override fun onDestroy() {
        completionNotifier.dispose()
        cancellation?.cancel()
        finishUnlock(false)
        owner = null
        worker.shutdown()
        // No new work after shutdown; sessions and SQLite are process-owned.
        super.onDestroy()
    }
}
