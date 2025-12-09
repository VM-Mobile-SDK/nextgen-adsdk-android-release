---
layout: default
title: "Creating customised advertising"
nav_order: 9
---

# Creating customised advertising

In this tutorial, we will learn how to create custom ads using AdSDK. This process is the same for both inline and interstitial ads.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/extending-sdk/creating-customised-ad) which has already implemented all steps from this tutorial.

**Note:** In this tutorial, we want to display a picture and frame it, but in real-world projects, your ad can be anything - video, HTML, graphics, etc.

## Section 1: Preparing the app

In this section, we will prepare our project for creating a custom renderer. We will create the logic for decoding the future JSON and move the methods for working with [AdResult] to a separate file.

### Step 1

The server should always be configured to return a custom response when using custom advertising. In this tutorial, the server is configured to give us the following response.

```json
{
    // ...
    ad_name: "tutorialad",
    body: {
        // ...
        ext: {
            // ...
            adData: {
                banner_image: Banner URL,
                framing_width: Framing width,
                is_black_framing: Boolean value – whether the color should be black or white.
            }
        }
    }
}
```

### Step 2

Knowing the data we want to obtain, we can start with the logic of decoding JSON. To do this, create `TutorialRendererResponse.kt` in the `ui/components/tutorial_renderer` package.

**File:** `TutorialRendererResponse.kt`

```kotlin
@Serializable
data class TutorialRendererResponse(val body: Body) {
    val bannerImage: String
        get() = body.ext.adData.bannerImage
    
    val framingWidth: Double
        get() = body.ext.adData.framingWidth
    
    val isBlackFraming: Boolean
        get() = body.ext.adData.isBlackFraming

    @Serializable
    data class Body(val ext: Ext)

    @Serializable
    data class Ext(val adData: AdData)

    @Serializable
    data class AdData(
        @SerialName("banner_image")
        val bannerImage: String,
        @SerialName("framing_width")
        val framingWidth: Double,
        @SerialName("is_black_framing")
        val isBlackFraming: Boolean
    )
}
```

### Step 3

Since the renderer is an extension to the SDK, it should also work with the [AdResult]. Create a `JsonExtensions.kt` file in the `utility/` package. In it, we implement a method for decoding JSON, which returns the [AdResult] type.

**File:** `JsonExtensions.kt`

```kotlin
inline fun <reified T> Json.decodeString(json: String) = try {
    AdResult.Success(decodeFromString<T>(json))
} catch (exception: SerializationException) {
    AdResult.Error(AdError.Decoding(exception))
}
```

### Step 4

The next step is to create `ByteArrayExtensions.kt` in the same package. In this file, we implement the logic for converting `ByteArray` to `ImageBitmap`.

**File:** `ByteArrayExtensions.kt`

```kotlin
fun ByteArray.toImageBitmap(url: String): AdResult<ImageBitmap> {
    val image = runCatching {
        BitmapFactory.decodeByteArray(this, 0, this.size)?.asImageBitmap()
    }.getOrNull()

    return if (image != null) {
        AdResult.Success(image)
    } else {
        val exception = JSONException("Image bitmap decoding failed for URL: $url")
        AdResult.Error(AdError.Decoding(exception))
    }
}
```

### Step 5

The final step of preparation is to transfer all [AdResult]'s extensions methods from `MainScreen.kt` and `AdItem.kt` to a separate file `AdResultExtensions.kt`, which we create in the `utility/` package.

We do this because when creating a renderer, we will have to actively work with [AdResult].

**File:** `AdResultExtensions.kt`

```kotlin
suspend fun <T, ActionResult> AdResult<T>.map(
    action: suspend (T) -> ActionResult
): AdResult<ActionResult> {
    return when (this) {
        is AdResult.Success -> AdResult.Success(action(this.result))
        is AdResult.Error -> AdResult.Error(this.error)
    }
}

suspend fun <T, ActionResult> AdResult<T>.flatMap(
    action: suspend (T) -> AdResult<ActionResult>
): AdResult<ActionResult> {
    return when (this) {
        is AdResult.Success -> action(this.result)
        is AdResult.Error -> AdResult.Error(this.error)
    }
}

suspend fun <T> AdResult<T>.onSuccess(
    action: suspend (T) -> Unit
) : AdResult<T> {
    return when (this) {
        is AdResult.Success -> {
            action(this.result)
            this
        }
        is AdResult.Error -> this
    }
}
```

## Section 2: Creating a business layer

We use the [AdRenderer] interface to create custom advertisements. In this section, we will look at methods related to the business layer of renderer creation.

### Step 1

Create `TutorialRenderer.kt` in the `ui/components/tutorial_renderer` package. In this file, we implement a class that will implement our future [AdRenderer].

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer : AdRenderer {
    
}
```

### Step 2

Let's start with the [AdRenderer.configure] method. This method is the key to creating ads. Within it, you have to perform all the logic to prepare the ad for display - decoding, additional downloads, etc.

**Note:** This method is directly related to the [AdService.makeAdvertisement] and [Advertisement.reload] methods. As soon as this method is completed, the [Advertisement] will be returned to the app.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer : AdRenderer {
    // Will be called every time an ad is loaded or reloaded.
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ): AdResult<Unit> {

    }
}
```

### Step 3

The `adResponse` parameter contains the entire response from the server.

Let’s add the decoding logic to get the data we need to create the ad.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer : AdRenderer {
    private val jsonFormat = Json { ignoreUnknownKeys = true }

    // Will be called every time an ad is loaded or reloaded.
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
}
```

### Step 4

The next step is to load a banner for display. The SDK provides some tools for easy work with advertising resources. In this case, we use [AssetRepository]. We pass it through the constructor.

It can download, cache, and return cached advertising resources. When using it, we don’t need to think about caching, as the whole process takes place internally. Isn’t it convenient?

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository
) : AdRenderer {
    private val jsonFormat = Json { ignoreUnknownKeys = true }

    // Will be called every time an ad is loaded or reloaded.
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
}
```

### Step 5

We use the [AssetRepository.getAsset] method, which can return either [AdError] or [AssetResult].

From it, we can get the loaded data and find out whether it was successfully cached.

**Note:** You can also use [AssetRepository.getAssets] to load multiple advertising resources concurrently.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository
) : AdRenderer {
    private val jsonFormat = Json { ignoreUnknownKeys = true }

    // Will be called every time an ad is loaded or reloaded.
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
        .flatMap { response ->
            assetRepository
                .getAsset(response.bannerImage)
                .onSuccess { assetResult ->
                    assetResult.cacheResult.get(
                        onSuccess = {
                            Log.d("TutorialRenderer", "Banner cached: $it")
                        },
                        onError = {
                            Log.e(
                                "TutorialRenderer",
                                "Banner caching failed: ${it.description}"
                            )
                        }
                    )
                }
                .flatMap { it.data.toImageBitmap(response.bannerImage) }
                .map { Pair(response, it) }
        }
}
```

### Step 6

In addition, the [AdRenderer.configure] method has an `adMetadata` parameter. This [AdMetadata] will be available in the app, and you can use it to pass some additional information from the renderer to the app.

**Note:** If you use interactive elements in the upper right corner of your banner, `isDSAButtonShown` may also be useful for you. If this value is `true`, you should reserve 21 dp for this button.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository
) : AdRenderer {
    private val jsonFormat = Json { ignoreUnknownKeys = true }

    // Will be called every time an ad is loaded or reloaded.
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
        .flatMap { response ->
            // ...
        }
        .onSuccess {
            adMetadata.rendererMetadata = mutableMapOf(
                "custom_data" to "my custom data that will be available in the app"
            )
        }
}
```

### Step 7

We’ve decoded the data we need and retrieved the ad banner, which means it’s time to change the state of our renderer so that the future composable knows it can display this content.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository
) : AdRenderer {
    private var rendererData = MutableStateFlow<RendererData?>(null)
    private val jsonFormat = Json { ignoreUnknownKeys = true }

    // Will be called every time an ad is loaded or reloaded.
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
        .flatMap { response ->
            // ...
        }
        .onSuccess {
            // ...
        }
        .onSuccess { (response, banner) ->
            rendererData.value = RendererData(
                banner = banner,
                framingWidth = response.framingWidth,
                isBlackFraming = response.isBlackFraming
            )
        }
        .map {}

    data class RendererData(
        val banner: ImageBitmap,
        val framingWidth: Double,
        val isBlackFraming: Boolean
    )
}
```

### Step 8

This concludes the configuration of our renderer, so we can now proceed to the next method – [AdRenderer.prepareForReload]. In it, you can implement logic to clear your state and prepare for a reload.

In our case, it’s not very useful, but it can come in handy, for example, if your renderer uses a timer or another process that you would like to reset.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository
) : AdRenderer {
    private var rendererData = MutableStateFlow<RendererData?>(null)
    private val jsonFormat = Json { ignoreUnknownKeys = true }

    // Will be called every time an ad is loaded or reloaded.
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
        // ...

    // Will be called when app want to reload the ad
    override suspend fun prepareForReload(): AdResult<Unit> {
        rendererData.value = null
        return AdResult.Success(Unit)
    }

    data class RendererData(
        // ...
    )
}
```

### Step 9

The final method in this section is [AdRenderer.dispose]. This is an optional method that you can use to clean up your renderer and finish all processes before it is destroyed.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository
) : AdRenderer {
    private var rendererData = MutableStateFlow<RendererData?>(null)
    private val jsonFormat = Json { ignoreUnknownKeys = true }

    // Will be called every time an ad is loaded or reloaded.
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
        // ...

    // Will be called when app want to reload the ad
    override suspend fun prepareForReload(): AdResult<Unit> {
        // ...
    }

    // Called before renderer will be removed
    override fun dispose() {

    }

    data class RendererData(
        // ...
    )
}
```

### Step 10

The most obvious example of using this method is cancelling all internal coroutines.

We create an internal `CoroutineScope` that we will use in the future, and with the [AdRenderer.dispose] method, we can be sure that our renderer will not cause any leaks in the future.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    private var rendererData = MutableStateFlow<RendererData?>(null)
    private val jsonFormat = Json { ignoreUnknownKeys = true }

    // Will be called every time an ad is loaded or reloaded.
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
        // ...

    // Will be called when app want to reload the ad
    override suspend fun prepareForReload(): AdResult<Unit> {
        // ...
    }

    // Called before renderer will be removed
    override fun dispose() {
        rendererData.value = null
        coroutineScope.cancel()
    }

    data class RendererData(
        // ...
    )
}
```

## Section 3: Event management

In the previous section, we implemented the logic associated with loading, reloading, and cleaning your custom ad. The next step will be to implement the processing of ad-related events.

### Step 1

Let’s continue working with our `TutorialRenderer`. Almost all ads need to handle taps, but our renderer doesn’t have this functionality at the moment.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...

    data class RendererData(
        // ...
    )
}
```

### Step 2

In order to execute or notify about an event, we use [AdRendererEventHandler]. In fact, it is an [Advertisement] object that knows how to handle certain events.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...

    data class RendererData(
        // ...
    )
}
```

### Step 3

Now we can implement the method that will be called when the banner is tapped.

**Note:** Some events return [AdResult], which indicates that the renderer may catch errors when executing events. If an error occurs when processing an event, you should not attempt to repeat it, as this is the responsibility of the app, which can do so using [AdEventListener]. You can use this error to debug or change the state of the presentation.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...

    fun onTap() {
        coroutineScope.launch { 
            eventHandler.performTap(AdTapEvent.Tap)
        }
    }

    data class RendererData(
        // ...
    )
}
```

### Step 4

The tap event is not the only event that [AdRendererEventHandler] can handle. You can find all events in the [AdRendererEventHandler] documentation.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...

    fun onTap() {
        coroutineScope.launch {
            eventHandler.performTap(AdTapEvent.Tap)
            // eventHandler.unloadRequest()
            // eventHandler.sendMessage("Message_to_app", "My message to the app")
        }
    }

    data class RendererData(
        // ...
    )
}
```

## Section 4: Creating a presentation layer

Even though our business layer is ready, we still can’t build our project. That’s because the [AdRenderer] requires a presentation layer.

### Step 1

The [AdRenderer] interface has a mandatory method [AdRenderer.RenderAd]. This method is exactly where we need to implement the presentation logic.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...

    @Composable
    override fun RenderAd(modifier: Modifier) {
        
    }
}
```

### Step 2

First, we will observe the `rendererData` to get the data we need.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...

    @Composable
    override fun RenderAd(modifier: Modifier) {
        val data = rendererData.collectAsState()
        data.value?.let {
            
        }
    }
}
```

### Step 3

After that, all we have left to do is implement the banner display with a frame and process tap on this advertisement.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...

    @Composable
    override fun RenderAd(modifier: Modifier) {
        val data = rendererData.collectAsState()
        data.value?.let {
            val borderColor = if (it.isBlackFraming) Color.Black else Color.White
            Box(
                modifier = modifier
                    .border(
                        width = it.framingWidth.dp,
                        color = borderColor
                    )
                    .clickable { onTap() }
            ) {
                Image(
                    bitmap = it.banner,
                    contentDescription = null
                )
            }
        }
    }
}
```

## Section 5: Registering a renderer in the SDK

Although we have created a custom ad, in order for the SDK to use it, we need to pass it to the SDK somehow. Let’s do that.

### Step 1

First of all, let’s get back to our response from the server. As you can see, it includes the `ad_name` field. It is this field that the SDK will use to identify your renderer.

```json
{
    // ...
    ad_name: "tutorialad", // <----------
    body: {
        // ...
        ext: {
            // ...
            adData: {
                banner_image: Banner URL,
                framing_width: Framing width,
                is_black_framing: Boolean value – whether the color should be black or white.
            }
        }
    }
}
```

### Step 2

Let’s go to the `MainScreen.kt` file, the place where we create our [AdService]. This is where we will be able to register our custom renderer.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        // ...
        viewModelScope.launch {
            adServiceProvider
                .configure(
                    "1800",
                    parentCoroutineScope = this,
                    cacheSize = 20u,
                    globalParameters = globalParameters,
                    adRequestGlobalParameters = adRequestGlobalParameters
                )
                // ...
                .onSuccess { adService ->
                    // ...
                }
                .get(
                    onSuccess = { _state.value = PresentationState.Loaded(Unit) },
                    onError = { _state.value = PresentationState.Error(it.description) }
                )
        }
    }
    // ...
}
// ...
```

### Step 3

All we need to do is use the [AdService.registerRenderer] method, passing in the value we expect to receive in the `ad_name` field and the renderer factory method, which we will review in more detail in the next step.

This way, every time the `ad_name` field in the server response is the same as the `String` you passed to this method, the SDK will build the renderer using provided factory method.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        // ...
        viewModelScope.launch {
            adServiceProvider
                .configure(
                    "1800",
                    parentCoroutineScope = this,
                    cacheSize = 20u,
                    globalParameters = globalParameters,
                    adRequestGlobalParameters = adRequestGlobalParameters
                )
                // ...
                .onSuccess { adService ->
                    // ...
                }
                .onSuccess {
                    it.registerRenderer("tutorialad") { serviceLocator ->
                        
                    }
                }
                .get(
                    onSuccess = { _state.value = PresentationState.Loaded(Unit) },
                    onError = { _state.value = PresentationState.Error(it.description) }
                )
        }
    }
    // ...
}
// ...
```

### Step 4

Now let's take a closer look at the factory method. An important parameter is [AdRenderer.ServiceLocator]. You can use it as a DI container or a Service Locator when creating your renderer.

[AdRenderer.ServiceLocator] contains all the information and services that can be used when creating a custom renderer. In our case, these are [AssetRepository] and [AdRendererEventHandler].

**Note:** We will look at other services later in this tutorial. All data and services can be found in the [AdRenderer.ServiceLocator] documentation.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        // ...
        viewModelScope.launch {
            adServiceProvider
                .configure(
                    "1800",
                    parentCoroutineScope = this,
                    cacheSize = 20u,
                    globalParameters = globalParameters,
                    adRequestGlobalParameters = adRequestGlobalParameters
                )
                // ...
                .onSuccess { adService ->
                    // ...
                }
                .onSuccess {
                    it.registerRenderer("tutorialad") { serviceLocator ->
                        TutorialRenderer(
                            assetRepository = serviceLocator.assetRepository,
                            eventHandler = serviceLocator.eventHandler
                        )
                    }
                }
                .get(
                    onSuccess = { _state.value = PresentationState.Loaded(Unit) },
                    onError = { _state.value = PresentationState.Error(it.description) }
                )
        }
    }
    // ...
}
// ...
```

### Step 5

The final step is to add a new [AdRequest]. To do this, open `InlineScreen.kt` and add a new [AdRequest] to the beginning of the `requests` list in the `getDataSource` method.

**File:** `InlineScreen.kt`

```kotlin
// ...
class InlineViewModel(
    private val adService: AdService = ServiceLocator.adService
) : ViewModel() {
    // ...
    private suspend fun getDataSource(): List<AdItemState> = supervisorScope {
        val requests = MutableList(5) {
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

        requests.add(0, AdRequest(contentUnit = "5227780"))

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
// ...
```

Now you can launch the app and see your new custom ad, congratulations!

## Section 6: Advanced management of advertising resources

Our ad can already load and cache an ad banner via [AssetRepository], but there are cases when you want to implement more flexible caching logic, for example, you want to put several ad resources in one folder. In this section, we will look at how to do this.

### Step 1

Return to the `TutorialRenderer.kt` file, and comment out all code related to the [AssetRepository].

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    // private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
        /*
        .flatMap { response ->
            assetRepository
                .getAsset(response.bannerImage)
                .onSuccess { assetResult ->
                    assetResult.cacheResult.get(
                        onSuccess = {
                            Log.d("TutorialRenderer", "Banner cached: $it")
                        },
                        onError = {
                            Log.e(
                                "TutorialRenderer",
                                "Banner caching failed: ${it.description}"
                            )
                        }
                    )
                }
                .flatMap { it.data.toImageBitmap(response.bannerImage) }
                .map { Pair(response, it) }
        }
         */
        .onSuccess {
            // ...
        }
        .onSuccess { (response, banner) ->
            // ...
        }
        .map {}
    // ...
}
```

### Step 2

We will create our own implementation for loading and caching banner.

To do this, we will create a method called `getBannerByteArray`, which we will use in the [AdRenderer.configure] method instead of [AssetRepository.getAsset].

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    // private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...
    override suspend fun configure(
        adResponse: String,
        adMetadata: AdMetadata
    ) = jsonFormat.decodeString<TutorialRendererResponse>(adResponse)
        /*
        // ...
         */
        .flatMap { response ->
            getBannerByteArray(response.bannerImage)
                .flatMap { it.toImageBitmap(response.bannerImage) }
                .map { Pair(response, it) }
            
        }
        .onSuccess {
            // ...
        }
        .onSuccess { (response, banner) ->
            // ...
        }
        .map {}

    private suspend fun getBannerByteArray(url: String): AdResult<ByteArray> {

    }
    // ...
}
```

### Step 3

To create our own implementation of loading and caching, we can use two other interfaces provided by [AdRenderer.ServiceLocator]: the [AssetCache] for working with the cache, and the [AssetRequestService] which can be used to conveniently load ad resources. We pass them through the constructor.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    // private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val cache: AssetCache,
    private val requestService: AssetRequestService,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...
    private suspend fun getBannerByteArray(url: String): AdResult<ByteArray> {

    }
    // ...
}
```

### Step 4

It's time to implement `getBannerByteArray` method. The first thing we will create is [AssetPath]. In our case, we want the file name to be associated with the URL, and this resource is located in the `TutorialRendererResources` folder.

**Note:** When passing the URL to [AssetPath.fromURL], the [AssetPath] will use the MD5 hash of the passed URL as the file name. You can also use the [AssetPath.fromFileName] method if you want to pass the file name yourself.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    // private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val cache: AssetCache,
    private val requestService: AssetRequestService,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...
    private suspend fun getBannerByteArray(url: String): AdResult<ByteArray> {
        val path = AssetPath.fromURL(
            folder = "TutorialRendererResources", // Optional
            url = url
        )
    }
    // ...
}
```

### Step 5

Now we can check if our banner is cached via [AssetCache.read], if so, we will use the cached data.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    // private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val cache: AssetCache,
    private val requestService: AssetRequestService,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...
    private suspend fun getBannerByteArray(url: String): AdResult<ByteArray> {
        val path = AssetPath.fromURL(
            folder = "TutorialRendererResources", // Optional
            url = url
        )

        val cacheResult = cache.read(path).getOrNull()

        if (cacheResult != null) {
            val (bytes, uri) = cacheResult
            Log.d("TutorialRenderer", "Banner loaded from cache: $uri")

            return AdResult.Success(bytes)
        }

        Log.d("TutorialRenderer", "Banner not found in cache")
    }
    // ...
}
```

### Step 6

If not, we can download the banner using [AssetRequestService].

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    // private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val cache: AssetCache,
    private val requestService: AssetRequestService,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...
    private suspend fun getBannerByteArray(url: String): AdResult<ByteArray> {
        val path = AssetPath.fromURL(
            folder = "TutorialRendererResources", // Optional
            url = url
        )

        val cacheResult = cache.read(path).getOrNull()

        if (cacheResult != null) {
            val (bytes, uri) = cacheResult
            Log.d("TutorialRenderer", "Banner loaded from cache: $uri")

            return AdResult.Success(bytes)
        }

        Log.d("TutorialRenderer", "Banner not found in cache")

        return requestService.request(url)
    }
    // ...
}
```

### Step 7

Since the banner has already been loaded, we would like to cache it for future use. To do this, you can use the [AssetCache.write] method.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    // private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val cache: AssetCache,
    private val requestService: AssetRequestService,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...
    private suspend fun getBannerByteArray(url: String): AdResult<ByteArray> {
        val path = AssetPath.fromURL(
            folder = "TutorialRendererResources", // Optional
            url = url
        )

        val cacheResult = cache.read(path).getOrNull()

        if (cacheResult != null) {
            val (bytes, uri) = cacheResult
            Log.d("TutorialRenderer", "Banner loaded from cache: $uri")

            return AdResult.Success(bytes)
        }

        Log.d("TutorialRenderer", "Banner not found in cache")

        return requestService.request(url)
            .onSuccess { bytes ->
                cache.write(path, bytes)
                    .get(
                        onSuccess = {
                            Log.d(
                                "TutorialRenderer",
                                "Banner cached after download: $it"
                            )
                        },
                        onError = {
                            Log.e(
                                "TutorialRenderer",
                                "Banner loaded, but caching failed: ${it.description}"
                            )
                        }
                    )
            }
    }
    // ...
}
```

### Step 8

You can also remove files from the cache if you need to.

**Note:** Most often, you do not need to remove resources manually, as the SDK itself manages the removal of files from the cache using a FIFO strategy and a cache size that is set from the app.

**File:** `TutorialRenderer.kt`

```kotlin
class TutorialRenderer(
    // private val assetRepository: AssetRepository,
    private val eventHandler: AdRendererEventHandler,
    private val cache: AssetCache,
    private val requestService: AssetRequestService,
    private val coroutineScope: CoroutineScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main.immediate
    )
) : AdRenderer {
    // ...
    private suspend fun getBannerByteArray(url: String): AdResult<ByteArray> {
        val path = AssetPath.fromURL(
            folder = "TutorialRendererResources", // Optional
            url = url
        )

        // cache.remove(path)
        // ...
    }
    // ...
}
```

### Step 9

The final step is to pass [AssetCache] and [AssetRequestService] from [AdRenderer.ServiceLocator] instead of [AssetRepository] in `MainScreen.kt`.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        // ...
        viewModelScope.launch {
            adServiceProvider
                .configure(
                    "1800",
                    parentCoroutineScope = this,
                    cacheSize = 20u,
                    globalParameters = globalParameters,
                    adRequestGlobalParameters = adRequestGlobalParameters
                )
                // ...
                .onSuccess { adService ->
                    // ...
                }
                .onSuccess {
                    it.registerRenderer("tutorialad") { serviceLocator ->
                        TutorialRenderer(
                            cache = serviceLocator.assetCache,
                            requestService = serviceLocator.assetRequestService,
                            eventHandler = serviceLocator.eventHandler
                        )
                    }
                }
                .get(
                    onSuccess = { _state.value = PresentationState.Loaded(Unit) },
                    onError = { _state.value = PresentationState.Error(it.description) }
                )
        }
    }
    // ...
}
// ...
```

Congratulations, we have implemented our own caching and loading logic!

[AdService]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/index.html
[AdService.registerRenderer]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/register-renderer.html
[AdService.makeAdvertisement]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/make-advertisement.html

[Advertisement]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/index.html
[Advertisement.reload]:ad_sdk/com.adition.ad_sdk.api.core/-advertisement/reload.html

[AdRenderer]:ad_sdk/com.adition.ad_sdk.api.core/-ad-renderer/index.html
[AdRenderer.configure]:ad_sdk/com.adition.ad_sdk.api.core/-ad-renderer/configure.html
[AdRenderer.prepareForReload]:ad_sdk/com.adition.ad_sdk.api.core/-ad-renderer/prepare-for-reload.html
[AdRenderer.dispose]:ad_sdk/com.adition.ad_sdk.api.core/-ad-renderer/dispose.html
[AdRenderer.RenderAd]:ad_sdk/com.adition.ad_sdk.api.core/-ad-renderer/-render-ad.html
[AdRenderer.ServiceLocator]:ad_sdk/com.adition.ad_sdk.api.core/-ad-renderer/-service-locator/index.html

[AdRendererEventHandler]:ad_sdk/com.adition.ad_sdk.api.core/-ad-renderer-event-handler/index.html

[AssetRepository]:ad_sdk/com.adition.ad_sdk.api.services.asset_repository/-asset-repository/index.html
[AssetRepository.getAsset]:ad_sdk/com.adition.ad_sdk.api.services.asset_repository/-asset-repository/get-asset.html
[AssetRepository.getAssets]:ad_sdk/com.adition.ad_sdk.api.services.asset_repository/-asset-repository/get-assets.html

[AssetCache]:ad_sdk/com.adition.ad_sdk.api.services.cache/-asset-cache/index.html
[AssetCache.read]:ad_sdk/com.adition.ad_sdk.api.services.cache/-asset-cache/read.html
[AssetCache.write]:ad_sdk/com.adition.ad_sdk.api.services.cache/-asset-cache/write.html

[AssetPath]:ad_sdk/com.adition.ad_sdk.api.services.cache/-asset-path/index.html
[AssetPath.fromURL]:ad_sdk/com.adition.ad_sdk.api.services.cache/-asset-path/-companion/from-u-r-l.html
[AssetPath.fromFileName]:ad_sdk/com.adition.ad_sdk.api.services.cache/-asset-path/-companion/from-file-name.html

[AssetRequestService]:ad_sdk/com.adition.ad_sdk.api.services.asset_request_service/-asset-request-service/index.html

[AssetResult]:ad_sdk/com.adition.ad_sdk.api.services.asset_repository/-asset-result/index.html

[AdEventListener]:ad_sdk/com.adition.ad_sdk.api.services.event_listener/-ad-event-listener/index.html

[AdError]:ad_sdk/com.adition.ad_sdk.api.entities.exception/-ad-error/index.html

[AdRequest]:ad_sdk/com.adition.ad_sdk.api.entities.request/-ad-request/index.html

[AdMetadata]:ad_sdk/com.adition.ad_sdk.api.entities.response/-ad-metadata/index.html

[AdResult]:ad_sdk/com.adition.ad_sdk.api.entities.exception/-ad-result/index.html
