---
layout: default
title: "Create and display inline ads"
nav_order: 1
---

# Create and display inline ads
This tutorial will guide you through creating a simple application that can load and display a list of ads.

## Section 1: Getting started with AdSDK

Add and configure the AdSDK to create and load ads.

### Step 1
Let's create a new Android project and remove all unnecessary code.
Make sure you have added the correct packages from the [readme](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-release).

### Step 2
The entry point into the SDK is the [AdService](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-ad-service/index.html) class.
To make an easy start we just initialize the [AdService](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-ad-service/index.html) in the `onCreate` method of the `MainActivity`.
This is the first thing we should create, as it will be used to generate advertisements in the future. 
To do this, we will add this code:
```kotlin 
coroutineScope.launch {
    val isSuccess = AdService.init("1800", applicationContext, EventHandler())
    Log.d("AdSDK", "Init is success: $isSuccess")
}
```
Lets create an App file and class to add the [AdService](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-ad-service/index.html) initialisation.
To do this, create this class and add the code snippet from above.
The only mandatory parameter when creating [AdService](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-ad-service/index.html) is the [networkId](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-ad-service/networkId.html).
Network ID is the ID of your advertising account.
Our Code should now look like this:
```kotlin
class App: Application() {
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    
    override fun onCreate() {
        super.onCreate()

        coroutineScope.launch {
            val isSuccess = AdService.init("1800", applicationContext, EventHandler())
            Log.d("App", "Init is success: $isSuccess")
        }
    }
}
```
Remember to add this class as an entry point, so add it to the application in your `Manifest:
```
android:name="com.adition.adsdk.App"
```

### Step 3
The next step will be to create a composable, which we will display upon successful creation of [AdService](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-ad-service/index.html). 
On this composable, we will be creating and displaying our advertisement.

```kotlin 
@Composable
fun AdView() {
    Text(
        text = "Advertisement should be here"
    )
}
```
Now we can call this in our composable in the `MainActivity`.
```kotlin 
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        setContent {
            AdsdkdemoappandroidTheme {
                AdView()
            }
        }
    }
}
```

## Section 2: Loading and displaying advertisements

### Step 1
Before we create an [Advertisement](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-advertisement/index.html) object we want to add a `ViewModel`:  
```kotlin
class MainViewModel: ViewModel() {

}
```

### Step 2
To create an [Advertisement](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-advertisement/index.html) object, you need to specify parameters, two of which are required:
* [contentId](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.entities/-advertisement-parameters/content-id.html) or [learningTag](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.entities/-advertisement-parameters/learning-tag.html)
* [adTypes](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.entities/-advertisement-parameters/ad-types.html)
We're going to use the [contentId](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.entities/-advertisement-parameters/content-id.html) because it's used more often than the [learningTag](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.entities/-advertisement-parameters/learning-tag.html). Content Unit is the unique ID of your advertising space and for ad type we use [AdComposeRenderRegistry.getAllRendererNames()](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-compose-render-registry/get-all-renderer-names.html) this will enable all available `adTypes`. 
Another important parameter is `placementType`. In this case, we need [AdPlacementType.INLINE](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.entities/-placement-type/-i-n-l-i-n-e/index.html), which is the default, so we ignore it.
All possible parameters can be found in the [AdvertisementParameters documentation](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core.internal.entities/-advertisement-parameters/index.html).

```kotlin
class MainViewModel: ViewModel() {
    var ad: Advertisement = Advertisement(
        "4810915",
        AdComposeRenderRegistry.getAllRendererNames(),
    )
}
```
We can now load this advertisement using [loadAdvertisement](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-advertisement/load-advertisement.html):
```kotlin
class MainViewModel: ViewModel() {
    var ad: Advertisement = Advertisement(
        "4810915",
        AdComposeRenderRegistry.getAllRendererNames(),
    )

    init {
        viewModelScope.launch {
            ad.loadAdvertisement()
        }
    }
}
```

### Step 3
We can pass this [Advertisement](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-advertisement/index.html) now to the [rememberAdState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/remember-ad-state.html) composable.
The [rememberAdState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/remember-ad-state.html) creates the [AdState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/index.html) which we will use later. 
There are multiple versions of the [rememberAdState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/remember-ad-state.html). 
For example we could pass a content unit directly to the [rememberAdState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/remember-ad-state.html) and it would create the [Advertisement](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_core/com.adition.sdk_core/-advertisement/index.html) for us. 
```kotlin
@Composable
fun AdView(viewModel: MainViewModel) {
    val adState = rememberAdState(advertisement = viewModel.ad)
}
```

### Step 4
We can pass the [AdState](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad-state/index.html) to [Ad](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad.html) composable.
The [Ad](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.6.0/sdk_presentation_compose/com.adition.sdk_presentation_compose/-ad.html) is the main composable used to display the ad with provided `adState`.
```kotlin
@Composable
fun AdView() {
    val adState = rememberAdState(advertisement = viewModel.ad)
    Ad(adState = adState, modifier = Modifier)
}
```

How our MainActivity should look like:
```kotlin
class MainActivity : ComponentActivity() {
    private val viewModel by viewModels<MainViewModel>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            AdsdkdemoappandroidTheme {
                AdView(viewModel)
            }
        }
    }
}

@Composable
fun AdView(viewModel: MainViewModel) {
    val adState = rememberAdState(advertisement = viewModel.ad)
    Ad(adState = adState, modifier = Modifier)
}
```
Now we should see the Banner on our device:
<br>
<img src="images/first_ad.png" width="300"/>