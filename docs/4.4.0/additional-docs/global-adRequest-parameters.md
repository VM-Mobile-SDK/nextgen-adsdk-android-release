---
layout: default
title: "4. Global ad request parameters"
---

# Global ad request parameters
An ad request can have additional parameters beyond those you pass during initialization. 
These additional parameters are global for all ad requests.
The SDK provides the ability to add global parameters once so that you don’t have to copy them when creating each ad request.

## Section 1: Modifying global parameters

In this section, we’ll configure the [gdpr parameter](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core.internal.entities/-g-d-p-r/index.html) for each ad request that we have in our app. 
In addition, we will review the possibility of removing global parameters.
You can configure not only GDPR but also other parameters. You can find a list of all global parameters in the [AdRequestGlobalParameters](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core.internal.entities/-ad-request-global-parameters/index.html) documentation.

### Step 1
We can add global parameters via the [AdService](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core/-ad-service/index.html). 
The [AdService](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core/-ad-service/index.html) has [setAdRequestGlobalParameter](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core/-ad-service/set-ad-request-global-parameter.html) method which we use to set the [gdpr parameter](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core.internal.entities/-g-d-p-r/index.html).
```kotlin
AdService.getInstance().setAdRequestGlobalParameter(
    AdRequestGlobalParameters::gdpr,
    GDPR(consent = "gdprconsentexample", isRulesEnabled = true)
)
```

### Step 2
To make it easy we will add the global parameters in the App class.
```kotlin 
class App : Application() {
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    override fun onCreate() {
        super.onCreate()

        coroutineScope.launch {
            val isSuccess = AdService.init("1800", applicationContext, EventHandler())
            Log.d("App", "Init is success: $isSuccess")

            launch {
                AdService.getInstance().eventHandler?.events?.collect { event ->
                    Log.d("Events", "Collected EVENT - $event")
                    when (event.eventType) {
                        is EventType.Tap -> {
                            // Ad got tapped.
                        }
                        else -> {}
                    }
                }
            }

            launch {
                AdService.getInstance().setAdRequestGlobalParameter(
                    AdRequestGlobalParameters::gdpr,
                    GDPR(consent = "gdprconsentexample", isRulesEnabled = true)
                )
            }
        }
    }

    override fun onTerminate() {
        super.onTerminate()
        coroutineScope.cancel()
    }
}
```

### Step 3
If we want to remove an global parameter we could use the [removeAdRequestGlobalParameter](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core/-ad-service/remove-ad-request-global-parameter.html) method.
```kotlin 
AdService.getInstance().removeAdRequestGlobalParameter(
    AdRequestGlobalParameters::gdpr
)
```