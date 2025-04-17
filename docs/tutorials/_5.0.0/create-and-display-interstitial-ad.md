---
layout: default
title: "Create and display interstitial ad"
nav_order: 3
---

# Create and display interstitial ad

A full-screen advertisement that fills the host app’s interface is known as an interstitial ad. In this tutorial we will add an interstitial ad to our application.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project] which has already implemented all steps from this tutorial.

## Section 1: Prepare app for interstitial ad

We want to present the interstitial on a different screen and add navigation buttons for it.

### Step 1

Let's create a new `MainScreen` file in which we add `Navigation` and `MainScreen`.

**Note:** At the moment you will get an error, because we have not created `InterstitialScreen` yet.

**File:** `MainScreen.kt`

```kotlin
@Composable
fun Navigation() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = "mainScreen") {
        composable("mainScreen") { MainScreen(navController) }
        composable("interstitial") { InterstitialScreen() }
    }
}

@Composable
fun MainScreen(navController: NavController) {
    Scaffold(
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { navController.navigate("interstitial") },
                content = { Text("Go to Interstitial") },
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            InlineAd()
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
```

### Step 2

The next step is to create our future screen for displaying interstitial ads. Create a new `InterstitialScreen` file and add a screen with a button to it.

**File:** `InterstitialScreen.kt`

```kotlin
@Composable
fun InterstitialScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Button(
            onClick = {

            },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(26.dp)
        ) {

            Text(
                text = "Show Interstitial",
            )
        }
    }
}

class InterstitialAdViewModel : ViewModel() {

}
```

## Section 2: Creating interstitial advertisements

We have already created an inline [Advertisement] on a previous chapter. In this section, we will create a interstitial ad for the future presentation.

### Step 1

Interstitial ad is created in the same way as inline ads, with one difference – the `placementType` parameter must be [AdPlacementType.INTERSTITIAL].

Let's add the logic for loading the advertisement into `InterstitialAdViewModel`. We'll again use `ResultState` with [Advertisement] to identify whether the ad was created and loaded successfully.

**File:** `InterstitialScreen.kt`

```kotlin
@Composable
fun InterstitialScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Button(
            onClick = {

            },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(26.dp)
        ) {

            Text(
                text = "Show Interstitial",
            )
        }
    }
}

class InterstitialAdViewModel : ViewModel() {
    private val adRequest = AdRequest("5192923")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                placementType = AdPlacementType.INTERSTITIAL,
            ).get(
                onSuccess = {
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InterstitialAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

### Step 2

We add the `InterstitialAdViewModel` to the `InterstitialAd`.

**File:** `InterstitialScreen.kt`

```kotlin
@Composable
fun InterstitialScreen() {
    val viewModel: InterstitialAdViewModel = viewModel()
    viewModel.advertisementState.value?.let {
        when(it) {
            is ResultState.Error -> {
                Text(it.exception.description)
            }
            is ResultState.Success -> {
                Button(
                    onClick = {

                    },
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(26.dp)
                ) {
                    Text(
                        text = "Show Interstitial",
                    )
                }
            }
        }
    }
}

class InterstitialAdViewModel : ViewModel() {
    private val adRequest = AdRequest("5192923")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                placementType = AdPlacementType.INTERSTITIAL,
            ).get(
                onSuccess = {
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InterstitialAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

## Section 3: Presenting interstitial ad

We learnt how to create interstitial advertisement. Now, we are ready to present our interstitial ad. In this section, we will display interstitial ad in our app.

### Step 1

Our AdSDK provides [AdInterstitialState] to control the state of the interstitial ad presentation.

Add a property for this in the `InterstitialAdViewModel`.

**File:** `InterstitialScreen.kt`

```kotlin
fun InterstitialScreen() {
    val viewModel: InterstitialAdViewModel = viewModel()
    viewModel.advertisementState.value?.let {
        when(it) {
            is ResultState.Error -> {
                Text(it.exception.description)
            }
            is ResultState.Success -> {
                Button(
                    onClick = {

                    },
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(26.dp)
                ) {
                    Text(
                        text = "Show Interstitial",
                    )
                }
            }
        }
    }
}

class InterstitialAdViewModel : ViewModel() {
    private val adRequest = AdRequest("5192923")
    var advertisement = mutableStateOf<Advertisement?>(null)
    lateinit var interstitialState: AdInterstitialState

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                placementType = PlacementType.INTERSTITIAL,
                adEventListener = adEventListener
            ).get(
                onSuccess = {
                    interstitialState = AdInterstitialState(it, this)
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("AdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

### Step 2

The next step will be adding a presentation layer. To display interstitial ads, SDK has an [Interstitial] composable. Add it to your `InterstitialScreen` and pass the state value from the `InterstitialAdViewModel`.

**File:** `InterstitialScreen.kt`

```kotlin
@Composable
fun InterstitialScreen(modifier: Modifier) {
    val viewModel: InterstitialAdViewModel = viewModel()
    Box(
        modifier = modifier
            .fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        viewModel.advertisementState.value?.let {
            when(it) {
                is ResultState.Error -> {
                    Text(it.exception.description)
                }
                is ResultState.Success -> {
                    Button(
                        onClick = {

                        },
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(26.dp)
                    ) {
                        Text(
                            text = "Show Interstitial",
                        )
                    }
                    Interstitial(viewModel.interstitialState)
                }
            }
        }
    }
}

class InterstitialAdViewModel : ViewModel() {
    private val adRequest = AdRequest("5192923")
    var advertisement = mutableStateOf<Advertisement?>(null)
    lateinit var interstitialState: AdInterstitialState

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                placementType = PlacementType.INTERSTITIAL
            ).get(
                onSuccess = {
                    interstitialState = AdInterstitialState(it, this)
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InterstitialAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

### Step 3

To show an interstitial ad, you can use the [AdInterstitialState.presentIfLoaded] method.

**Note:** If you don’t use the [Advertisement.reload] method, your [Advertisement] object will always be loaded, which means that the ad will be presented to the user immediately when [AdInterstitialState.presentIfLoaded] method called. Otherwise, the ad will be presented immediately after loading.

**File:** `InterstitialScreen.kt`

```kotlin
fun InterstitialScreen() {
    val viewModel: InterstitialAdViewModel = viewModel()
    Box(
        modifier = modifier
            .fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        viewModel.advertisementState.value?.let {
            when(it) {
                is ResultState.Error -> {
                    Text(it.exception.description)
                }
                is ResultState.Success -> {
                    Button(
                        onClick = {
                            viewModel.interstitialState.presentIfLoaded()
                        },
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(26.dp)
                    ) {
                        Text(
                            text = "Show Interstitial",
                        )
                    }
                    Interstitial(viewModel.interstitialState)
                }
            }
        }
    }
}

class InterstitialAdViewModel : ViewModel() {
    private val adRequest = AdRequest("5192923")
    var advertisement = mutableStateOf<Advertisement?>(null)
    lateinit var interstitialState: AdInterstitialState

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                placementType = PlacementType.INTERSTITIAL
            ).get(
                onSuccess = {
                    interstitialState = AdInterstitialState(it, this)
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InterstitialAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

## Section 3: Hiding interstitial ad

We managed to successfully show the ad, but we would like to be able to close interstitial. In this section, we implement this logic.

### Step 1

Let’s continue the development in our `InterstitialScreen` file. We could hide the ad by simply calling the [AdInterstitialState.hide] method, but we don’t know when to call it.

In order to understand when ad should be hidden, we need to use [AdEventListener]. We will explain the [AdEventListener] in more detail in the next chapter.

Let's create an `adEventListener` in `InterstitialAdViewModel`, and then pass it to the [AdService.makeAdvertisement].

**File:** `InterstitialScreen.kt`

```kotlin
fun InterstitialScreen() {
    val viewModel: InterstitialAdViewModel = viewModel()
    Box(
        modifier = modifier
            .fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        viewModel.advertisementState.value?.let {
            when(it) {
                is ResultState.Error -> {
                    Text(it.exception.description)
                }
                is ResultState.Success -> {
                    Button(
                        onClick = {
                            viewModel.interstitialState.presentIfLoaded()
                        },
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(26.dp)
                    ) {
                        Text(
                            text = "Show Interstitial",
                        )
                    }
                    Interstitial(viewModel.interstitialState)
                }
            }
        }
    }
}

class InterstitialAdViewModel : ViewModel() {
    private val adRequest = AdRequest("5192923")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    lateinit var interstitialState: AdInterstitialState

    val adEventListener: AdEventListener = object : AdEventListener {
        override fun eventProcessed(adEventType: AdEventType, adMetadata: AdMetadata) {
            Log.d("InterstitialAdViewModel events", "Collected EVENT - $adEventType")
        }
    }

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                placementType = AdPlacementType.INTERSTITIAL,
                adEventListener = adEventListener
            ).get(
                onSuccess = {
                    interstitialState = AdInterstitialState(it, this)
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InterstitialAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

### Step 2

The event we are interested in is [AdEventType.UnloadRequest]. We need to observe it to make sure that the ad is hidden when it is needed.

**Note:** You should not change the state from presented to hidden without using [AdEventType.UnloadRequest] event. The advert itself knows when it needs to be hidden and asks you to hide it using this method.

**File:** `InterstitialScreen.kt`

```kotlin
fun InterstitialScreen() {
    val viewModel: InterstitialAdViewModel = viewModel()
    Box(
        modifier = modifier
            .fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        viewModel.advertisementState.value?.let {
            when(it) {
                is ResultState.Error -> {
                    Text(it.exception.description)
                }
                is ResultState.Success -> {
                    Button(
                        onClick = {
                            viewModel.interstitialState.presentIfLoaded()
                        },
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(26.dp)
                    ) {
                        Text(
                            text = "Show Interstitial",
                        )
                    }
                    Interstitial(viewModel.interstitialState)
                }
            }
        }
    }
}

class InterstitialAdViewModel : ViewModel() {
    private val adRequest = AdRequest("5192923")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    lateinit var interstitialState: AdInterstitialState

    val adEventListener: AdEventListener = object : AdEventListener {
        override fun eventProcessed(adEventType: AdEventType, adMetadata: AdMetadata) {
            Log.d("InterstitialAdViewModel events", "Collected EVENT - $adEventType")
            if (adEventType == AdEventType.UnloadRequest) {
                interstitialState.hide()
            }
        }
    }

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
                placementType = AdPlacementType.INTERSTITIAL,
                adEventListener= adEventListener
            ).get(
                onSuccess = {
                    interstitialState = AdInterstitialState(it, this)
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InterstitialAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

Now, if you launch the app, you should see an interstitial ad.

[project]:(https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/create-interstitial-ads)

[AdService.makeAdvertisement]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.core/-ad-service/make-advertisement.html)

[Advertisement]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.core/-advertisement/index.html)
[Advertisement.reload]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.core/-advertisement/reload.html)

[AdPlacementType.INTERSTITIAL]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.entities.request/-ad-placement-type/-i-n-t-e-r-s-t-i-t-i-a-l/index.html)

[AdEventListener]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-listener/index.html)

[AdInterstitialState]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.entities/-ad-interstitial-state/index.html)
[AdInterstitialState.presentIfLoaded]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.entities/-ad-interstitial-state/present-if-loaded.html)
[AdInterstitialState.hide]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.entities/-ad-interstitial-state/hide.html)

[AdEventType.UnloadRequest]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/-unload-request/index.html)

[Interstitial]:(https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.0/sdk_presentation_compose/com.adition.sdk_presentation_compose.api/-interstitial/index.html)
