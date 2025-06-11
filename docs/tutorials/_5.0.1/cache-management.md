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

When we creating an [AdService], we can specify the size of our cache in MB. Let’s change it to 20 MB.

The cache size parameter is optional. If you do not specify it, the default cache size is 100 MB.

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
                cacheSizeInMb = 20u
            )

            initResult.get(
                onSuccess =  {
                    addGlobalParameters()
                    adServiceStatus.postValue(ResultState.Success(Unit))
                },
                onError = {
                    adServiceStatus.postValue(ResultState.Error(it))
                }
            )
        }
    }

    // ...
}
```

### Step 2

In addition, the SDK allows you to change the size of the cache over time. You can use [AdService.setCacheSize] method for this purpose.

If the specified cache size is smaller than the size of already cached resources, the cache will delete resources to fit the new specified limit.

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
                cacheSizeInMb = 20u
            )

            initResult.get(
                onSuccess =  {
                    // coroutineScope.launch { AdService.setCacheSize(20u) }
                    addGlobalParameters()
                    adServiceStatus.postValue(ResultState.Success(Unit))
                },
                onError = {
                    adServiceStatus.postValue(ResultState.Error(it))
                }
            )
        }
    }

    // ...
}
```

## Section 2: Flushing the cache

Although the cache size reached to it limit, SDK will removes resources in FIFO order, sometimes you need to clear the cache completely. In this section, we will learn how we can do this.

### Step 1

For example, let's clear the cache in the case of an [AdError.CacheWriteAction].

To do this, let's go back to the `InlineAd` file and add this code in the case of a [AdService.makeAdvertisement] method failure.

**File:** `InlineAd.kt`

```kotlin
// ...

class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...

    init {
        viewModelScope.launch {
            val tagUser = async { tagUser() }
            val conversionTracking = async { conversionTracking() }

            tagUser.await()
            conversionTracking.await()

            AdService.makeAdvertisement(
                adRequest,
                adEventListener = adEventListener
            ).get(
                onSuccess = {
                    aspectRatio = it.adMetadata?.aspectRatio ?: aspectRatio
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InlineAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    when(it) {
                        is AdError.CacheWriteAction -> {
                            
                        }
                        else -> {}
                    }
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
    
    //...
}
```

### Step 2

We create an method `flushCache` and use [AdService.flushCache].

**File:** `InlineAd.kt`

```kotlin
// ...

class InlineAdViewModel: ViewModel() {
    private val adRequest = AdRequest("4810915")
    var advertisementState = mutableStateOf<ResultState<Advertisement>?>(null)
    var aspectRatio = 2f

    // ...

    init {
        viewModelScope.launch {
            val tagUser = async { tagUser() }
            val conversionTracking = async { conversionTracking() }

            tagUser.await()
            conversionTracking.await()

            AdService.makeAdvertisement(
                adRequest,
                adEventListener = adEventListener
            ).get(
                onSuccess = {
                    aspectRatio = it.adMetadata?.aspectRatio ?: aspectRatio
                    advertisementState.value = ResultState.Success(it)
                },
                onError = {
                    Log.e("InlineAdViewModel", "Failed makeAdvertisement: ${it.description}")
                    when(it) {
                        is AdError.CacheWriteAction -> {
                            flushCache()
                        }
                        else -> {}
                    }
                    advertisementState.value = ResultState.Error(it)
                }
            )
        }
    }
    
    fun flushCache() {
        viewModelScope.launch {
            AdService.flushCache().get(
                onSuccess = {
                    Log.d("InlineAdViewModel", "FlushCache was successful")
                },
                onError = {
                    Log.d("InlineAdViewModel", "Failed flushCache: ${it.description}")
                }
            )
        }
    }
    
    // ...
}
```

## Section 3: Specify the cache path

In this section, we will see how to set the path of the cache.

### Step 1

Like the size we can also set the custom path of the cache when we configure the [AdService].

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
                    // coroutineScope.launch { AdService.setCacheSize(20u) }
                    addGlobalParameters()
                    adServiceStatus.postValue(ResultState.Success(Unit))
                },
                onError = {
                    adServiceStatus.postValue(ResultState.Error(it))
                }
            )
        }
    }

    // ...
}
```

### Step 2

Similar to the size, the SDK allows you to change the path of the cache over time. You can use [AdService.setCachePath] method for this purpose.

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
                    // coroutineScope.launch { AdService.setCacheSize(20u) }
                    // coroutineScope.launch { 
                    //    AdService.setCachePath(cacheDir.path + "/tutorialApp/") 
                    // }
                    addGlobalParameters()
                    adServiceStatus.postValue(ResultState.Success(Unit))
                },
                onError = {
                    adServiceStatus.postValue(ResultState.Error(it))
                }
            )
        }
    }

    // ...
}
```

[AdService]:sdk_core/com.adition.sdk_core.api.core/-ad-service/index.html
[AdService.makeAdvertisement]:sdk_core/com.adition.sdk_core.api.core/-ad-service/make-advertisement.html
[AdService.setCacheSize]:sdk_core/com.adition.sdk_core.api.core/-ad-service/set-cache-size.html
[AdService.setCachePath]:sdk_core/com.adition.sdk_core.api.core/-ad-service/set-cache-path.html
[AdService.flushCache]:sdk_core/com.adition.sdk_core.api.core/-ad-service/flush-cache.html

[AdError.CacheWriteAction]:sdk_core/com.adition.sdk_core.api.entities.exception/-ad-error/-cache-write-action/index.html
