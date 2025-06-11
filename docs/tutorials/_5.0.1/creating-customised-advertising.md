---
layout: default
title: "Creating customised advertising"
nav_order: 8
---

# Creating customised advertising

In this tutorial, we will learn how to create custom ads using AdSDK. This process is the same for both inline and interstitial ads.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/extending-sdk/creating-customised-ad) which has already implemented all steps from this tutorial.

**Note:** In this tutorial, we want to display a picture and frame it, but in real-world projects, your ad can be anything - video, HTML, graphics, etc.

## Section 1: Creating a custom renderer

We will create an custom composable ad. Let’s start by using the [AdComposeRenderer].

### Step 1

Create a new file TutorialRenderer and TutorialRenderer class on it.

### Step 2

`TutorialRenderer` need to implement [AdComposeRenderer], override [AdComposeRenderer.configure], and [AdComposeRenderer.RenderAd].

We'll take a closer look at each of these methods in separate sections.

**File:** `TutorialRenderer.kt`

```kotlin
internal class TutorialRenderer : AdComposeRenderer {

    override suspend fun configure(
        rendererEventHandler: AdRendererEventHandler,
        adMetadata: AdMetadata,
        adResponseBundle: AdResponseBundle
    ): AdResult<Unit> {}

    @Composable
    override fun RenderAd(modifier: Modifier) {}
}
```

## Section 2: Get the data

In this section, we will learn how the renderer can receive data from the ad server using the [AdComposeRenderer.configure] method.

### Step 1

The server should always be configured to return a custom response when using custom advertising. In this tutorial, the server is configured to give us the following response.

```json
{
    // ...
    "ad_name": "tutorialad",
    "body": {
        // ...
        "ext": {
            // ...
            "adData": {
                "banner_image": "Banner URL",
                "framing_width": "Framing width",
                "is_black_framing": "Boolean value – whether the color should be black or white."
            }
        }
    }
}
```

### Step 2

We will use `kotlinx.serialization.json.JsonObject` to parse the `JSON`. 

We have to import it in our build gradle file.

**File:** `build.gradle.kts`

```kotlin
implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")
```

### Step 3

The [AdComposeRenderer.configure] method is the key to creating ads. Within it, you have to perform all the logic to prepare the ad for display - decoding, additional downloads, etc.

**Note**: This method is directly related to the [AdService.makeAdvertisement] and [Advertisement.reload] methods. As soon as this method is completed, the [Advertisement] will be returned to the app.

The [AdResponseBundle] parameter contains the entire response from the server we need. It contains the data as [AdResponse] and `JSON` as a string. We will keep it easy and just use a method to get the 3 values from the [AdResponse]. You could do this with your own decoding logic or anything similar and use `JSON` string. 

**File:** `TutorialRenderer.kt`

```kotlin
internal class TutorialRenderer : AdComposeRenderer {
    private var framingWidth: Int = 1
    private var isBlackFraming: Boolean = false

    override suspend fun configure(
        rendererEventHandler: AdRendererEventHandler,
        adMetadata: AdMetadata,
        adResponseBundle: AdResponseBundle
    ): AdResult<Unit> {
        val adDataMap = adResponseBundle.adResponse.body?.ext?.adData as? Map<*, *>
            ?: return AdResult.Error(AdError.Decoding(Exception("adData is missing.")))

        val jsonString = JSONObject(adDataMap).toString()
        val adData = Json.parseToJsonElement(jsonString).jsonObject

        val bannerURL = adData["banner_image"]?.jsonPrimitive?.content
            ?: return AdResult.Error(AdError.Decoding(Exception("Banner URL is null.")))

        framingWidth = adData["framing_width"]?.jsonPrimitive?.intOrNull ?: framingWidth
        isBlackFraming = adData["is_black_framing"]?.jsonPrimitive?.booleanOrNull ?: isBlackFraming
        
    }

    @Composable
    override fun RenderAd(modifier: Modifier) {}
}
```
### Step 4

We will use the banner URL to get the image from the cache or download it from the server. We get a cache instance with [AdService.getCacheInstance] and can use [DriveCache.find] to get the image from cache. If not, we will use [AdRendererEventHandler.downloadBitmap] to download the image.

We will take a closer look at [AdRendererEventHandler] in the next sections.

**File:** `TutorialRenderer.kt`

```kotlin
internal class TutorialRenderer : AdComposeRenderer {
    private lateinit var eventHandler: AdRendererEventHandler   
    private var framingWidth: Int = 1
    private var isBlackFraming: Boolean = false

    override suspend fun configure(
        rendererEventHandler: AdRendererEventHandler,
        adMetadata: AdMetadata,
        adResponseBundle: AdResponseBundle
    ): AdResult<Unit> {
        this.eventHandler = rendererEventHandler

        val adDataMap = adResponseBundle.adResponse.body?.ext?.adData as? Map<*, *>
            ?: return AdResult.Error(AdError.Decoding(Exception("adData is missing.")))

        val jsonString = JSONObject(adDataMap).toString()
        val adData = Json.parseToJsonElement(jsonString).jsonObject

        val bannerURL = adData["banner_image"]?.jsonPrimitive?.content
            ?: return AdResult.Error(AdError.Decoding(Exception("Banner URL is null.")))

        framingWidth = adData["framing_width"]?.jsonPrimitive?.intOrNull ?: framingWidth
        isBlackFraming = adData["is_black_framing"]?.jsonPrimitive?.booleanOrNull ?: isBlackFraming

        val bannerResult = getBanner(bannerURL)
        return when (bannerResult) {
            is AdResult.Success -> {
                imageBitmap = bannerResult.result
                AdResult.Success(Unit)
            }

            is AdResult.Error -> AdResult.Error(bannerResult.error)
        }
    }

    private suspend fun getBanner(url: String): AdResult<ImageBitmap> {
        val cachedBanner = getCachedBanner(url)

        if (cachedBanner != null) {
            return AdResult.Success(cachedBanner)
        }

        return loadAndCacheBanner(url)
    }

    private suspend fun getCachedBanner(url: String): ImageBitmap? {
        val cache = AdService.getCacheInstance().getOrNull()
        val banner = cache?.find(url)?.getOrNull()

        if (banner != null) {
            return BitmapFactory.decodeByteArray(
                banner.data,
                0,
                banner.data.size
            )?.asImageBitmap()
        }

        return null
    }

    private suspend fun loadAndCacheBanner(url: String): AdResult<ImageBitmap> {
        val bitmapResult = eventHandler.downloadBitmap(url)

        return when (bitmapResult) {
            is AdResult.Error -> AdResult.Error(bitmapResult.error)
            is AdResult.Success -> {
                AdResult.Success(bitmapResult.result.asImageBitmap())
            }
        }
    }

    @Composable
    override fun RenderAd(modifier: Modifier) {}
}
```

## Section 3: Create the renderer UI

Now our data is ready. Lets create the renderer UI.

To do this, we will use the [AdComposeRenderer.RenderAd] composable method.

### Step 1

We will only show a framed image when the `imageBitmap` is loaded.

**File:** `TutorialRenderer.kt`

```kotlin
internal class TutorialRenderer : AdComposeRenderer {
    private lateinit var eventHandler: AdRendererEventHandler
    private var imageBitmap by mutableStateOf<ImageBitmap?>(null)
    private var framingWidth: Int = 1
    private var isBlackFraming: Boolean = false
    
    // ...

    @Composable
    override fun RenderAd(modifier: Modifier) {
        val imageBitmap = rememberUpdatedState(this.imageBitmap)
        imageBitmap.value?.let {
            // Framed image goes here.
        }
    }
}
```

### Step 2

We create a box for the framing and show the image inside.

**File:** `TutorialRenderer.kt`

```kotlin
internal class TutorialRenderer : AdComposeRenderer {
    private lateinit var eventHandler: AdRendererEventHandler
    private var imageBitmap by mutableStateOf<ImageBitmap?>(null)
    private var framingWidth: Int = 1
    private var isBlackFraming: Boolean = false
    
    // ...

    @Composable
    override fun RenderAd(modifier: Modifier) {
        val imageBitmap = rememberUpdatedState(this.imageBitmap)
        imageBitmap.value?.let {
            val borderColor = if (isBlackFraming) Color.Black else Color.White
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(it.width.toFloat() / it.height)
                    .border(
                        width = framingWidth.dp,
                        color = borderColor
                    )
            ) {
                Image(
                    bitmap = it,
                    contentDescription = null
                )
            }
        }
    }
}
```

## Section 4: Event management

The next step will be to implement the processing of ad-related events. We can do this using the [AdRendererEventHandler].

## Step 1

We already used [AdRendererEventHandler.downloadBitmap].

Here are all event method we can use:
- [AdRendererEventHandler.downloadBitmap]
- [AdRendererEventHandler.performCustomTrackingEvent]
- [AdRendererEventHandler.performTapEvent]
- [AdRendererEventHandler.sendMessage]
- [AdRendererEventHandler.unloadRequest]

## Step 2

We will use [AdRendererEventHandler.performTapEvent] to trigger the tap event.

**Note**: You can see all possible types of tap events and the difference between them in the [AdTapEvent] documentation.

**File:** `TutorialRenderer.kt`

```kotlin
internal class TutorialRenderer : AdComposeRenderer {
    private lateinit var eventHandler: AdRendererEventHandler
    
    // ...

    @Composable
    override fun RenderAd(modifier: Modifier) {
        val imageBitmap = rememberUpdatedState(this.imageBitmap)
        imageBitmap.value?.let {
            val borderColor = if (isBlackFraming) Color.Black else Color.White
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(it.width.toFloat() / it.height)
                    .border(
                        width = framingWidth.dp,
                        color = borderColor
                    )
            ) {
                Image(
                    bitmap = it,
                    contentDescription = null,
                    modifier.clickable { eventHandler.performTapEvent(AdTapEvent.Tap) }
                )
            }
        }
    }
}
```

## Section 5: Prepare to present the custom ad

Let's create a screen to present our custom ad.

## Step 1

Create a new file `CustomAd`.

## Step 2 

Add a `CustomAd` composable and a `CustomAdViewModel`.

**File:** `CustomAd.kt`

```kotlin
@Composable
fun CustomAd() {
    val viewModel: CustomAdViewModel = viewModel()
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

class CustomAdViewModel: ViewModel() {
    private val adRequest = AdRequest("5227780")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)

    init {
        viewModelScope.launch {
            AdService.makeAdvertisement(
                adRequest,
            ).get(
                onSuccess = {
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("CustomAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

## Step 3

Add the `CustomAd` into the `MainScreen`.

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
            CustomAd()
        }
    }
}
```

## Section 6: Registering a renderer in the SDK

Although we have created a custom ad, in order for the SDK to use it, we need to pass it to the SDK somehow. Let’s do that.

## Step 1

First of all, let’s get back to our response from the server. As you can see, it includes the `ad_name` field. It is this field that the SDK will use to identify your renderer.

```json
{
    // ...
    "ad_name": "tutorialad", // <-------
    "body": {
        // ...
        "ext": {
            // ...
            "adData": {
                "banner_image": "Banner URL",
                "framing_width": "Framing width",
                "is_black_framing": "Boolean value – whether the color should be black or white."
            }
        }
    }
}
```

## Step 2

All we need to do is use the [AdService.registerRenderer] method, passing in the value we expect to receive in the `ad_name` field and the renderer factory. This way, every time the `ad_name` field in the server response is the same as the string you passed to this method, the SDK will display the `TutorialRenderer`.

### Step 3

We call the [AdService.registerRenderer] method in the `App` class.

**File:** `App.kt`

```kotlin
class App: Application() {
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    val adServiceStatus = MutableLiveData<ResultState<Unit>>()

    override fun onCreate() {
        super.onCreate()

        coroutineScope.launch {
            val initResult = AdService.configure(
                "1800",
                applicationContext,
                cacheSizeInMb = 20u,
                cachePath = cacheDir.path + "/tutorialApp/"
            )

            initResult.get(
                onSuccess =  {
                    launch {
                        AdService.registerRenderer("tutorialad") {
                            TutorialRenderer()
                        }

                        adServiceStatus.postValue(ResultState.Success(Unit))
                    }
                },
                onError = {
                    adServiceStatus.postValue(ResultState.Error(it))
                }
            )
        }
    }
}
```

Now you can launch the app and see your new custom ad, congratulations!

[AdComposeRenderer]:sdk_presentation_compose/com.adition.sdk_presentation_compose.api/-ad-compose-renderer/index.html
[AdComposeRenderer.configure]:sdk_core/com.adition.sdk_core.api.core/-ad-renderer/configure.html
[AdComposeRenderer.RenderAd]:sdk_presentation_compose/com.adition.sdk_presentation_compose.api/-ad-compose-renderer/RenderAd.html
[AdResponseBundle]:sdk_core/com.adition.sdk_core.api.entities.response/-ad-response-bundle/index.html
[AdResponse]:sdk_core/com.adition.sdk_core.api.entities.response/-ad-response/index.html
[AdRendererEventHandler.downloadBitmap]:sdk_core/com.adition.sdk_core.api.core/-ad-renderer-event-handler/download-bitmap.html
[AdRendererEventHandler.performCustomTrackingEvent]:sdk_core/com.adition.sdk_core.api.core/-ad-renderer-event-handler/perform-custom-tracking-event.html
[AdRendererEventHandler.performTapEvent]:sdk_core/com.adition.sdk_core.api.core/-ad-renderer-event-handler/sperform-tap-event.html
[AdRendererEventHandler.sendMessage]:sdk_core/com.adition.sdk_core.api.core/-ad-renderer-event-handler/send-message.html
[AdRendererEventHandler.unloadRequest]:sdk_core/com.adition.sdk_core.api.core/-ad-renderer-event-handler/unload-request.html
[AdService.registerRenderer]:sdk_core/com.adition.sdk_core.api.core/-ad-service/register-renderer.html
[AdService.getCacheInstance]:sdk_core/com.adition.sdk_core.api.core/-ad-service/get-cache-instance.html
[DriveCache.find]:sdk_core/com.adition.sdk_core.api.services.cache/-drive-cache/find.html
[AdTapEvent]:sdk_core/com.adition.sdk_core.api.services.event_listener/-ad-event-type/-ad-tap-tvent.html
[Advertisement]:sdk_core/com.adition.sdk_core.api.core/-advertisement/index.html