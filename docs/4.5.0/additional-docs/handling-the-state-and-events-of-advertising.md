---
layout: default
title: "2. Handling the state and events of advertising"
---

# Handling the state and events
This tutorial will help you observe and respond to changes in the state and events.
In it, we will continue the development of the application we started in the previous section.

## Section 1: Observing the states

When we talk about state we mean the lifecycle state of the [Ads](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad.html) composable.

### Step 1
The state of an [Ad](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad.html) is called [AdState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/index.html).
This is an example of how we can observe the [AdState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/index.html):
```kotlin
when (val state = adState?.state) {
    is AdState.State.Error -> {
        // We have an error.
    }
    is AdState.State.Loading -> {
        // We are Caching.
    }
    is AdState.State.Caching -> {
        // We are Caching.
    }
    is AdState.State.AdReadyToDisplay -> {
        // Ad is ready and will be displayed.
    }
    else -> {}
}
```
Here we can see the different ad [states](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/-state/index.html) we can observe:
- [Error](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/-state/-error/index.html)
- [Loading](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/-state/-loading/index.html)
- [Caching](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/-state/-caching/index.html)
- [AdReadyToDisplay](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/-state/-ad-ready-to-display/index.html)
-
### Step 2
Let's add the code snippet from above to our `AdView` example:
```kotlin
@Composable
fun AdView() {
    val adState = rememberAdState(advertisement = viewModel.ad)
    Ad(adState = adState, modifier = Modifier)

    when (val state = adState?.state) {
        is AdState.State.Error -> {
            // We have an error.
        }
        is AdState.State.Loading -> {
            // We are Caching.
        }
        is AdState.State.Caching -> {
            // We are Caching.
        }
        is AdState.State.AdReadyToDisplay -> {
            // Ad is ready and will be displayed and we could additional work
        }
        else -> {}
    }
}
```
We are able now to act accordingly to each [AdState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/index.html) state.

## Section 2: Handling errors during the loading and decoding

Sometimes it's important for an app to be able to handle errors correctly.
With the help of [AdError](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_core/com.adition.sdk_core/-ad-error/index.html), you can catch a specific error and implement the logic for handling it the way you need.

### Step 1
We can observe errors in the AdSDK with [AdException](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_core/com.adition.sdk_core/-ad-exception/index.html).
An [AdException](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_core/com.adition.sdk_core/-ad-exception/index.html) holds the exception itself and the type of the error via [AdError](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_core/com.adition.sdk_core/-ad-error/index.html).
With [AdError](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_core/com.adition.sdk_core/-ad-error/index.html) we can observe different error types.
For example lets catch a decoding error.
```kotlin
when(state.adException.adError) {
    AdError.DECODING -> {
        // Act accordingly e.g. repeat the request.
    }
}
```

### Step 2
You can catch a number of different error types, just check [AdError](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_core/com.adition.sdk_core/-ad-error/index.html).
Let's just log the error and have a look how our composable should look like.
```kotlin
@Composable
fun AdView(viewModel: MainViewModel) {
    val adState = rememberAdState(advertisement = viewModel.ad)
    Ad(adState = adState, modifier = Modifier)

    when (val state = adState?.state) {
        is AdState.State.Error -> {
            when(state.adException.adError) {
                AdError.DECODING -> {
                    Log.e("MainActivity", "Decoding error: ${state.adException.exception}")
                }
            }
        }
        is AdState.State.Loading -> {
            // We are Caching.
        }
        is AdState.State.Caching -> {
            // We are Caching.
        }
        is AdState.State.AdReadyToDisplay -> {
            // Ad is ready and will be displayed.
        }
        else -> {}
    }
}
```

## Section 3: Observing the advertising events
Observe the advertising events to respond to them in the application.
The SDK can send many events related to advertisements, like impressions, visibility percentages and tap events.

### Step 1
With the use of the [AdService](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_core/com.adition.sdk_core/-ad-service/index.html) we can collect all ad [Event](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_core/com.adition.sdk_core/-event/index.html).
```kotlin
AdService.getInstance().eventHandler?.events?.collect { event ->
    Log.d("Events", "Collected EVENT - $event")
}
```

### Step 2
Start the event observing before the composable loads if you want to make sure you get every event.
For example, we could add it in the `App` class.
```kotlin
class App: Application() {
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
        }
    }
}
```

### Step 3
You can observe the specific [EventTypes](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.5.0/sdk_core/com.adition.sdk_core/-event-type/index.html) you are interested in.
For example, you can react to the tap on ads:
```kotlin
when(event.eventType) {
    is EventType.Tap -> {
        // Ad got tapped.
    }
    else -> {}
}
```

### Step 4
Let's add this to the App class as well.
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
        }
    }
}
```

Now we could act accordingly to a specific event in any way we wanted.