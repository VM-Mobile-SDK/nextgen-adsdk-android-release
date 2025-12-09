---
layout: default
title: "Create and display interstitial ad"
nav_order: 3
---

# Create and display interstitial ad

A full-screen advertisement that fills the host app’s interface is known as an interstitial ad. In this tutorial we will add an interstitial ad to our application.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/create-interstitial-ads) which has already implemented all steps from this tutorial.

## Section 1: Creating interstitial advertisements

We have already created an inline [Advertisement] on a previous chapter. In this section, we will create a interstitial ad for the future presentation.

### Step 1

Let’s create `InterstitialRoute`, `InterstitialScreen` composable, and `InterstitialViewModel` in the `presentation/screens`. This will be the screen where we will display the ad.

**File:** `InterstitialScreen.kt`

```kotlin
@Serializable
data object InterstitialRoute

@Composable
fun InterstitialScreen(
    viewModel: InterstitialViewModel = viewModel(),
    navController: NavController
) {
}

class InterstitialViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
}
```

### Step 2

Same with the `InlineScreen`, let's add it to our navigation.

**File:** `MainScreen.kt`

```kotlin
// ...
@Composable
fun MainScreen(
    navController: NavController,
    viewModel: MainViewModel = viewModel()
) {
    val uiState by viewModel.state.collectAsState()

    PresentationStateContainer(
        uiState,
        Modifier.fillMaxSize()
    ) {
        Column(
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            Button(
                onClick = { navController.navigate(InlineRoute) }
            ) {
                Text("Inline Ads List")
            }

            Button(
                onClick = { navController.navigate(InterstitialRoute) }
            ) {
                Text("Interstitial Ad")
            }
        }
    }
}
//...
```

**File:** `MainActivity.kt`

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TutorialAppTheme {
                val navController = rememberNavController()

                NavHost(
                    navController = navController,
                    startDestination = MainRoute
                ) {
                    composable<MainRoute> { MainScreen(navController = navController) }
                    composable<InlineRoute> { InlineScreen(navController = navController) }
                    composable<InterstitialRoute> {
                        InterstitialScreen(navController = navController)
                    }
                }
            }
        }
    }
}
```

### Step 3

Creating interstitial ads is almost the same as creating inline ads, with one small difference – the `placementType` parameter must be [AdPlacementType.INTERSTITIAL].

Let's add the logic for loading the advertisement into `InterstitialViewModel`.

**File:** `InterstitialScreen.kt`

```kotlin
// ...
class InterstitialViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    init {
        viewModelScope.launch {
            val request = AdRequest(contentUnit = "5192923")

            adService.makeAdvertisement(
                adRequest = request,
                placementType = AdPlacementType.INTERSTITIAL,
                adEventListener = null
            ).get(
                onSuccess = { ad ->
                    
                },
                onError = { error ->
                    
                }
            )
        }
    }
}
```

## Section 3: Presenting interstitial ad

We learnt how to create interstitial advertisement. Now, we are ready to present our interstitial ad. In this section, we will display interstitial ad in our app.

## Step 1

The AdSDK provides [AdInterstitialState] to control the state of the interstitial ad presentation. It accepts two parameters:

- `advertisement` – the advertisement to be displayed.
- `scope` – the coroutine scope that defines the interstitial's lifecycle.

We add [AdInterstitialState] to `PresentationState` for presentation control.

**File:** `InterstitialScreen.kt`

```kotlin
// ...
@Composable
fun InterstitialScreen(
    viewModel: InterstitialViewModel = viewModel(),
    navController: NavController
) {
    val uiState by viewModel.state.collectAsState()

    PresentationStateContainer(
        uiState,
        Modifier.fillMaxSize()
    ) { interstitialState ->
        AppTopBarContainer(
            title = "Interstitial Screen",
            onNavigateBack = { navController.navigateUp() }
        ) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.fillMaxSize()
            ) {
            }
        }
    }
}

class InterstitialViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    private var interstitialState: AdInterstitialState? = null
    private val _state = MutableStateFlow<PresentationState<AdInterstitialState>>(
        PresentationState.Loading
    )

    val state = _state.asStateFlow()

    init {
        viewModelScope.launch {
            val request = AdRequest(contentUnit = "5192923")

            adService.makeAdvertisement(
                adRequest = request,
                placementType = AdPlacementType.INTERSTITIAL,
                adEventListener = null
            ).get(
                onSuccess = { ad ->
                    val adState = AdInterstitialState(ad, this)
                    interstitialState = adState
                    _state.value = PresentationState.Loaded(adState)
                },
                onError = { error ->
                    interstitialState = null
                    _state.value = PresentationState.Error(error.description)
                }
            )
        }
    }
}
```

### Step 2

Now let’s add a button that will show our ad if it is loaded.

**File:** `InterstitialScreen.kt`

```kotlin
// ...
@Composable
fun InterstitialScreen(
    viewModel: InterstitialViewModel = viewModel(),
    navController: NavController
) {
    val uiState by viewModel.state.collectAsState()

    PresentationStateContainer(
        uiState,
        Modifier.fillMaxSize()
    ) { interstitialState ->
        AppTopBarContainer(
            title = "Interstitial Screen",
            onNavigateBack = { navController.navigateUp() }
        ) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.fillMaxSize()
            ) {
                Button(
                    onClick = { viewModel.onPresent() }
                ) {
                    Text("Present")
                }
            }
        }
    }
}

class InterstitialViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    private var interstitialState: AdInterstitialState? = null
    // ...

    init {
        // ...
    }

    fun onPresent() {  }
}
```

### Step 3

To show an interstitial ad, you can use the [AdInterstitialState.presentIfLoaded] method.

**Note:** If you don’t use the [Advertisement.reload] method, your [Advertisement] object will always be loaded, which means that the ad will be presented to the user immediately when [AdInterstitialState.presentIfLoaded] method called. Otherwise, the ad will be presented immediately after loading.

**File:** `InterstitialScreen.kt`

```kotlin
// ...
class InterstitialViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    private var interstitialState: AdInterstitialState? = null
    // ...

    init {
        // ...
    }

    fun onPresent() { interstitialState?.presentIfLoaded() }
}
```

### Step 3

The next step will be adding a presentation layer. To display interstitial ads, SDK has an [Interstitial] composable. Add it to your `InterstitialScreen` and pass the state.

**File:** `InterstitialScreen.kt`

```kotlin
// ...
@Composable
fun InterstitialScreen(
    viewModel: InterstitialViewModel = viewModel(),
    navController: NavController
) {
    val uiState by viewModel.state.collectAsState()

    PresentationStateContainer(
        uiState,
        Modifier.fillMaxSize()
    ) { interstitialState ->
        AppTopBarContainer(
            title = "Interstitial Screen",
            onNavigateBack = { navController.navigateUp() }
        ) {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.fillMaxSize()
            ) {
                Button(
                    onClick = { viewModel.onPresent() }
                ) {
                    Text("Present")
                }
            }
        }

        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.fillMaxSize()
        ) {
            Interstitial(interstitialState)
        }
    }
}
// ...
```

## Section 3: Hiding interstitial ad

We managed to successfully show the ad, but we would like to be able to close interstitial. In this section, we implement this logic.

### Step 1

Let’s continue the development in our `InterstitialScreen` file. We could hide the ad by simply calling the [AdInterstitialState.hide] method, but we don’t know when to call it.

In order to understand when ad should be hidden, we need to use [AdEventListener]. We will explain the [AdEventListener] in more detail in the next tutorial.

Let's create an `adEventListener` in `InterstitialViewModel`, and then pass it to the [AdService.makeAdvertisement].

**File:** `InterstitialScreen.kt`

```kotlin
// ...
class InterstitialViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    private var interstitialState: AdInterstitialState? = null
    private val _state = MutableStateFlow<PresentationState<AdInterstitialState>>(
        PresentationState.Loading
    )

    private val adEventListener: AdEventListener = object : AdEventListener {
    }

    val state = _state.asStateFlow()

    init {
        viewModelScope.launch {
            val request = AdRequest(contentUnit = "5192923")

            adService.makeAdvertisement(
                adRequest = request,
                placementType = AdPlacementType.INTERSTITIAL,
                adEventListener = adEventListener
            ).get(
                onSuccess = { ad ->
                    val adState = AdInterstitialState(ad, this)
                    interstitialState = adState
                    _state.value = PresentationState.Loaded(adState)
                },
                onError = { error ->
                    interstitialState = null
                    _state.value = PresentationState.Error(error.description)
                }
            )
        }
    }

    fun onPresent() { interstitialState?.presentIfLoaded() }
}
```

### Step 2

The method we are interested in is [AdEventListener.unloadRequest]. We need to implement it to make sure that the ad is hidden when it is needed.

**Note:** You should not change the state from presented to hidden without using [AdEventListener.unloadRequest] method. The advert itself knows when it needs to be hidden and asks you to hide it using this method.

**File:** `InterstitialScreen.kt`

```kotlin
// ...
class InterstitialViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    private var interstitialState: AdInterstitialState? = null
    private val _state = MutableStateFlow<PresentationState<AdInterstitialState>>(
        PresentationState.Loading
    )

    private val adEventListener: AdEventListener = object : AdEventListener {
        override fun unloadRequest() { interstitialState?.hide() }
    }

    val state = _state.asStateFlow()

    init {
        // ...
    }

    fun onPresent() { interstitialState?.presentIfLoaded() }
}
```

### Step 3

Same with inline ad, to avoid leaks, we must clear the advertisement when we no longer need it using the [Advertisement.dispose] method.

**File:** `InterstitialScreen.kt`

```kotlin
class InterstitialViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    private var interstitialState: AdInterstitialState? = null
    // ...

    init {
        // ...
    }

    fun onPresent() { interstitialState?.presentIfLoaded() }

    override fun onCleared() {
        super.onCleared()
        interstitialState?.advertisement?.dispose()
    }
}
```

You can launch the app and make sure it works. Congratulations, we can now display interstitials in our app!

[AdService.makeAdvertisement]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/make-advertisement.html

[Advertisement]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/index.html
[Advertisement.reload]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/reload.html
[Advertisement.dispose]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/dispose.html

[AdPlacementType.INTERSTITIAL]:ad_sdk/com.adition.ad_sdk.api.entities.request/-ad-placement-type/-i-n-t-e-r-s-t-i-t-i-a-l/index.html

[AdInterstitialState]:ad_sdk/com.adition.ad_sdk.api.entities/-ad-interstitial-state/index.html
[AdInterstitialState.presentIfLoaded]:ad_sdk/com.adition.ad_sdk.api.entities/-ad-interstitial-state/present-if-loaded.html
[AdInterstitialState.hide]:ad_sdk/com.adition.ad_sdk.api.entities/-ad-interstitial-state/hide.html

[AdEventListener]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/index.html
[AdEventListener.unloadRequest]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/unload-request.html

[Interstitial]:com.adition.ad_sdk.api.presentation/-interstitial.html
