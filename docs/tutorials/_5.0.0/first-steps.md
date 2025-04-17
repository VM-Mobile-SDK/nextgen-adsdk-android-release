---
layout: default
title: "First steps for working with AdSDK"
nav_order: 1
---

# First steps for working with AdSDK

This tutorial will guide you through the first steps of working with the AdSDK - creating an [AdService].

You can download this [this project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/first-step) which already implements all the steps of this tutorial.

## Creating an AdService

Creating and configuring an [AdService] for later ad creation and loading.

### Step 1

Create a new Android project and remove any unnecessary code.

Make sure you have added the correct packages from the [readme](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-release/blob/main/README.md).

### Step 2

The entry point into the SDK is the [AdService] class. This is the first thing we should create, as it will be used to generate advertisements in the future.

For an easy start, we will simply configure the [AdService] in the `App` class. We create a file called `App` and add it to the `MainActivity` as well.

**File:** `App.kt`

```kotlin
class App : Application() {
    override fun onCreate() {
        super.onCreate()

    }
}
```

**File:** `MainActivity.kt`

```kotlin
class MainActivity : ComponentActivity() {
    
    override fun onCreate() {
        super.onCreate()

        val app = application as App

        // ... 
    }
}

// ...
```

Remember to add this class as an entry point, so add it to the application in your `Manifest`.

**File:** `AndroidManifest.xml`

```xml
android:name="com.adition.tutorial_app.App"
```

### Step 3

Before using the [AdService], we should first configure it. To do this, we will use the [AdService.configure] method in the App class. The only mandatory parameter when configuring an [AdService] is [AdService.networkId]. The network identifier is the identifier of your advertising account.

The configure method is suspendable, so we should use the coroutine. To do this, we need to create a `coroutineScope` and add this code to the `onCreate` function of the `App` class.

```kotlin
class App: Application() {
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    override fun onCreate() {
        super.onCreate()

        coroutineScope.launch {
            AdService.configure("1800", applicationContext)
        }
    }
}
```

### Step 4

[AdService.configure] returns [AdResult], which is our custom AdSDK implementation of Kotlin's `Result`. [AdResult] contains [AdError] the only type of error which the SDK supports. We can use [AdResult] to check that the [AdService] has been successfully configured and initialised.

Let us add a `ResultState` class to monitor the status.

**File:** `ResultState`

```kotlin
sealed class ResultState<out T> {
    data class Success<out T>(val data: T) : ResultState<T>()
    data class Error<T>(val exception: AdError) : ResultState<T>()
}
```

We can use this status in the `App` file.

**File:** `App.kt`

```kotlin
class App: Application() {
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    val adServiceStatus = MutableLiveData<ResultState<Unit>>()

    override fun onCreate() {
        super.onCreate()

        coroutineScope.launch {
            val initResult = AdService.configure("1800", applicationContext)

            initResult.get(
                onSuccess =  {
                    adServiceStatus.value = ResultState.Success(Unit)
                },
                onError = {
                    adServiceStatus.value = ResultState.Error(it)
                }
            )
        }
    }
}
```

### Step 5

We can now use `adServiceStatus` in the `onCreate` function of the `MainActivity`.

**File:** `MainActivity.kt`

```kotlin
class MainActivity : ComponentActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val app = application as App
        app.adServiceStatus.observe(this) { result ->
            when(result) {
                is ResultState.Error -> {
                    // We will handle in the next step.
                }

                is ResultState.Success -> {
                    setContent {
                        TutorialAppTheme {
                            Greeting(name = "AdSDK")
                        }
                    }
                }
            }
        }
    }
}

// ... 
```

### Step 6

We could react on all the different error cases [AdError] contains. To keeps it easy we just show the description of the [AdError].

**File:** `MainActivity.kt`

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val app = application as App
        app.adServiceStatus.observe(this) { result ->
            when(result) {
                is ResultState.Error -> {
                    showAppError(result.exception)
                }

                is ResultState.Success -> {
                    setContent {
                        TutorialAppTheme {
                            Greeting(name = "AdSDK")
                        }
                    }
                }
            }
        }
    }

    private fun showAppError(adError: AdError) {
        Toast.makeText(this, "Initialization failed: ${adError.description}", Toast.LENGTH_LONG).show()
    }
}

// ... 
```

Now, if you’ve done everything right, you should see the greeting message when you launch the app. This completes the [AdService] configuration, congratulations!

[AdService]:sdk_core/com.adition.sdk_core.api.core/-ad-service/index.html
[AdService.networkId]:sdk_core/com.adition.sdk_core.api.core/-ad-service/network-id.html
[AdService.configure]:sdk_presentation_compose/com.adition.sdk_presentation_compose.api/-ad-service-extension/index.html

[AdError]:sdk_core/com.adition.sdk_core.api.entities.exception/-ad-error/index.html
[AdResult]:sdk_core/com.adition.sdk_core.api.entities.exception/-ad-result/index.html
