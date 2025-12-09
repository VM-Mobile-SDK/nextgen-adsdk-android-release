---
layout: default
title: "Custom handling of target tap URLs"
nav_order: 8
---

# Custom handling of target tap URLs

Sometimes you need to handle taps in your own way. For example, to display ads in the internal browser in the app. In this tutorial, we will learn how to customise the SDK’s tap handling behaviour.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/extending-sdk/create-target-url-handler) which has already implemented all steps from this tutorial.

## Section 1: Preparing the app

In this section, we will create a screen with a browser that will display the target URL when you click on an inline ad.

### Step 1

Create a new `BrowserScreen.kt` file in `presentation/screens` package. In it, we will implement the `BrowserScreen` and `BrowserRoute`.

**File:** `BrowserScreen.kt`

```kotlin
@Serializable
data class BrowserRoute(val url: String)

@Composable
fun BrowserScreen(
    url: String,
    navController: NavController
) {
    val context = LocalContext.current

    AppTopBarContainer(
        title = "Browser",
        onNavigateBack = { navController.navigateUp() }
    ) {
        AndroidView(
            factory = {
                WebView(context).apply {
                    webViewClient = WebViewClient()
                    loadUrl(url)
                }
            },
            update = { it.loadUrl(url) },
            modifier = Modifier.fillMaxSize(),
            onRelease = { webView ->
                webView.stopLoading()
                webView.destroy()
            }
        )
    }
}
```

### Step 2

After that, we add this screen to the navigation in `MainActivity`.

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
                    // ...
                    composable<BrowserRoute> {
                        val route = it.toRoute<BrowserRoute>()
                        BrowserScreen(url = route.url, navController = navController)
                    }
                }
            }
        }
    }
}
```

### Step 3

Since we want `BrowserScreen` to open for inline advertising, open `AdItem.kt`.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest,
    private val parentCoroutineScope: CoroutineScope
) {
    private val _state = MutableStateFlow<PresentationState<ItemData>>(PresentationState.Loading)
    private var advertisement: Advertisement? = null

    val state = _state.asStateFlow()
    val price: Int = Random.nextInt(10, 200)

    // ...
}
// ...
```

### Step 4

We create a sealed class `Event` and `MutableSharedFlow`, which `AdItemState` will use to notify `AdItem` that we need to navigate to `BrowserScreen`.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest,
    private val parentCoroutineScope: CoroutineScope
) {
    private val _state = MutableStateFlow<PresentationState<ItemData>>(PresentationState.Loading)
    private val _events = MutableSharedFlow<Event>()
    private var advertisement: Advertisement? = null

    val state = _state.asStateFlow()
    val events = _events.asSharedFlow()
    val price: Int = Random.nextInt(10, 200)

    // ...

    sealed class Event {
        data class OpenURL(val url: String) : Event()
    }
}
// ...
```

### Step 5

The final step is to collect events inside the composable.

**File:** `AdItem.kt`

```kotlin
@Composable
fun AdItem(state: AdItemState, navController: NavController) {
    val uiState by state.state.collectAsState()
    val events = state.events

    LaunchedEffect(Unit) {
        events.collect { event ->
            when (event) {
                is AdItemState.Event.OpenURL -> {
                    navController.navigate(BrowserRoute(event.url))
                }
            }
        }
    }

    // ...
}
// ...
```

## Section 2: Creating a target URL handler

In this section, we will look at how you can implement custom target URL processing.

### Step 1

Let's continue in `AdItemState`. As you may have noticed, the [AdService.makeAdvertisement] method has a parameter called `targetURLHandler`, which receives [TargetURLHandler].

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest,
    private val parentCoroutineScope: CoroutineScope
) {
    private val _state = MutableStateFlow<PresentationState<ItemData>>(PresentationState.Loading)
    private val _events = MutableSharedFlow<Event>()
    private var advertisement: Advertisement? = null

    val state = _state.asStateFlow()
    val events = _events.asSharedFlow()
    val price: Int = Random.nextInt(10, 200)

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
            // ...
    }

    // ...
}
// ...
```

### Step 2

The [TargetURLHandler] interface designed to handle target URLs. Let's implement it.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest,
    private val parentCoroutineScope: CoroutineScope
) {
    private val _state = MutableStateFlow<PresentationState<ItemData>>(PresentationState.Loading)
    private val _events = MutableSharedFlow<Event>()
    private var advertisement: Advertisement? = null
    private val targetUrlHandler: TargetURLHandler = object : TargetURLHandler {
        
    }

    val state = _state.asStateFlow()
    val events = _events.asSharedFlow()
    val price: Int = Random.nextInt(10, 200)

    // ...

    suspend fun loadAdvertisement() {
        _state.value = PresentationState.Loading

        adService
            .makeAdvertisement(
                adRequest = request,
                placementType  = AdPlacementType.INLINE, // Inline by default
                targetURLHandler = targetUrlHandler,
                adEventListener = eventListener
            )
            // ...
    }

    // ...
}
// ...
```

### Step 3

[TargetURLHandler] interface has two methods, one of which is optional, so let’s start with it.

[TargetURLHandler.isValidURL] will be called every time the SDK wants to validate the target URL. If you return `false`, the SDK will return an [AdError.invalidTargetURL] error in [AdEventListener.tapEventProcessingFailed].

**Note:** If you do not implement this method, all URLs will be considered valid.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    // ...
) {
    private val _state = MutableStateFlow<PresentationState<ItemData>>(PresentationState.Loading)
    private val _events = MutableSharedFlow<Event>()
    private var advertisement: Advertisement? = null
    private val targetUrlHandler: TargetURLHandler = object : TargetURLHandler {
        override fun isValidURL(url: String) = true // Can be skipped
    }
    // ...
}
// ...
```

### Step 4

The second method is mandatory. The [TargetURLHandler.handleURL] will be called every time the SDK wants the URL to be opened for the user. In our case, we want to emit `Event.OpenURL`.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest,
    private val parentCoroutineScope: CoroutineScope
) {
    private val _state = MutableStateFlow<PresentationState<ItemData>>(PresentationState.Loading)
    private val _events = MutableSharedFlow<Event>()
    private var advertisement: Advertisement? = null
    private val targetUrlHandler: TargetURLHandler = object : TargetURLHandler {
        override fun isValidURL(url: String) = true // Can be skipped
        override fun handleURL(url: String) {
            parentCoroutineScope.launch {
                _events.emit(Event.OpenURL(url))
            }
        }
    }
    // ...
}
// ...
```

Now, if you launch the app and tap on the ad, you can see that the target URL opens in the internal browser. Congratulations!

[AdService.makeAdvertisement]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/make-advertisement.html

[TargetURLHandler]:ad_sdk/com.adition.ad_sdk.api.services.event_handler/-target-url-handler/index.html
[TargetURLHandler.isValidURL]:ad_sdk/com.adition.ad_sdk.api.services.event_handler/-target-url-handler/isValidURL.html
[TargetURLHandler.handleURL]:ad_sdk/com.adition.ad_sdk.api.services.event_handler/-target-url-handler/handleURL.html

[AdError.invalidTargetURL]:ad_sdk/com.adition.ad_sdk.api.entities.exception/-ad-error/invalidTargetURL.html

[AdEventListener.tapEventProcessingFailed]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/tap-event-processing-failed.html
