---
layout: default
title: "Handling the ad events"
nav_order: 4
---

# Monitor and process ad-related events

[Advertisement] do a lot of work under the hood and can send messages about them to the app. In turn, you can monitor and react to it in some way. In this tutorial, we’ll look at what events are handled by [Advertisement] and how we can interact with them.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/monitoring-ad-events) which has already implemented all steps from this tutorial.

## Section 1: Observing events

We will use the [AdEventListener] to observe the [AdEventType]. Since we used the [AdEventListener] in the interstitial tutorial, this time we will add it to the other `InlineAdViewModel` to observe all the [AdEventType].

### Step 1

Lets add an [AdEventListener] to the `InlineAdViewModel` and pass it to the [AdService.makeAdvertisement].

**File:** `InlineAd.kt`

```kotlin
// ...

class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    val adEventListener: AdEventListener = object : AdEventListener {
        override fun eventProcessed(adEventType: AdEventType, adMetadata: AdMetadata) {
            Log.d("InlineAdViewModel events", "Collected EVENT - $adEventType")

        }
    }

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                adEventListener = adEventListener
            ).get(
                onSuccess = {
                    aspectRatio = it.adMetadata?.aspectRatio ?: aspectRatio
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InlineAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

### Step 2

Here we can see the different [AdEventType] we can observe:
- [Impression]
- [Viewable]
- [Tap]
- [UnloadRequest]
- [RendererMessageReceived]
- [CustomTrackingEvent]

Now let us add all possible [AdEventType] to the [AdEventListener.eventProcessed] method of the `adEventListener`.

**File:** `InlineAd.kt`

```kotlin
// ...

class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    val adEventListener: AdEventListener = object : AdEventListener {
        override fun eventProcessed(adEventType: AdEventType, adMetadata: AdMetadata) {
            Log.d("InlineAdViewModel events", "Collected EVENT - $adEventType")
            when (adEventType) {
                is AdEventType.Impression -> {}
                is AdEventType.RendererMessageReceived -> {}
                is AdEventType.CustomTrackingEvent -> {}
                is AdEventType.Tap -> {}
                is AdEventType.UnloadRequest -> {}
                is AdEventType.Viewable -> {}
            }
        }
    }

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                adEventListener = adEventListener
            ).get(
                onSuccess = {
                    aspectRatio = it.adMetadata?.aspectRatio ?: aspectRatio
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InlineAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

### Step 3

We have already seen [UnloadRequest] in the interstitial example. Lets look at the [Viewable] event and monitor each [VisibilityPercentage] in this example.

**Note:** [Impression] and [Viewable] can only be observed if they are configured in the ad server backend. Otherwise they are not part of the ad response.

**File:** `InlineAd.kt`

```kotlin
// ...

class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    val adEventListener: AdEventListener = object : AdEventListener {
        override fun eventProcessed(adEventType: AdEventType, adMetadata: AdMetadata) {
            Log.d("InlineAdViewModel events", "Collected EVENT - $adEventType")
            when (adEventType) {
                is AdEventType.Impression -> {}
                is AdEventType.RendererMessageReceived -> {}
                is AdEventType.CustomTrackingEvent -> {}
                is AdEventType.Tap -> {}
                is AdEventType.UnloadRequest -> {}
                is AdEventType.Viewable -> {
                    when (adEventType.percentage) {
                        AdEventType.VisibilityPercentage.ONE -> {
                            Log.d("InlineAdViewModel events", "1% of my ads are now visible on the screen.")
                        }
                        AdEventType.VisibilityPercentage.FIFTY -> {
                            Log.d("InlineAdViewModel events", "50% of my ads are now visible on the screen.")
                        }
                        AdEventType.VisibilityPercentage.ONE_HUNDRED -> {
                            Log.d("InlineAdViewModel events", "100% of my ads are now visible on the screen.")
                        }
                    }
                }
            }
        }
    }

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                adEventListener = adEventListener
            ).get(
                onSuccess = {
                    aspectRatio = it.adMetadata?.aspectRatio ?: aspectRatio
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InlineAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

[AdService.makeAdvertisement]:sdk_core/com.adition.sdk_core.api.core/-ad-service/make-advertisement.html

[Advertisement]:sdk_core/com.adition.sdk_core.api.core/-advertisement/index.html

[AdEventListener]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-listener/index.html
[AdEventListener.eventProcessed]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-listener/event-processed.html

[AdEventType]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/index.html
[Impression]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/-impression/index.html
[RendererMessageReceived]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/-renderer-message-received/index.html
[CustomTrackingEvent]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/-custom-tracking-event/index.html
[Tap]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/-tap/index.html
[UnloadRequest]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/-unload-request/index.html
[Viewable]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/-viewable/index.html

[VisibilityPercentage]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/-visibility-percentage/index.html
