---
layout: default
title: "Create and display inline ads"
nav_order: 2
---

# Create and display inline ads

This tutorial will guide you how to create and display inline ads. An inline ad is an ad created to be displayed in your view hierarchy.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/create-inline-ads) which has already implemented all steps from this tutorial.

## Section 1: Creating an inline ads

Your [AdService] is ready for creating advertisements, so in this section, we will create an [Advertisement] for future ad display.

### Step 1

Lets create an `AdItem` composable and an `AdItemState` class in `presentation/screens/inline_screen/components`. Since we plan to display multiple ads in the `LazyColumn`, we will use it to display a single ad.

We pass the [AdService] to the constructor, which will be used to create the ad later.

**File:** `AdItem.kt`

```kotlin
@Composable
fun AdItem() {
    Text(text = "Advertisement should be here")
}

class AdItemState(
    val id: Int,
    private val adService: AdService
) {
    suspend fun loadAdvertisement() {
    }
}
```

### Step 2

To create advertisements, we use the [AdService.makeAdvertisement] method. The most important parameter now is [AdRequest], which describes the request that will be sent to the server to receive ads.

Let’s pass it through the constructor and look at it in more detail later.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    suspend fun loadAdvertisement() {
        adService
            .makeAdvertisement(
                adRequest = request,
                placementType  = AdPlacementType.INLINE, // Inline by default
                targetURLHandler = null, // Can be skipped
                adEventListener = null // Can be skipped
            )
    }
}
```

### Step 3

The [AdService.makeAdvertisement] method returns [AdResult]. If the ad is created and loaded successfully, you will receive the downloaded [Advertisement] object. You can think of it as a ViewModel that holds the data and state of your ad.

We store this object and create `ItemData`, which we will pass using `PresentationState` to our composable.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    private val _state = MutableStateFlow<PresentationState<ItemData>>(PresentationState.Loading)
    private var advertisement: Advertisement? = null

    val state = _state.asStateFlow()

    suspend fun loadAdvertisement() {
        _state.value = PresentationState.Loading

        adService
            .makeAdvertisement(
                adRequest = request,
                placementType  = AdPlacementType.INLINE, // Inline by default
                targetURLHandler = null, // Can be skipped
                adEventListener = null // Can be skipped
            )
            .get(
                onSuccess = { ad ->
                    val data = ItemData(ad)
                    advertisement = ad
                    _state.value = PresentationState.Loaded(data)
                },
                onError = { error ->
                    _state.value = PresentationState.Error(error.description)
                }
            )
    }

    data class ItemData(
        val advertisement: Advertisement
    )
}
```

### Step 4

Since [Advertisement] is not a lifecycle-aware object and contains logic related to coroutines, we need to destroy [Advertisement] when we no longer need it. To do this, we must use the [Advertisement.dispose] method.

We add it to `onCleared` and will call it later from `ViewModel`.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    // ...

    fun onCleared() {
        advertisement?.dispose()
        advertisement = null
    }

    // ...
}
```

## Section 2: Displaying advertisement

If we have an [Advertisement] instance, it remains to add a `Composable` to present it. In this section, we will figure out how to do this.

### Step 1

We can use [Ad] to display advertisement, which serves as the presentation layer for your inline ad.

**File:** `AdItem.kt`

```kotlin
@Composable
fun AdItem(state: AdItemState) {
    val uiState by state.state.collectAsState()

    PresentationStateContainer(
        uiState,
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(2.0f)
    ) { data ->
        Box(
            Modifier.fillMaxWidth()
        ) {
            Ad(
                advertisement = data.advertisement,
                Modifier.fillMaxWidth()
            )
        }
    }
}
// ...
```

### Step 2

The only problem at the moment is that we don't know the size of the advertisement. But we know that [Advertisement] stores advertising data. Let’s try to get it!

We can obtain all possible advertising data using [Advertisement.getMetadata] method that returns [AdMetadata] instance. This is the one we will use to obtain the size data.

We will extend `ItemData` and map the result of [AdService.makeAdvertisement] to obtain [AdMetadata.aspectRatio].

**Note:** The [AdMetadata] is optional, but you can be sure that if you have not called the [Advertisement.reload] method, the object will be present.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest
) {
    private val _state = MutableStateFlow<PresentationState<ItemData>>(PresentationState.Loading)
    private var advertisement: Advertisement? = null

    val state = _state.asStateFlow()

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

    fun onCleared() {
        advertisement?.dispose()
        advertisement = null
    }

    data class ItemData(
        val advertisement: Advertisement,
        val aspectRatio: Float?
    )
}

private suspend fun <T, ActionResult> AdResult<T>.map(
    action: suspend (T) -> ActionResult
): AdResult<ActionResult> {
    return when (this) {
        is AdResult.Success -> AdResult.Success(action(this.result))
        is AdResult.Error -> AdResult.Error(this.error)
    }
}
```

### Step 3

All we have left to do is use the aspect ratio provided, if it is specified in the [Advertisement]. If not, we will use the default 2:1.

After that, we can be sure that the ad size is displayed correctly.

**File:** `AdItem.kt`

```kotlin
@Composable
fun AdItem(state: AdItemState) {
    val uiState by state.state.collectAsState()

    PresentationStateContainer(
        uiState,
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(2.0f)
    ) { data ->
        Box(
            Modifier
                .fillMaxWidth()
                .aspectRatio(data.aspectRatio ?: 2.0f)
        ) {
            Ad(
                advertisement = data.advertisement,
                Modifier
                    .fillMaxWidth()
                    .aspectRatio(data.aspectRatio ?: 2.0f)
            )
        }
    }
}
// ...
```

## Section 3: Creating and displaying a list of advertisements

Our `AdItem` is ready to load and display a single ad. In this section, we will create a new screen to display the list of advertisements.

### Step 1

First, we will create the top navigation bar, which we will use on future screen.

Create `AppTopBarContainer` in `ui/components`.

**File:** `AppTopBarContainer.kt`

```kotlin
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppTopBarContainer(
    title: String,
    modifier: Modifier = Modifier,
    onNavigateBack: () -> Unit,
    content: @Composable () -> Unit = {}
) {
    Column {
        Surface(
            modifier = modifier.fillMaxWidth(),
            color = MaterialTheme.colorScheme.primaryContainer,
            contentColor = MaterialTheme.colorScheme.onPrimaryContainer
        ) {
            TopAppBar(
                title = { Text(title) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        }

        content()
    }
}
```

### Step 2

The next step will be to create `InlineScreen` composable and `InlineViewModel` in `presentation/screens/inline_screen`.

**File:** `InlineScreen.kt`

```kotlin
@Composable
fun InlineScreen(
    viewModel: InlineViewModel = viewModel(),
    navController: NavController
) {
}

class InlineViewModel(
    private val adService: AdService = ServiceLocator.adService
): ViewModel() {
}
```

### Step 3

After that, we need to create routes for each of the screens, add a transition from `MainScreen` to `InlineScreen`, and connect navigation in `MainActivity`.

**File:** `InlineScreen.kt`

```kotlin
@Serializable
data object InlineRoute

// ...
```

**File:** `MainScreen.kt`

```kotlin
@Serializable
data object MainRoute

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
        }
    }
}

// ...
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
                }
            }
        }
    }
}
```

### Step 4

Let's continue working with `InlineScreen`. This screen is responsible for creating `AdItemState` and displaying `AdItem`s.

**Note:** We start the process of loading all the ads as soon as the screen appears, but you can implement your own logic with bash loading on scroll, or load ads before the screen is displayed, it all depends on your needs.

**File:** `InlineScreen.kt`

```kotlin
// ...
@Composable
fun InlineScreen(
    viewModel: InlineViewModel = viewModel(),
    navController: NavController
) {
    val uiState by viewModel.state.collectAsState()

    PresentationStateContainer(
        uiState,
        Modifier.fillMaxSize()
    ) { dataSource ->
        AppTopBarContainer(
            title = "Inline Screen",
            onNavigateBack = { navController.navigateUp() }
        ) {
            LazyColumn(
                modifier = Modifier.fillMaxSize()
            ) {
                items(
                    dataSource,
                    key = { it.id }
                ) { itemState ->
                    AdItem(itemState)
                }
            }
        }
    }
}

class InlineViewModel(
    private val adService: AdService = ServiceLocator.adService
): ViewModel() {
    private val dataSource = mutableListOf<AdItemState>()
    private val _state = MutableStateFlow<PresentationState<List<AdItemState>>>(
        PresentationState.Loading
    )

    val state = _state.asStateFlow()

    init {
        viewModelScope.launch {
            val cellStates = getDataSource()
            dataSource.addAll(cellStates)
            _state.value = PresentationState.Loaded(cellStates)
        }
    }

    private suspend fun getDataSource(): List<AdItemState> {}
}
```

### Step 5

Let’s focus our attention on the `getDataSource` method, because in this method we will implement the logic for filling the `dataSource`.

As you may recall, to create an ad, we need an [AdRequest]. It describes the request that will be sent to the server to get an ad.

The only mandatory parameter when creating the [AdRequest] is [AdRequest.contentUnit] or [AdRequest.learningTag]. Content unit is unique ID of a content space.

**Note:** You can also use [AdRequest.learningTag], but we use [AdRequest.contentUnit] in this tutorial because it is more commonly used.

**File:** `InlineScreen.kt`

```kotlin
// ...
class InlineViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    // ...
    private suspend fun getDataSource(): List<AdItemState> = supervisorScope {
        val requests = List(5) {
            AdRequest(
                contentUnit = "4810915",
                profiles = hashMapOf(), // Can be skipped
                keywords = listOf(), // Can be skipped
                window = null, // Can be skipped
                timeoutAfterSeconds = 10u, // Can be skipped
                gdprPd = null, // Can be skipped
                campaignId = null, // Can be skipped
                bannerId = null, // Can be skipped
                isSHBEnabled = null, // Can be skipped
                dsa = null // Can be skipped
            )
        }
    }
}
```

### Step 6

Time to load ads! Since we want to load all the ads in parallel, we’ll use a `async` coroutine to for that.

**File:** `InlineScreen.kt`

```kotlin
// ...
class InlineViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    // ...
    private suspend fun getDataSource(): List<AdItemState> = supervisorScope {
        val requests = List(5) {
            AdRequest(
                contentUnit = "4810915",
                profiles = hashMapOf(), // Can be skipped
                keywords = listOf(), // Can be skipped
                window = null, // Can be skipped
                timeoutAfterSeconds = 10u, // Can be skipped
                gdprPd = null, // Can be skipped
                campaignId = null, // Can be skipped
                bannerId = null, // Can be skipped
                isSHBEnabled = null, // Can be skipped
                dsa = null // Can be skipped
            )
        }

        requests
            .mapIndexed { index, request ->
                async {
                    val itemState = AdItemState(
                        index,
                        adService,
                        request
                    )

                    itemState.loadAdvertisement()
                    itemState
                }
            }
            .awaitAll()
    }
}
```

### Step 7

At this point, we can already see the list of advertisements, but in order to avoid possible leaks, we must clear the [Advertisement]s when we no longer need them.

To do this, we will use the `onCleared` method.

**File:** `InlineScreen.kt`

```kotlin
// ...
class InlineViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    // ...
    override fun onCleared() {
        super.onCleared()
        dataSource.onCleared()
    }
    // ...
}

private fun List<AdItemState>.onCleared() = forEach { it.onCleared() }
```

Now, if you did everything right, you can launch the app and see the list of advertisement. Congratulations!

[AdService]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/index.html
[AdService.makeAdvertisement]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/make-advertisement.html

[AdRequest]:ad_sdk/com.adition.ad_sdk.api.entities.request/-ad-request/index.html
[AdRequest.contentUnit]:ad_sdk/com.adition.ad_sdk.api.entities.request/-ad-request/content-unit.html
[AdRequest.learningTag]:ad_sdk/com.adition.ad_sdk.api.entities.request/-ad-request/learning-tag.html

[AdMetadata]:ad_sdk/com.adition.ad_sdk.api.entities.response/-ad-metadata/index.html
[AdMetadata.aspectRatio]:ad_sdk/com.adition.ad_sdk.api.entities.response/-ad-metadata/aspect-ratio.html

[AdResult]:ad_sdk/com.adition.ad_sdk.api.entities.exception/-ad-result/index.html

[Advertisement]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/index.html
[Advertisement.dispose]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/dispose.html
[Advertisement.getMetadata]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/getMetadata.html
[Advertisement.reload]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/reload.html

[Ad]:ad_sdk/com.adition.ad_sdk.api.presentation/-ad.html
