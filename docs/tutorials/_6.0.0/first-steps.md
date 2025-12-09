---
layout: default
title: "First steps for working with AdSDK"
nav_order: 1
---

# First steps for working with AdSDK

This tutorial will guide you through the first steps of working with the AdSDK - creating an [AdService].

You can download this [this project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/first-step) which already implements all the steps of this tutorial.

## Section 1: App creation and preparation

Creating and preparing a tutorial application before working with AdSDK.

### Step 1

Create a new Android project and remove any unnecessary code.

Make sure you have added the correct packages from the [readme](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-release/blob/main/README.md).

### Step 2

In real projects, you will most likely use different libraries for DI. For a simple example, we create an object called `ServiceLocator` in `di` package.

In addition, we will create an `Application` class.

**File:** `ServiceLocator.kt`

```kotlin
object ServiceLocator {

}
```

**File:** `App.kt`

```kotlin
class App : Application() {
    override fun onCreate() {
        super.onCreate()
    }
}
```

### Step 3

After that, we will create `MainScreen` in `presentation/screens` as our start screen and add it to the `MainActivity`.

**File:** `MainScreen.kt`

```kotlin
@Composable
fun MainScreen(
    viewModel: MainViewModel = viewModel()
) {
}

class MainViewModel : ViewModel() {
}
```

**File:** `MainActivity.kt`

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TutorialAppTheme {
                MainScreen()
            }
        }
    }
}
```

**Note:** The [AdService.configure] method makes one request to the ad server to get and set a cookie. Make sure you set the necessary [GlobalParameters], if needed..

### Step 4

As the final step in preparing the application, we will create a `PresentationState` in `presentation/entities` that we will use on future screens, and a `PresentationStateContainer` composable in `ui/components` to display this state.

With their help, we can easily monitor the state of the future screens with the transfer of the data we need.

**File:** `PresentationState.kt`

```kotlin
sealed class PresentationState<out Data> {
    object Loading : PresentationState<Nothing>()
    data class Error(val description: String) : PresentationState<Nothing>()
    data class Loaded<Data>(val data: Data) : PresentationState<Data>()
}
```

**File:** `PresentationStateContainer.kt`

```kotlin
@Composable
fun <Data> PresentationStateContainer(
    state: PresentationState<Data>,
    modifier: Modifier = Modifier,
    content: @Composable (data: Data) -> Unit
) {
    when (state) {
        is PresentationState.Loading -> {
            Box(
                contentAlignment = Alignment.Center,
                modifier = modifier
            ) {
                CircularProgressIndicator()
            }
        }
        is PresentationState.Error -> {
            Box(
                contentAlignment = Alignment.Center,
                modifier = modifier
            ) {
                Text(text = state.description, color = Color.Red)
            }
        }
        is PresentationState.Loaded -> content(state.data)
    }
}
```

## Section 2: Creating an AdService

Creating and configuring an [AdService] for later ad creation and loading.

### Step 1

The entry point into the SDK is the [AdServiceProvider] class and the [AdService] interface.

[AdService] is the main class that we will use to create ads in the future.

In turn, [AdServiceProvider] is a class that we can use in the DI container. It is responsible for configuring and storing [AdService]. We add [AdServiceProvider] to the `ServiceLocator` and initialise it by passing `applicationContext` to it.

**File:** `ServiceLocator.kt`

```kotlin
object ServiceLocator {
    lateinit var adServiceProvider: AdServiceProviderInterface
        private set

    fun init(context: Context) {
        adServiceProvider = AdServiceProvider(context)
    }
}
```

**File:** `App.kt`

```kotlin
class App : Application() {
    override fun onCreate() {
        super.onCreate()
        ServiceLocator.init(applicationContext)
    }
}
```

### Step 2

The first thing we need to do is configure [AdService] using the [AdServiceProvider.configure] method.

To do this, we need to pass at least two parameters:

- `networkId` – identifier of your advertising account.
- `parentCoroutineScope` – coroutine scope that defines the lifetime of the [AdService].

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    init {
        viewModelScope.launch {
            adServiceProvider.configure(
                "1800",
                parentCoroutineScope = this
            )
        }
    }
}
```

### Step 3

[AdServiceProvider.configure] returns [AdResult], which is our custom AdSDK implementation of Kotlin's `Result`. [AdResult] contains [AdError] - the only type of error which the SDK supports. We can use [AdResult] to check that the [AdService] has been successfully configured and initialised.

We will process the [AdService] configuration result using the `PresentationState` we created earlier. If the service is configured, the `state` will be changed to `Loaded`; otherwise, we will change it to `Error` with the error description.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    private val _state = MutableStateFlow<PresentationState<Unit>>(
        PresentationState.Loading
    )

    val state = _state.asStateFlow()

    init {
        viewModelScope.launch {
            adServiceProvider.configure(
                "1800",
                parentCoroutineScope = this
            ).get(
                onSuccess = { _state.value = PresentationState.Loaded(Unit) },
                onError = { _state.value = PresentationState.Error(it.description) }
            )
        }
    }
}
```

### Step 4

We can now use `MainViewModel.state` in the `MainScreen` and handle it using `PresentationStateContainer`.

**File:** `MainScreen.kt`

```kotlin
@Composable
fun MainScreen(
    viewModel: MainViewModel = viewModel()
) {
    val uiState by viewModel.state.collectAsState()

    PresentationStateContainer(
        uiState,
        Modifier.fillMaxSize()
    ) {
        Text("Ready")
    }
}
// ...
```

### Step 5

As a final step, let’s prepare the [AdService] so it’s easier to use in the upcoming components. Once again, you’ll likely be using different libraries for DI.

Since our [AdService] will live as a singleton, we ensure that it will only be used after configuration. In this case, we can call the [AdServiceProvider.get] method and be sure that it will never return an error.

**Note:** If you call the [AdServiceProvider.get] method before successfully configuring [AdService], you will receive an [AdError.Configuration] error.

**File:** `ServiceLocator.kt`

```kotlin
object ServiceLocator {
    lateinit var adServiceProvider: AdServiceProviderInterface
        private set

    val adService: AdService
        get() = when (val serviceResult = adServiceProvider.get()) {
            is AdResult.Success -> serviceResult.result
            is AdResult.Error -> throw Exception(serviceResult.error.description)
        }

    fun init(context: Context) {
        adServiceProvider = AdServiceProvider(context)
    }
}
```

Now, if you’ve done everything right, you should see the “Ready” message when you launch the app. This completes the [AdService] configuration, congratulations!

[AdService]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/index.html
[AdServiceProvider]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service-provider/index.html
[AdServiceProvider.configure]:ad_sdk/com.adition.ad_sdk.api/-ad-service-provider/configure.html
[AdServiceProvider.get]:ad_sdk/com.adition.ad_sdk.api/-ad-service-provider/get.html

[AdError]:ad_sdk/com.adition.ad_sdk.api.entities.exception/-ad-error/index.html
[AdError.Configuration]:ad_sdk/com.adition.ad_sdk.api.entities.exception/-ad-error/-configuration/index.html
[AdResult]:ad_sdk/com.adition.ad_sdk.api.entities.exception/-ad-result/index.html
