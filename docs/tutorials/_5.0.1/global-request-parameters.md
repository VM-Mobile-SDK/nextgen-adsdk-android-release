---
layout: default
title: "Global request parameters"
nav_order: 6
---

# Global request parameters

We already know how to create and perform [AdRequest], [TagRequest], and [TrackingRequest]. However, each of them can have additional parameters, which are called global parameters because they are specified globally for all requests. The SDK provides the ability to add global parameters once so that you don’t have to copy them when creating each request.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/global-parameters) which has already implemented all steps from this tutorial.

## Modifying global parameters

In this section we'll configure the [AdRequestGlobalParameters] and [TrackingGlobalParameters] for each [AdRequest], [TagRequest], and [TrackingRequest] we have in our application. We will also look at the possibility of removing global parameters.

### Step 1

We can add global parameters using the [AdService]. The [AdService] has a [AdService.setAdRequestGlobalParameter] method which we will use to set the [gdpr parameter] for each [AdRequest].

Add the global parameters to the `App` class and a function `addGlobalParameters()`.

**Note:** If we want to remove a ad request global parameter we could use the [AdService.removeAdRequestGlobalParameter] method.

**File:** `App.kt`

```kotlin
class App: Application() {
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    val adServiceStatus = MutableLiveData<ResultState<Unit>>()

    override fun onCreate() {
        super.onCreate()

        coroutineScope.launch {
            val initResult = AdService.configure("1800", applicationContext)

            initResult.get(
                onSuccess =  {
                    addGlobalParameters()
                    adServiceStatus.postValue(ResultState.Success(Unit))
                },
                onError = {
                    adServiceStatus.postValue(ResultState.Error(it))
                }
            )
        }
    }

    private fun addGlobalParameters() {
        val gdpr = GDPR(consent = "gdprconsentexample", isRulesEnabled = true)

        AdService.setAdRequestGlobalParameter(AdRequestGlobalParameters::gdpr, gdpr)
        // AdService.removeAdRequestGlobalParameter(AdRequestGlobalParameters::gdpr)
    }
}
```

### Step 2

We can also modify [TrackingGlobalParameters] for each [TagRequest] and [TrackingRequest] using the [AdService.setTrackingGlobalParameter] method. Let's add this code to the `addGlobalParameters` method.

**Note:** If we want to remove a tracking global parameter we could use the [AdService.removeTrackingGlobalParameter] method.

**File:** `App.kt`

```kotlin
class App: Application() {
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    val adServiceStatus = MutableLiveData<ResultState<Unit>>()

    override fun onCreate() {
        super.onCreate()

        coroutineScope.launch {
            val initResult = AdService.configure("1800", applicationContext)

            initResult.get(
                onSuccess =  {
                    addGlobalParameters()
                    adServiceStatus.postValue(ResultState.Success(Unit))
                },
                onError = {
                    adServiceStatus.postValue(ResultState.Error(it))
                }
            )
        }
    }

    private fun addGlobalParameters() {
        val gdpr = GDPR(consent = "gdprconsentexample", isRulesEnabled = true)

        AdService.setAdRequestGlobalParameter(AdRequestGlobalParameters::gdpr, gdpr)
        // AdService.removeAdRequestGlobalParameter(AdRequestGlobalParameters::gdpr)

        AdService.setTrackingGlobalParameter(TrackingGlobalParameters::gdpr, gdpr)
        // AdService.removeTrackingGlobalParameter(TrackingGlobalParameters::gdpr)
    }
}
```

[gdpr parameter]:sdk_core/com.adition.sdk_core.api.entities.request/-g-d-p-r/index.html

[AdService]:sdk_core/com.adition.sdk_core.api.core/-ad-service/index.html
[AdService.setAdRequestGlobalParameter]:sdk_core/com.adition.sdk_core.api.core/-ad-service/set-ad-request-global-parameter.html
[AdService.removeAdRequestGlobalParameter]:sdk_core/com.adition.sdk_core.api.core/-ad-service/remove-ad-request-global-parameter.html
[AdService.setTrackingGlobalParameter]:sdk_core/com.adition.sdk_core.api.core/-ad-service/set-tracking-global-parameter.html
[AdService.removeTrackingGlobalParameter]:sdk_core/com.adition.sdk_core.api.core/-ad-service/remove-tracking-global-parameter.html

[AdRequest]:sdk_core/com.adition.sdk_core.api.entities.request/-ad-request/index.html

[TagRequest]:sdk_core/com.adition.sdk_core.api.entities.request/-tag-request/index.html

[TrackingRequest]:sdk_core/com.adition.sdk_core.api.entities.request/-tracking-request/index.html

[AdRequestGlobalParameters]:sdk_core/com.adition.sdk_core.api.entities.request/-ad-request-global-parameters/index.html

[TrackingGlobalParameters]:sdk_core/com.adition.sdk_core.api.entities.request/-tracking-global-parameters/index.html
