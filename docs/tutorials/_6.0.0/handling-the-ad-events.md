---
layout: default
title: "Handling the ad events"
nav_order: 4
---

# Monitor and process ad-related events

[Advertisement] do a lot of work under the hood and can send messages about them to the app. In turn, you can monitor and react to it in some way. In this tutorial, we’ll look at what events are handled by [Advertisement] and how we can interact with them.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/monitoring-ad-events) which has already implemented all steps from this tutorial.

## Section 1: Monitoring of ad-related events

In this section, we’ll look at how you can know when and what kind of event happened.

### Step 1

Let’s open `AdItem.kt`, and pay attention to the parameters of the [AdService.makeAdvertisement] method.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...

    suspend fun loadAdvertisement() {
        _state.value = PresentationState.Loading

        adService
            .makeAdvertisement(
                adRequest = request,
                placementType  = AdPlacementType.INLINE, // Inline by default
                targetURLHandler = null, // Can be skipped
                adEventListener = null // Can be skipped
            )
            .map { ItemData(it, it.getMetadata()?.aspectRatio) }
            .get(
                onSuccess = { data ->
                    advertisement = data.advertisement
                    _state.value = PresentationState.Loaded(data)
                },
                onError = { error ->
                    _state.value = PresentationState.Error(error.description)
                }
            )
    }
    // ...
}
// ...
```

### Step 2

To monitor and interact with any ad event, we should implement [AdEventListener] and pass it when creating an [Advertisement].

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...

    suspend fun loadAdvertisement() {
        _state.value = PresentationState.Loading

        adService
            .makeAdvertisement(
                adRequest = request,
                placementType  = AdPlacementType.INLINE, // Inline by default
                targetURLHandler = null, // Can be skipped
                adEventListener = eventListener
            )
            .map { ItemData(it, it.getMetadata()?.aspectRatio) }
            .get(
                onSuccess = { data ->
                    advertisement = data.advertisement
                    _state.value = PresentationState.Loaded(data)
                },
                onError = { error ->
                    _state.value = PresentationState.Error(error.description)
                }
            )
    }
    // ...

    private val eventListener = object : AdEventListener {
        
    }
}
// ...
```

Now we’re ready to get started with various advertising-related events!

## Section 2: Request to unload or hide ad

In this section, we’ll look at how an [Advertisement] can signal to unload or hide the ad.

### Step 1

To monitor the moment when an ad wants to be removed or hidden, you can implement [AdEventListener.unloadRequest].

You may already remember its use with interstitial ads, where it is an essential part of the implementation. In the case of inline ads, this method can also be used in customised ads.

**Note:** If you know that you do not have inline ads that can be hidden or removed, you can ignore this method for inline ads.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        override fun unloadRequest() {
        }
    }
}
// ...
```

### Step 2

Let’s implement this method so that it displays the message to the user and removes the [Advertisement].

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        override fun unloadRequest() {
            _state.value = PresentationState.Error("Unloaded by event listener")
            advertisement?.dispose()
            advertisement = null
        }
    }
}
// ...
```

## Section 3: Monitor and process advertising tracking events

[Advertisement] can perform tracking, depending on the response from the server. The SDK uses [AdTrackingEvent] to identify them. Most often, you’ll use these methods for debugging or handling errors related to tracking. In this section, we’ll look how we can work with [AdTrackingEvent].

### Step 1

You can use two methods to monitor tracking events:

- [AdEventListener.trackingEventProcessed]
- [AdEventListener.trackingEventProcessingFailed]

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun trackingEventProcessed(
            event: AdTrackingEvent,
            processedURLs: List<String>,
            metadata: AdMetadata
        ) {
            
        }

        override suspend fun trackingEventProcessingFailed(
            event: AdTrackingEvent,
            processedURLs: List<String>,
            failedURLs: Map<String, AdError>
        ): AdEventListener.FailureAction {
            
        }
    }
}
// ...
```

### Step 2

Let’s start with [AdEventListener.trackingEventProcessed], it signals a successful tracking on the server. As you can see, one [AdTrackingEvent] can have multiple URLs to track on the server, so you have the `processedURLs` parameter, which contains a list of all the URLs that were requested.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun trackingEventProcessed(
            event: AdTrackingEvent,
            processedURLs: List<String>,
            metadata: AdMetadata
        ) {
            when (event) {
                is AdTrackingEvent.Impression -> {
                    Log.d("AdItemState", "My ad $id is ready")
                }
                is AdTrackingEvent.Viewable -> {
                    Log.d(
                        "AdItemState",
                        "${event.percentage.value}% of my ad $id is now visible on the screen."
                    )
                }
            }

            Log.d(
                "AdItemState", 
                "SDK notified server about that via URLs: $processedURLs"
            )
        }

        override suspend fun trackingEventProcessingFailed(
            event: AdTrackingEvent,
            processedURLs: List<String>,
            failedURLs: Map<String, AdError>
        ): AdEventListener.FailureAction {
            
        }
    }
}
// ...
```

### Step 3

[AdEventListener.trackingEventProcessingFailed] is called in case of an error. In this case, since the event can have several URLs, you get a list of those URLs that were successfully requested and those that failed.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun trackingEventProcessed(
            event: AdTrackingEvent,
            processedURLs: List<String>,
            metadata: AdMetadata
        ) {
            // ...
        }

        override suspend fun trackingEventProcessingFailed(
            event: AdTrackingEvent,
            processedURLs: List<String>,
            failedURLs: Map<String, AdError>
        ): AdEventListener.FailureAction {
            when (event) {
                is AdTrackingEvent.Impression -> {
                    Log.d("AdItemState", "My ad $id is ready")
                }
                is AdTrackingEvent.Viewable -> {
                    Log.d(
                        "AdItemState",
                        "${event.percentage.value}% of my ad $id is now visible on the screen."
                    )
                }
            }

            Log.d(
                "AdItemState",
                """
                    SDK notified server about that via URLs: $processedURLs",
                    but failed during requesting those: $failedURLs
                """.trimIndent()
            )
        }
    }
}
// ...
```

### Step 4

In addition, you should specify how you want to handle this error with [AdEventListener.FailureAction]. You can either [AdEventListener.FailureAction.IGNORE] the error, in which case the server will not know about this event, or try to [AdEventListener.FailureAction.RETRY] the requests to the URLs that failed.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun trackingEventProcessed(
            event: AdTrackingEvent,
            processedURLs: List<String>,
            metadata: AdMetadata
        ) {
            // ...
        }

        override suspend fun trackingEventProcessingFailed(
            event: AdTrackingEvent,
            processedURLs: List<String>,
            failedURLs: Map<String, AdError>
        ): AdEventListener.FailureAction {
            when (event) {
                is AdTrackingEvent.Impression -> {
                    Log.d("AdItemState", "My ad $id is ready")
                }
                is AdTrackingEvent.Viewable -> {
                    Log.d(
                        "AdItemState",
                        "${event.percentage.value}% of my ad $id is now visible on the screen."
                    )
                }
            }

            Log.d(
                "AdItemState",
                """
                    SDK notified server about that via URLs: $processedURLs",
                    but failed during requesting those: $failedURLs
                """.trimIndent()
            )

            return AdEventListener.FailureAction.IGNORE
        }
    }
}
// ...
```

## Section 4: Monitor and process advertising tap events

As a rule, tapping on an ad will trigger a [AdTapEvent] in the SDK. This can be either a simple opening of the URL to the user in an external browser or more complex logic with redirect processing.

In this section, we’ll look how we can work with [AdTapEvent]. Most often, you’ll use it for debugging or handling tap-related errors.

### Step 1

Same with tracking events, you can use two methods to monitor tap events:

- [AdEventListener.tapEventProcessed]
- [AdEventListener.tapEventProcessingFailed]

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun tapEventProcessed(
            event: AdTapEvent,
            processedURL: String,
            metadata: AdMetadata
        ) {
            
        }

        override suspend fun tapEventProcessingFailed(
            event: AdTapEvent,
            error: AdError
        ): AdEventListener.FailureAction {
            
        }
    }
}
// ...
```

### Step 2

Let’s start with [AdEventListener.tapEventProcessed], it signals a successful tap processing.

As you can see, all [AdTapEvent] except [AdTapEvent.SilentTap] should eventually show something to the user. In the case of [AdTapEvent.SilentTap], the SDK only handles the tracking associated with the tap.

**Note:** You can read the [AdTapEvent.SilentTap] documentation to better understand when this event is used.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun tapEventProcessed(
            event: AdTapEvent,
            processedURL: String,
            metadata: AdMetadata
        ) {
            when (event) {
                is AdTapEvent.Tap, is AdTapEvent.TapURL -> {
                    Log.d(
                        "AdItemState",
                        """
                            User tapped on my ad $id.
                            $processedURL opened for the user.
                        """.trimIndent()
                    )
                }
                is AdTapEvent.TapAsset -> {
                    Log.d(
                        "AdItemState",
                        """
                            User tapped on asset ${event.id} of my ad $id.
                            $processedURL opened for the user.
                        """.trimIndent()
                    )
                }
                is AdTapEvent.SilentTap -> {
                    Log.d(
                        "AdItemState",
                        """
                            The renderer of ad $id want to process click counter redirect.
                            URL for redirect: ${event.url}.
                            As a result of redirects we get $processedURL.
                            This URL is NOT opened for the user.
                        """.trimIndent()
                    )
                }
            }
        }

        override suspend fun tapEventProcessingFailed(
            event: AdTapEvent,
            error: AdError
        ): AdEventListener.FailureAction {
            
        }
    }
}
// ...
```

### Step 3

[AdEventListener.tapEventProcessingFailed] is called in case of an error. In this case, we get the [AdTapEvent] that caused the [AdError]. Just like with [AdTrackingEvent], you can decide how you will handle this error with [AdEventListener.FailureAction].

**Note:** Most often, the error is related to an incorrect URL received in the advertisement, but in the case of [AdTapEvent.SilentTap], it can be errors related to redirect processing.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun tapEventProcessed(
            event: AdTapEvent,
            processedURL: String,
            metadata: AdMetadata
        ) {
            // ...
        }

        override suspend fun tapEventProcessingFailed(
            event: AdTapEvent,
            error: AdError
        ): AdEventListener.FailureAction {
            when (event) {
                is AdTapEvent.Tap, is AdTapEvent.TapURL -> {
                    Log.d("AdItemState", "User tapped on my ad $id.")
                }
                is AdTapEvent.TapAsset -> {
                    Log.d("AdItemState", "User tapped on asset ${event.id} of my ad $id")
                }
                is AdTapEvent.SilentTap -> {
                    Log.d(
                        "AdItemState",
                        """
                            The renderer of ad $id want to process click counter redirect.
                            URL for redirect: ${event.url}.
                        """.trimIndent()
                    )
                }
            }
            
            Log.d("AdItemState", "But processing failed with error: ${error.description}")

            return AdEventListener.FailureAction.IGNORE
        }
    }
}
// ...
```

## Section 5: Monitor and process custom advertising events

The AdSDK offers extensive customisation functionality, such as creating customised ads and sending customised events. In this section, we will consider only those events that can occur when using a custom renderer or custom HTML advertising.

### Step 1

Let’s start with the simplest event, when the [AdRenderer] wants to notify the application of an event with a name and an optional message – [AdEventListener.rendererMessageReceived].

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun rendererMessageReceived(name: String, message: String?) {

        }
    }
}
// ...
```

### Step 2

The renderer can send any message that you can process. In our case, we just want to log this event.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun rendererMessageReceived(name: String, message: String?) {
            Log.d(
                "AdItemState",
                """
                    Renderer of my ad $id sent me a message.
                    Name: $name, message: $message"
                    We can create custom logic in the application based on it.
                """.trimIndent()
            )
        }
    }
}
// ...
```

### Step 3

In addition, the custom [AdRenderer] can perform custom tracking. To monitor such events, you can use:

- [AdEventListener.customTrackingEventProcessed]
- [AdEventListener.customTrackingEventProcessingFailed]

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun customTrackingEventProcessed(name: String, url: String, metadata: AdMetadata) {

        }

        override suspend fun customTrackingEventProcessingFailed(
            name: String,
            url: String,
            error: AdError
        ): AdEventListener.FailureAction {

        }
    }
}
// ...
```

### Step 4

The logic is similar to tracking or tap events monitoring and handling. You can get the name of the event, the URL where the request was made, a possible error, and decide how to handle it.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...
    private val eventListener = object : AdEventListener {
        // ...
        override fun customTrackingEventProcessed(name: String, url: String, metadata: AdMetadata) {
            Log.d(
                "AdItemState",
                "Custom tracking event '$name' of my ad $id processed. URL: $url"
            )
        }

        override suspend fun customTrackingEventProcessingFailed(
            name: String,
            url: String,
            error: AdError
        ): AdEventListener.FailureAction {
            Log.d(
                "AdItemState",
                """
                    Custom tracking event '$name' of my ad $id failed during processing.
                    URL: $url, error: ${error.description}
                """.trimIndent()
            )
            
            return AdEventListener.FailureAction.IGNORE
        }
    }
}
// ...
```

[AdError]:ad_sdk/com.adition.ad_sdk.api.entities.exception/-ad-error/index.html
[AdService.makeAdvertisement]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/make-advertisement.html

[Advertisement]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/index.html
[AdRenderer]:ad_sdk/com.adition.ad_sdk.api.core/-ad-renderer/index.html

[AdEventListener]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/index.html
[AdEventListener.unloadRequest]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/unload-request.html
[AdEventListener.trackingEventProcessed]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/tracking-event-processed.html
[AdEventListener.trackingEventProcessingFailed]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/tracking-event-processing-failed.html
[AdEventListener.tapEventProcessed]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/tap-event-processed.html
[AdEventListener.tapEventProcessingFailed]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/tap-event-processing-failed.html
[AdEventListener.rendererMessageReceived]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/renderer-message-received.html
[AdEventListener.customTrackingEventProcessed]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/custom-tracking-event-processed.html
[AdEventListener.customTrackingEventProcessingFailed]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/custom-tracking-event-processing-failed.html

[AdEventListener.FailureAction]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/-failure-action/index.html
[AdEventListener.FailureAction.IGNORE]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/-failure-action/-i-g-n-o-r-e/index.html
[AdEventListener.FailureAction.RETRY]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/-failure-action/-r-e-t-r-y/index.html

[AdTrackingEvent]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-tracking-event/index.html
[AdTapEvent]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-tap-event/index.html
[AdTapEvent.SilentTap]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-tap-event/-silent-tap/index.html
