package io.harness.flutter_cfsdk

import android.app.Application
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.google.gson.JsonObject

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.harness.cfsdk.CfClient
import io.harness.cfsdk.CfConfiguration
import io.harness.cfsdk.cloud.core.model.Evaluation
import io.harness.cfsdk.cloud.model.Target
import io.harness.cfsdk.cloud.oksse.EventsListener
import io.harness.cfsdk.cloud.oksse.model.StatusEvent
import org.json.JSONArray
import org.json.JSONObject
import java.lang.Exception
import java.util.concurrent.*;

/** FfFlutterClientSdkPlugin */
class FfFlutterClientSdkPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var application: Application

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var hostChannel: MethodChannel
    private var listener: EventsListener? = null
    private val executor = Executors.newFixedThreadPool(5)
    private val handler: Handler = Handler(Looper.myLooper()!!)

    private fun postToMainThread(action: () -> Unit) {
        if (handler.looper == Looper.myLooper()) {
            action.invoke()
        } else handler.post {
            action.invoke()
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ff_flutter_client_sdk")
        hostChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "cf_flutter_host")
        application = flutterPluginBinding.applicationContext as Application
        channel.setMethodCallHandler(this)
    }

    private fun configFromMap(configMap: Map<String, Any?>): CfConfiguration.Builder {

        val builder = CfConfiguration.builder()

        if (configMap["pollingInterval"] != null) {
            builder.pollingInterval(configMap["pollingInterval"] as Int)
        }
        if (configMap["streamEnabled"] != null) {
            builder.enableStream(configMap["streamEnabled"] as Boolean)
        }
        if (configMap["configUrl"] != null) {
            builder.baseUrl(configMap["configUrl"] as String)
        }
        if (configMap["streamUrl"] != null) {
            builder.streamUrl(configMap["streamUrl"] as String)
        }
        if (configMap["eventUrl"] != null) {
            builder.eventUrl(configMap["eventUrl"] as String)
        }
        return builder
    }

    private fun invokeInitialize(@NonNull call: MethodCall, @NonNull result: Result) {

        val config: Map<String, Any>? = call.argument("configuration")
        val key: String? = call.argument("apiKey")
        val targetMap: Map<String, Any>? = call.argument("target")

        if (config != null) {

            val target = targetMap?.get("identifier") as String?

            val conf = configFromMap(config)
                .build()

            val targetInstance = Target().identifier(target)

            CfClient.getInstance().initialize(

                application,
                key,
                conf,
                targetInstance

            ) { auth, execResult ->

                postToMainThread {
                    print(auth.environment)

                    Handler(Looper.getMainLooper()).post {

                        result.success(execResult.isSuccess())
                    }
                }
            }
        }
    }

    private fun evaluationToMap(evaluation: Evaluation): Map<String, Any> {
        return mutableMapOf<String, Any>().apply {
            this["flag"] = evaluation.flag
            this["value"] = evaluation.getValue()
        }
    }

    private fun registerEventListener() {
        if (listener != null) return
        listener = EventsListener {
            when (it.eventType) {
                StatusEvent.EVENT_TYPE.SSE_START -> {
                    postToMainThread {
                        hostChannel.invokeMethod("start", null)
                    }
                }
                StatusEvent.EVENT_TYPE.SSE_END -> {
                    postToMainThread {
                        hostChannel.invokeMethod("end", null)
                    }
                }
                StatusEvent.EVENT_TYPE.EVALUATION_CHANGE -> {

                    val evaluation = it.extractPayload<Evaluation>()

                    val content = evaluationToMap(evaluation)

                    postToMainThread {
                        hostChannel.invokeMethod("evaluation_change", content)
                    }
                }
                StatusEvent.EVENT_TYPE.EVALUATION_RELOAD -> {

                    val evaluationList = it.extractPayload<List<Evaluation>>()

                    val resultList = evaluationList.map { evaluation ->
                        evaluationToMap(evaluation)
                    }

                    val content = mutableMapOf<String, Any>(Pair("evaluationData", resultList))

                    postToMainThread {
                        hostChannel.invokeMethod("evaluation_polling", content)
                    }
                }
            }
            println("internal received event ${it.eventType.name}")
        }
        CfClient.getInstance().registerEventsListener(listener)
    }


    private fun extractEvaluationArgs(call: MethodCall): Pair<String?, Any?> {
        val flag: String? = call.argument("flag")
        val defaultValue: Any? = call.argument("defaultValue")
        return Pair(flag, defaultValue)
    }

    private fun invokeStringEvaluation(@NonNull call: MethodCall): String {
        val args = extractEvaluationArgs(call)
        return CfClient.getInstance().stringVariation(args.first, args.second as String)
    }

    private fun invokeBoolEvaluation(@NonNull call: MethodCall): Boolean {
        val args = extractEvaluationArgs(call)
        return CfClient.getInstance().boolVariation(args.first, args.second as Boolean)
    }

    private fun invokeNumberEvaluation(@NonNull call: MethodCall): Number {
        val args = extractEvaluationArgs(call)
        println("extracting number argument ${args.second ?: ""}");
        val number: Number? = args.second as Number?
        return CfClient.getInstance().numberVariation(args.first, number?.toDouble() ?: 0.0)
    }

    private fun invokeDestroy() {
        listener = null
        CfClient.getInstance().destroy()
    }

    private fun invokeJsonEvaluation(@NonNull call: MethodCall): Map<String, Any?>? {

        val args = extractEvaluationArgs(call)
        return try {

            val flag = args.first!!
            val defaultValue = jsonElementFromBridge(args.second as Map<String, Any>)
            println("\nreceived on native: $defaultValue")

            val jsonObject = CfClient.getInstance().jsonVariation(args.first, defaultValue)
            mutableMapOf(Pair(flag, jsonElementToBridge(jsonObject)))

        } catch (e: Exception) {

            e.printStackTrace()
            null
        }
    }


    private fun jsonElementFromBridge(dyn: Map<String, Any>?): JSONObject {
        val jsonObj = JSONObject()
        dyn!!.forEach {
            jsonObj.put(it.key as String, jsonElementFromBridgeDecoded(it.value))
        }
        return jsonObj

    }

    private fun jsonElementFromBridgeDecoded(value: Any?): Any? {

        return when (value) {
            null -> null
            is Boolean, is Number, is String -> {
                value
            }
            is ArrayList<*> -> {
                val jsonArr = JSONArray()
                value.forEach {
                    jsonArr.put(jsonElementFromBridgeDecoded(it))
                }
                jsonArr
            }
            else -> {
                val jsonObj = JSONObject()
                (value as HashMap<*, *>).forEach {
                    jsonObj.put(it.key as String, jsonElementFromBridgeDecoded(it.value))
                }
                return jsonObj
            }
        }
    }

    private fun jsonElementToBridge(jsonElement: Any?): Any? {
        return when (jsonElement) {
            is Boolean, is Number, is String -> {
                jsonElement.toString()
            }
            is JSONArray -> {
                val res = ArrayList<Any?>()
                for (i in 0 until jsonElement.length()) {
                    res.add(jsonElementToBridge(jsonElement[i]))
                }
                res
            }
            is JSONObject -> {
                val res = HashMap<String, Any?>()
                jsonElement.keys().forEach {
                    res[it] = jsonElementToBridge(jsonElement[it])
                }
                res
            }
            else -> {
                null
            }
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

        executor.execute {

            when (call.method) {

                "initialize" -> invokeInitialize(call, result)

                "stringVariation" -> {

                    val value = invokeStringEvaluation(call)

                    Handler(Looper.getMainLooper()).post {

                        result.success(value)
                    }
                }

                "boolVariation" -> {

                    val value = invokeBoolEvaluation(call)

                    Handler(Looper.getMainLooper()).post {

                        result.success(value)
                    }
                }

                "numberVariation" -> {

                    val value = invokeNumberEvaluation(call)

                    Handler(Looper.getMainLooper()).post {

                        result.success(value)
                    }
                }

                "jsonVariation" -> {

                    val evaluation = invokeJsonEvaluation(call)
                    if (evaluation == null) {

                        result.notImplemented()

                    } else {

                        Handler(Looper.getMainLooper()).post {

                            result.success(evaluation)
                        }
                    }
                }

                "registerEventsListener" -> {

                    registerEventListener()

                    Handler(Looper.getMainLooper()).post {

                        result.success(0)
                    }
                }

                "destroy" -> {

                    invokeDestroy()

                    Handler(Looper.getMainLooper()).post {

                        result.success(0)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
