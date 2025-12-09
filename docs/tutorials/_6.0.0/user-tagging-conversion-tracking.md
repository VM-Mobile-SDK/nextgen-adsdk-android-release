---
layout: default
title: "User tagging and conversion tracking"
nav_order: 5
---

# User tagging and conversion tracking

AdSDK provides powerful functionality for user tagging and conversion tracking. In this tutorial we will explore this functionality.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/tag-tracking-tutorial) which has already implemented all steps from this tutorial.

## Section 1: Preparing the app

Before considering user tagging and conversion tracking, we need to prepare the application to have appropriate places to perform tagging and tracking. In this section, we will add an option to purchase the product shown in the inline ad.

### Step 1

First, we will create a reusable component `LabeledContent` in `ui/components` that we will use in the future.

**File:** `LabeledContent.kt`

```kotlin
@Composable
fun LabeledContent(
    label: String,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, fontWeight = FontWeight.Bold)
        content()
    }
}
```

### Step 2

Let’s create a new `BasketScreen`, `BasketViewModel`, and `BasketRoute` in `presentation/screens`.

In it, we create a screen where the user will buy the product, displaying the id, price, quantity, and total cost.

**File:** `BasketScreen.kt`

```kotlin
@Serializable
data class BasketRoute(val id: Int, val price: Int)

@Composable
fun BasketScreen(
    route: BasketRoute,
    viewModel: BasketViewModel = viewModel { BasketViewModel(route.id, route.price) },
    navController: NavController
) {
    val quantity by viewModel.quantity.collectAsState()
    val total by viewModel.total.collectAsState()
    val error by viewModel.error.collectAsState()

    AppTopBarContainer(
        title = "Basket",
        onNavigateBack = { navController.navigateUp() }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            LabeledContent(label = "Item id") { Text(viewModel.id.toString()) }
            LabeledContent(label = "Price") { Text("€${viewModel.price}") }
            LabeledContent(label = "Quantity") { Text(quantity.toString()) }
            IconButton(onClick = { viewModel.onIncreaseQuantity() }) {
                Icon(Icons.Default.Add, contentDescription = "Increase quantity")
            }

            IconButton(onClick = { viewModel.onDecreaseQuantity() }) {
                Icon(Icons.Default.Remove, contentDescription = "Decrease quantity")
            }

            LabeledContent(label = "Total") { Text("€$total") }
            Button(
                onClick = { viewModel.onPurchase() },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Purchase")
            }

            error?.let { errorMessage ->
                Text(
                    text = errorMessage,
                    color = Color.Red
                )
            }
        }
    }
}

class BasketViewModel(
    val id: Int,
    val price: Int
) : ViewModel() {
    private var _quantity = MutableStateFlow(1)
    private var _error = MutableStateFlow<String?>(null)

    val quantity = _quantity.asStateFlow()
    val error = _error.asStateFlow()
    val total: StateFlow<Int> = quantity
        .map { it * price }
        .stateIn(viewModelScope, SharingStarted.Eagerly, price)

    fun onIncreaseQuantity() { _quantity.value += 1 }
    fun onDecreaseQuantity() { if (quantity.value > 1) _quantity.value -= 1 }
    fun onPurchase() {}
}
```

### Step 3

Now we return to the `AdItemState`. We add a random price for the product and pass `parentCoroutineScope` for future use.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest,
    private val parentCoroutineScope: CoroutineScope
) {
    // ...
    val price: Int = Random.nextInt(10, 200)

    suspend fun loadAdvertisement() {
        // ...
    }
    // ...
}
// ...
```

### Step 4

The next step is to add price information and a button to the `AdItem` that will take us to the basket screen.

**File:** `AdItem.kt`

```kotlin
@Composable
fun AdItem(state: AdItemState, navController: NavController) {
    val uiState by state.state.collectAsState()

    PresentationStateContainer(
        uiState,
        modifier = Modifier
            .fillMaxWidth()
    ) { data ->
        Column {
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

            LabeledContent(
                "Price: €${state.price}",
                Modifier.padding(15.dp)
            ) {
                Button(onClick = {
                    navController.navigate(
                        BasketRoute(state.id, state.price)
                    )
                }) {
                    Text("Add to basket")
                }
            }
        }
    }
}
// ...
```

### Step 5

Now we fix the errors in `InlineScreen.kt` after previous changes.

We pass `navController` to `AdItem` and `viewModelScope` to `AdItemState`.

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
                    AdItem(itemState, navController)
                }
            }
        }
    }
}

class InlineViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    // ...
    private suspend fun getDataSource(): List<AdItemState> = supervisorScope {
        // ...
        requests
            .mapIndexed { index, request ->
                async {
                    val itemState = AdItemState(
                        index,
                        adService,
                        request,
                        viewModelScope
                    )

                    itemState.loadAdvertisement()
                    itemState
                }
            }
            .awaitAll()
    }
}
```

### Step 6

And finally, as a last step, we add `BasketRoute` to navigation.

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
                    composable<BasketRoute> {
                        val route = it.toRoute<BasketRoute>()
                        BasketScreen(route = route, navController = navController)
                    }
                }
            }
        }
    }
}
```

Now our app is ready to create purchases!

## Section 2: User tagging

The SDK provides functionality to put a user identifier, e.g. cookie id, into a retargeting segment (to tag a user). This allows advertisers to create a segment of users with certain interests or affinities, and to re-advertise to this segment (retargeting). In this section, we will look at how we can perform a tag request using the AdSDK.

### Step 1

Let’s continue with the `AdItem.kt` file. Let’s imagine a situation where we need to tag a user when he adds an item to the basket.

To do this, first of all, we add the `onBasket` method to the `AdItemState`, and call it when the basket button is tapped.

**File:** `AdItem.kt`

```kotlin
@Composable
fun AdItem(state: AdItemState, navController: NavController) {
    val uiState by state.state.collectAsState()

    PresentationStateContainer(
        uiState,
        modifier = Modifier
            .fillMaxWidth()
    ) { data ->
        Column {
            // ...

            LabeledContent(
                "Price: €${state.price}",
                Modifier.padding(15.dp)
            ) {
                Button(onClick = {
                    state.onBasket()
                    navController.navigate(
                        BasketRoute(state.id, state.price)
                    )
                }) {
                    Text("Add to basket")
                }
            }
        }
    }
}

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

    fun onBasket() {

    }
    // ...
}
// ...
```

### Step 2

Now we’re ready to tag the user. You use [TagRequest] to describe the tagging request. It consists of [TagRequest.Tag]s with a key, a subkey, and a value. In our case, we’ll use key as the name of our store, subkey as the product category, and value as our product id.

**Note:** In real projects, the advertiser should provide you with information on the tag parameters.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest,
    private val parentCoroutineScope: CoroutineScope
) {
    // ...
    fun onBasket() {
        val request = TagRequest(
            tags = listOf(
                TagRequest.Tag(
                    key = "MyTutorialStore",
                    subKey = "Movies",
                    value = "$id"
                )
            ),
            timeout = null // Can be skipped
        )
    }
}
// ...
```

### Step 3

You can perform a user tagging request with [AdService.tagUser] method.

**File:** `AdItem.kt`

```kotlin
// ...
class AdItemState(
    val id: Int,
    private val adService: AdService,
    private val request: AdRequest,
    private val parentCoroutineScope: CoroutineScope
) {
    // ...
    fun onBasket() {
        val request = TagRequest(
            tags = listOf(
                TagRequest.Tag(
                    key = "MyTutorialStore",
                    subKey = "Movies",
                    value = "$id"
                )
            ),
            timeout = null // Can be skipped
        )

        parentCoroutineScope.launch { 
            adService.tagUser(request)
                .get(
                    onSuccess = { 
                        Log.d("AdItemState", "Successfully tagged user for item $id") 
                    },
                    onError = {
                        Log.d("AdItemState", "Failed to tag user for item $id: ${it.description}")
                    }
                )
        }
    }
}
// ...
```

Congratulations, now our app can tag the user who added the item to the basket!

## Section 3: Conversion tracking

The SDK allows you to track conversions. This is useful for advertisers, as conversion details would be available in posttracking reports via the adserver. In this section, we will look at how we can perform a tracking request using the AdSDK.

### Step 1

Let’s open the `BasketScreen.kt` file and focus on the `BasketViewModel`.

The conversion, in our case, is the purchase of an item in the basket.

**File:** `BasketScreen.kt`

```kotlin
// ...
class BasketViewModel(
    val id: Int,
    val price: Int
) : ViewModel() {
    private var _quantity = MutableStateFlow(1)
    private var _error = MutableStateFlow<String?>(null)

    val quantity = _quantity.asStateFlow()
    val error = _error.asStateFlow()
    val total: StateFlow<Int> = quantity
        .map { it * price }
        .stateIn(viewModelScope, SharingStarted.Eagerly, price)

    fun onIncreaseQuantity() { _quantity.value += 1 }
    fun onDecreaseQuantity() { if (quantity.value > 1) _quantity.value -= 1 }
    fun onPurchase() {}
}
```

### Step 2

A conversion tracking request is described using [TrackingRequest]. In it, we pass all the parameters related to the purchase.

**Note:** In real projects, the advertiser should provide you with information on the `landingpageId` and `trackingspotId` parameters.

**File:** `BasketScreen.kt`

```kotlin
// ...
class BasketViewModel(
    val id: Int,
    val price: Int
) : ViewModel() {
    private var _quantity = MutableStateFlow(1)
    private var _error = MutableStateFlow<String?>(null)

    val quantity = _quantity.asStateFlow()
    val error = _error.asStateFlow()
    val total: StateFlow<Int> = quantity
        .map { it * price }
        .stateIn(viewModelScope, SharingStarted.Eagerly, price)

    fun onIncreaseQuantity() { _quantity.value += 1 }
    fun onDecreaseQuantity() { if (quantity.value > 1) _quantity.value -= 1 }
    fun onPurchase() {
        val request = TrackingRequest(
            landingPageId = 0,
            trackingSpotId = 0,
            orderId = "My purchase id", // Can be skipped
            price = price.toFloat(), // Can be skipped
            total = total.value.toFloat(), // Can be skipped
            quantity = quantity.value, // Can be skipped
            itemNumber = "$id", // Can be skipped
            description = null, // Can be skipped
            timeout = null // Can be skipped
        )
    }
}
```

### Step 3

Now we can perform the tracking request. We use [AdService.trackingRequest] for this purpose, and in case of an error, we display it on the screen.

**File:** `BasketScreen.kt`

```kotlin
// ...
class BasketViewModel(
    val id: Int,
    val price: Int,
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    private var _quantity = MutableStateFlow(1)
    private var _error = MutableStateFlow<String?>(null)

    val quantity = _quantity.asStateFlow()
    val error = _error.asStateFlow()
    val total: StateFlow<Int> = quantity
        .map { it * price }
        .stateIn(viewModelScope, SharingStarted.Eagerly, price)

    fun onIncreaseQuantity() { _quantity.value += 1 }
    fun onDecreaseQuantity() { if (quantity.value > 1) _quantity.value -= 1 }
    fun onPurchase() {
        val request = TrackingRequest(
            landingPageId = 0,
            trackingSpotId = 0,
            orderId = "My purchase id", // Can be skipped
            price = price.toFloat(), // Can be skipped
            total = total.value.toFloat(), // Can be skipped
            quantity = quantity.value, // Can be skipped
            itemNumber = "$id", // Can be skipped
            description = null, // Can be skipped
            timeout = null // Can be skipped
        )

        viewModelScope.launch {
            adService.trackingRequest(request)
                .get(
                    onSuccess = {
                        Log.d("BasketViewModel", "Successfully tracked purchase with id: $id")
                    },
                    onError = { _error.value = it.description }
                )
        }
    }
}
```

Congratulations, our app can now track purchase!

[TagRequest]:ad_sdk/com.adition.ad_sdk.api.entities.request/-tag-request/index.html
[TagRequest.Tag]:ad_sdk/com.adition.ad_sdk.api.entities.request/-tag-request/-tag/index.html

[TrackingRequest]:ad_sdk/com.adition.ad_sdk.api.entities.request/-tracking-request/index.html

[AdService.tagUser]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/tag-user.html
[AdService.trackingRequest]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/tracking-request.html
