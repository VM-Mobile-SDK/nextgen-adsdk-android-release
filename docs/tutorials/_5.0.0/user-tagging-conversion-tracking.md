---
layout: default
title: "User tagging and conversion tracking"
nav_order: 5
---

# User tagging and conversion tracking

AdSDK provides powerful functionality for user tagging and conversion tracking. In this tutorial we will explore this functionality.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project] which has already implemented all steps from this tutorial.

## Section 1: User tagging

The SDK provides functionality to put a user identifier, such as a cookie id, into a retargeting segment (to tag a user). This allows advertisers to create a segment of users with certain interests or affinities, and to re-advertise to this segment (retargeting). In this section, we will look at how to perform a tag request using the AdSDK.

### Step 1

To tag a user we need a [TagRequest], that describes the request for tagging and consists of tags with a key, a subkey, and a value.

We keep it simple and just add a `tagUser()` method to the `InlineAdViewModel` and create a [TagRequest] with one [TagRequest.Tag].

**File:** `InlineAd.kt`

```kotlin
class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...
    
    init {
        viewModelScope.launch {
            tagUser()

            // ...
        }
    }

    private suspend fun tagUser() {
        val tags = listOf(TagRequest.Tag("segments", "category", "home"))
        val request = TagRequest(tags)
    }
}
```

### Step 2

We pass the [TagRequest] to the [AdService.tagUser].

**File:** `InlineAd.kt`

```kotlin
class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...

    init {
        viewModelScope.launch {
            tagUser()

            // ...
        }
    }

    private suspend fun tagUser() {
        val tags = listOf(TagRequest.Tag("segments", "category", "home"))
        val request = TagRequest(tags)

        AdService.tagUser(request)
    }
}
```

### Step 3

The [AdService.tagUser] method returns an [AdResult], so let's log the result.

**File:** `InlineAd.kt`

```kotlin
class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...

    init {
        viewModelScope.launch {
            tagUser()

            // ...
        }
    }

    private suspend fun tagUser() {
        val tags = listOf(TagRequest.Tag("segments", "category", "home"))
        val request = TagRequest(tags)

        AdService.tagUser(request).get(
            onSuccess = {
                Log.d("InlineAdViewModel", "User tagging was successful")
            },
            onError = {
                Log.d("InlineAdViewModel", "Failed user tagging: ${it.description}")
            }
        )
    }
}
```

### Step 4

To make sure the user is tagged before we call [AdService.makeAdvertisement], we will use the `coroutines` `async` method.

**File:** `InlineAd.kt`

```kotlin
class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...

    init {
        viewModelScope.launch {
            val tagUser = async { tagUser() }
            tagUser.await()

            // ...
        }
    }

    private suspend fun tagUser() {
        val tags = listOf(TagRequest.Tag("segments", "category", "home"))
        val request = TagRequest(tags)

        AdService.tagUser(request).get(
            onSuccess = {
                Log.d("InlineAdViewModel", "User tagging was successful")
            },
            onError = {
                Log.d("InlineAdViewModel", "Failed user tagging: ${it.description}")
            }
        )
    }
}
```

## Section 2: Conversion tracking

The SDK allows you to track conversions. This is useful for advertisers as conversion details are available in post tracking reports via the ad server. In this section we will look at how to perform a tracking request using the AdSDK.

### Step 1

A conversion tracking request is described using [TrackingRequest].

We add a `conversionTracking()` function to the `InlineAdViewModel`

**File:** `InlineAd.kt`

```kotlin
class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...

    init {
        viewModelScope.launch {
            tagUser()
            conversionTracking()

            // ...
        }
    }

    private suspend fun tagUser() {
        val tags = listOf(TagRequest.Tag("segments", "category", "home"))
        val request = TagRequest(tags)

        AdService.tagUser(request).get(
            onSuccess = {
                Log.d("InlineAdViewModel", "User tagging was successful")
            },
            onError = {
                Log.d("InlineAdViewModel", "Failed user tagging: ${it.description}")
            }
        )
    }

    private suspend fun conversionTracking() {
        val request = TrackingRequest(
            landingPageId = 1,
            trackingSpotId = 1,
            orderId = "orderId",
            itemNumber = "itemNumber",
            description = "description",
            quantity = 1,
            price = 19.99f,
            total = 39.98f
        )
    }
}
```

### Step 2

We pass the [TrackingRequest] to the [AdService.trackingRequest].

**File:** `InlineAd.kt`

```kotlin
class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...

    init {
        viewModelScope.launch {
            tagUser()
            conversionTracking()

            // ...
        }
    }

    private suspend fun tagUser() {
        val tags = listOf(TagRequest.Tag("segments", "category", "home"))
        val request = TagRequest(tags)

        AdService.tagUser(request).get(
            onSuccess = {
                Log.d("InlineAdViewModel", "User tagging was successful")
            },
            onError = {
                Log.d("InlineAdViewModel", "Failed user tagging: ${it.description}")
            }
        )
    }

    private suspend fun conversionTracking() {
        val request = TrackingRequest(
            landingPageId = 1,
            trackingSpotId = 1,
            orderId = "orderId",
            itemNumber = "itemNumber",
            description = "description",
            quantity = 1,
            price = 19.99f,
            total = 39.98f
        )

        AdService.trackingRequest(request)
    }
}
```


### Step 3

The [AdService.trackingRequest] method also returns an [AdResult], so let's log the result.

**File:** `InlineAd.kt`

```kotlin
class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...

    init {
        viewModelScope.launch {
            tagUser()
            conversionTracking()

            // ...
        }
    }

    private suspend fun tagUser() {
        val tags = listOf(TagRequest.Tag("segments", "category", "home"))
        val request = TagRequest(tags)

        AdService.tagUser(request).get(
            onSuccess = {
                Log.d("InlineAdViewModel", "User tagging was successful")
            },
            onError = {
                Log.d("InlineAdViewModel", "Failed user tagging: ${it.description}")
            }
        )
    }

    private suspend fun conversionTracking() {
        val request = TrackingRequest(
            landingPageId = 1,
            trackingSpotId = 1,
            orderId = "orderId",
            itemNumber = "itemNumber",
            description = "description",
            quantity = 1,
            price = 19.99f,
            total = 39.98f
        )

        AdService.trackingRequest(request).get(
            onSuccess = {
                Log.d("InlineAdViewModel", "Conversion tracking was successful")
            },
            onError = {
                Log.d("InlineAdViewModel", "Failed conversion tracking: ${it.description}")
            }
        )
    }
}
```

### Step 4

To ensure that the conversion tracking is done before we call the [AdService.makeAdvertisement] method, we will use the `coroutines` `async` method.

**File:** `InlineAd.kt`

```kotlin
class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...

    init {
        viewModelScope.launch {
            val tagUser = async { tagUser() }
            val conversionTracking = async { conversionTracking() }
            tagUser.await()
            conversionTracking.await()

            // ...
        }
    }

    private suspend fun tagUser() {
        val tags = listOf(TagRequest.Tag("segments", "category", "home"))
        val request = TagRequest(tags)

        AdService.tagUser(request).get(
            onSuccess = {
                Log.d("InlineAdViewModel", "User tagging was successful")
            },
            onError = {
                Log.d("InlineAdViewModel", "Failed user tagging: ${it.description}")
            }
        )
    }

    private suspend fun conversionTracking() {
        val request = TrackingRequest(
            landingPageId = 1,
            trackingSpotId = 1,
            orderId = "orderId",
            itemNumber = "itemNumber",
            description = "description",
            quantity = 1,
            price = 19.99f,
            total = 39.98f
        )

        AdService.trackingRequest(request).get(
            onSuccess = {
                Log.d("InlineAdViewModel", "Conversion tracking was successful")
            },
            onError = {
                Log.d("InlineAdViewModel", "Failed conversion tracking: ${it.description}")
            }
        )
    }
}
```

[project]:(https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/tag-tracking-tutorial)

[AdService.makeAdvertisement]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.core/-ad-service/make-advertisement.html)
[AdService.tagUser]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.core/-ad-service/tag-user.html)
[AdService.trackingRequest]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.core/-ad-service/tracking-request.html)

[TagRequest]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.entities.request/-tag-request/index.html)
[TagRequest.Tag]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.entities.request/-tag-request/-tag/index.html)

[TrackingRequest]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.entities.request/-tracking-request/index.html)

[AdResult]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.entities.exception/-ad-result/index.html)
