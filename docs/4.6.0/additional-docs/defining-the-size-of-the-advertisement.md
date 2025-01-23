---
layout: default
title: "3. Defining the size of the advertisement"
---

# Defining the size of the advertisement
This tutorial will teach you how to define the size of the advertisement, taking into account the aspect ratio parameter. 
In it, we will continue the development of the application we started in the previous section.

## Section 1: Defining the size of the advertisement

### Step 1
For the the size of the advertisement we can use [AdMetadata](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.model/-ad-meta-data/index.html). 
From this object we can get the basic information after the advertising content has been loaded from the server.

We will use the `aspectRatio` from the [adMetadata](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.model/-ad-meta-data/index.html). 
So let's get the [adMetadata](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.model/-ad-meta-data/index.html) from [adState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/index.html):
```kotlin 
val aspectRatio = adState.adMetaData?.aspectRatio ?: 2F
```
Since `aspectRatio` is optional, we use the default value of 2:1 in this project.

### Step 2
Now we can add the `aspectRatio` via the Modifier into the [Ad](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad.html) composable.
```kotlin 
@Composable
fun AdView(viewModel: MainViewModel) {
    val adState = rememberAdState(advertisement = viewModel.ad)
    val aspectRatio = adState.adMetaData?.aspectRatio ?: 2F
    Ad(
        adState = adState,
        modifier = Modifier
            .aspectRatio(aspectRatio)
    )

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
Note:
In this case, we are requesting the `adMetaData` before the ad is successfully loaded, but when the ad is successfully loaded, the composable will be updated and we will get this data.
In a real-world scenario, you would most likely use a `ViewModel‘ or other state management mechanism where you could implement logic to ensure that the `adMetaData’ is only requested when the ad is already loaded.