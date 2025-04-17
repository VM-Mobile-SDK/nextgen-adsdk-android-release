---
layout: default
title: "Create and display inline ads"
nav_order: 2
---

# Create and display inline ads

This tutorial will guide you how to create and display inline ads. An inline ad is an ad created to be displayed in your view hierarchy.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/create-inline-ads) which has already implemented all steps from this tutorial.

## Creating an inline ads

Your [AdService] is ready for creating advertisements, so in this section, we will create an `InlineAd` composable for future ad display.

### Step 1

Lets create an `InlineAd` composable and an `InlineAdViewModel` class.

**File:** `InlineAd.kt`

```kotlin
@Composable
fun InlineAd() {
    Text(
        text = "Advertisement should be here"
    )
}

class InlineAdViewModel : ViewModel() {

} 
```

### Step 2

To create advertisements, we use the [AdService.makeAdvertisement] method. The most important parameter now is [AdRequest], which describes the request that will be sent to the server to receive ads. The only mandatory parameter when creating the [AdRequest] is [AdRequest.contentUnit] or [AdRequest.learningTag]. Content unit is unique ID of a content space.

You can also use [AdRequest.learningTag], but we use [AdRequest.contentUnit] in this tutorial because it is more commonly used.

**File:** `InlineAd.kt`

```kotlin
@Composable
fun InlineAd() {
    Text(
        text = "Advertisement should be here"
    )
}

class InlineAdViewModel : ViewModel() {
    private val adRequest = AdRequest("4810915")
} 
```

### Step 3

The [AdService.makeAdvertisement] method returns [AdResult]. It is also suspendable we will use it in the `viewModelScope`. If the ad is created and loaded successfully, you will receive the downloaded [Advertisement] object. You can think of it as a ViewModel that holds the data and state of your ad.

We'll again use `ResultState` with [Advertisement] to identify whether the ad was created and loaded successfully.

**File:** `InlineAd.kt`

```kotlin
@Composable
fun InlineAd() {
    Text(
        text = "Advertisement should be here"
    )
}

class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(adRequest).get(
                onSuccess = {
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

### Step 4

If we have an [Advertisement] instance, it remains to add a `Composable`. The `sdk_presentation_compose` has [Ad], which is the presentation layer of your inline ad.

**File:** `InlineAd.kt`

```kotlin
@Composable
fun InlineAd() {
    val viewModel: InlineAdViewModel = viewModel()
    viewModel.advertisementState.value?.let {
        when(it) {
            is ResultState.Error -> {
                Text(it.exception.description)
            }
            is ResultState.Success -> {
                Ad(it.data)
            }
        }
    }
}

class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(adRequest).get(
                onSuccess = {
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

### Step 5

The last thing we need to do is add our `Composable` to the `MainActivity`.

**File:** `MainActivity.kt`

```kotlin
class MainActivity : ComponentActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val app = application as App
        app.adServiceStatus.observe(this) { result ->
            when(result) {
                is ResultState.Error -> {
                    showAppError(result.exception)
                }

                is ResultState.Success -> {
                    setContent {
                        TutorialAppTheme {
                            InlineAd()
                        }
                    }
                }
            }
        }
    }

    private fun showAppError(adError: AdError) {
        Toast.makeText(this, "Initialization failed: ${adError.description}", Toast.LENGTH_LONG).show()
    }
}
```

## Section 2: Defining the size of the advertisement

Our `InlineAdViewModel` and `InlineAd` can load and display ads, but how can we understand what size the `Ad` should be? In this section we will deal with this question.

### Step 1

As we already know, [Advertisement] stores advertising data. Let’s try to get it! We can obtain all possible advertising data using [AdMetadata]. This is the one we will use to obtain the size data.

We are interested in [AdMetadata.aspectRatio], which is optional. We have implemented the logic so that in cases where it is not present, we will use the 2:1 ratio.

**File:** `InlineAd.kt`

```kotlin
@Composable
fun InlineAd() {
    val viewModel: InlineAdViewModel = viewModel()
    viewModel.advertisementState.value?.let {
        when(it) {
            is ResultState.Error -> {
                Text(it.exception.description)
            }
            is ResultState.Success -> {
                it.data.adMetadata
                Ad(it.data)
            }
        }
    }
}

class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(adRequest).get(
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
Now we can add the [AdMetadata.aspectRatio] via the `Modifier` into the [Ad].

**File:** `InlineAd.kt`

```kotlin
@Composable
fun InlineAd() {
    val viewModel: InlineAdViewModel = viewModel()
    viewModel.advertisementState.value?.let {
        when(it) {
            is ResultState.Error -> {
                Text(it.exception.description)
            }
            is ResultState.Success -> {
                it.data.adMetadata
                Ad(
                    it.data,
                    modifier = Modifier.aspectRatio(viewModel.aspectRatio)
                )
            }
        }
    }
}

class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(adRequest).get(
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

Now we should see the banner on our device. Congrats!

[AdService]:sdk_core/com.adition.sdk_core.api.core/-ad-service/index.html
[AdService.makeAdvertisement]:sdk_core/com.adition.sdk_core.api.core/-ad-service/make-advertisement.html

[AdRequest]:sdk_core/com.adition.sdk_core.api.entities.request/-ad-request/index.html
[AdRequest.contentUnit]:sdk_core/com.adition.sdk_core.api.entities.request/-ad-request/content-unit.html
[AdRequest.learningTag]:sdk_core/com.adition.sdk_core.api.entities.request/-ad-request/learning-tag.html

[AdMetadata]:sdk_core/com.adition.sdk_core.api.entities.response/-ad-metadata/index.html
[AdMetadata.aspectRatio]:sdk_core/com.adition.sdk_core.api.entities.response/-ad-metadata/aspect-ratio.html

[AdResult]:sdk_core/com.adition.sdk_core.api.entities.exception/-ad-result/index.html

[Advertisement]:sdk_core/com.adition.sdk_core.api.core/-advertisement/index.html

[Ad]:sdk_presentation_compose/com.adition.sdk_presentation_compose.api/-ad/index.html
