---
layout: default
title: "AdSDK Cache Management"
nav_order: 7
---

# AdSDK Cache Management

The SDK supports a persistent cache with resources related to ad, these can be banners or other resources, depending on the type of ad. In this tutorial, we’ll look at how an application developer can control the cache.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/cache-magement) which has already implemented all steps from this tutorial.

## Section 1: Limiting the cache size

In this section, we will learn how to limit the size of the cache.

### Step 1

Let’s open `MainScreen.kt` and focus on the [AdServiceProvider.configure] method. When we creating an [AdService], we can specify the size of our cache in MB via `cacheSize` parameter. Let’s set it to 20 MB.

**Note:** The cache size parameter is optional. If you do not specify it, the default cache size is 100 MB.

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
                .flatMap { adServiceProvider.get() }
                .onSuccess { adService ->
                    // ...
                }
                .get(
                    onSuccess = { _state.value = PresentationState.Loaded(Unit) },
                    onError = { _state.value = PresentationState.Error(it.description) }
                )
        }
    }
}
// ...
```

### Step 2

In addition, the SDK allows you to change the size of the cache over time. You can use [AdService.setCacheSize] method for this purpose.

**Note:** If the specified cache size is smaller than the size of already cached resources, the cache will delete resources to fit the new specified limit.

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
                // .onSuccess {
                //     val possibleError = it.setCacheSize(20u).adErrorOrNull()
                // }
                .flatMap { adServiceProvider.get() }
                .onSuccess { adService ->
                    // ...
                }
                .get(
                    onSuccess = { _state.value = PresentationState.Loaded(Unit) },
                    onError = { _state.value = PresentationState.Error(it.description) }
                )
        }
    }
}
// ...
```

## Section 2: Flushing the cache

Although the cache size reached to it limit, SDK will removes resources in FIFO order, sometimes you need to clear the cache completely. In this section, we will learn how we can do this.

### Step 1

Let’s imagine a situation in which some ads can be localized. In this case, you would like to clear the entire cache so that when the ad is reloaded, it will be correctly localized.

Let’s add the functionality of tracking localization changes. First, we will create the package `presentation/screens/main_screen` and move `MainScreen.kt` there. Next, we will create `LocaleChangeEffect.kt` in `presentation/screens/main_screen/components`.

**File:** `LocaleChangeEffect.kt`

```kotlin
@Composable
fun LocaleChangeEffect(onLocaleChanged: (Locale) -> Unit) {
    val configuration = LocalConfiguration.current
    val locale = configuration.locales[0]
    val localeTag = locale.toLanguageTag()
    val previousLocaleTag = rememberSaveable { mutableStateOf<String?>(null) }

    LaunchedEffect(localeTag) {
        if (previousLocaleTag.value != null && previousLocaleTag.value != localeTag) {
            onLocaleChanged(locale)
        }
        previousLocaleTag.value = localeTag
    }
}
```

### Step 2

Now let's return to `MainScreen.kt` and use this effect.

**File:** `MainScreen.kt`

```kotlin
// ...
@Composable
fun MainScreen(
    navController: NavController,
    viewModel: MainViewModel = viewModel()
) {
    // ...
    PresentationStateContainer(
        uiState,
        Modifier.fillMaxSize()
    ) {
        LocaleChangeEffect { viewModel.onLocaleChange() }
        // ...
    }
}

class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        // ...
    }
    
    fun onLocaleChange() {
        
    }
}
// ...
```

### Step 3

All we have to do is clear the cache. To do this, we use the [AdService.flushCache] method.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        // ...
    }
    
    fun onLocaleChange() {
        viewModelScope.launch {
            adServiceProvider.get()
                .onSuccess {
                    val possibleError = it.flushCache().adErrorOrNull()

                    if (possibleError != null) {
                        Log.e(
                            "MainViewModel",
                            "Error flushing cache: ${possibleError.description}"
                        )
                    }
                }
        }
    }
}
// ...
```

Congratulations, now all ad resources will be removed every time the user changes the language.

[AdServiceProvider.configure]:ad_sdk/com.adition.ad_sdk.api/-ad-service-provider/configure.html

[AdService]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/index.html
[AdService.setCacheSize]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/set-cache-size.html
[AdService.flushCache]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/flush-cache.html
