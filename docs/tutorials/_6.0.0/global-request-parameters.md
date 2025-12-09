---
layout: default
title: "Global request parameters"
nav_order: 6
---

# Global request parameters

We already know how to create and perform [AdRequest], [TagRequest], and [TrackingRequest]. However, each of them can have additional parameters, which are called global parameters because they are specified globally for all requests. The SDK provides the ability to add global parameters once so that you don’t have to copy them when creating each request.

We will continue to build the app, so be sure to follow all the previous tutorials. You can download this [project](https://github.com/VM-Mobile-SDK/nextgen-adsdk-android-tutorial/tree/built-in-capabilities/global-parameters) which has already implemented all steps from this tutorial.

## Section 1: Preparing the app

The application should ask whether it is permitted to collect data about the user. In this section, we will add functionality for this.

### Step 1

Let's open `MainScreen.kt`. Since we need to ask the user for permission, we create an `AlertDialog` in `MainScreen`.

**File:** `MainScreen.kt`

```kotlin
// ...
@Composable
fun MainScreen(
    navController: NavController,
    viewModel: MainViewModel = viewModel()
) {
    val uiState by viewModel.state.collectAsState()
    val showDialog by viewModel.showDialog.collectAsState()

    if (showDialog) {
        AlertDialog(
            onDismissRequest = {
                viewModel.showDialog.value = false
                viewModel.onLoad(false)
            },
            text = { Text("Please grant the permission to collect the data") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.showDialog.value = false
                    viewModel.onLoad(true)
                }) {
                    Text("Allow")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    viewModel.showDialog.value = false
                    viewModel.onLoad(false)
                }) {
                    Text("Deny")
                }
            }
        )
    }
    // ...
}

class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    private val _state = MutableStateFlow<PresentationState<Unit>>(
        PresentationState.Loading
    )

    val state = _state.asStateFlow()
    val showDialog = MutableStateFlow(true)

    init {
        // ...
    }

    fun onLoad(isDataCollectionAllowed: Boolean) {
    }
}
```

### Step 2

Since the [AdService] configuration contains cookies loading logic, we should obtain permission before calling [AdServiceProvider.configure].

To do this, we will move the configuration logic from `init` to the new `onLoad` method. Thus, when configuring [AdService], we will already have the `isDataCollectionAllowed` parameter.

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
    val showDialog = MutableStateFlow(true)

    fun onLoad(isDataCollectionAllowed: Boolean) {
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

### Step 3

The final step will be to add a couple of extensions so that we can use [AdService] after successful configuration.

In this code, after successful configuration via [AdServiceProvider.configure], we obtain [AdService] using the [AdServiceProvider.get] method. After that, we call the `onSuccess` method, which we will use in the future to work with [AdService].

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        viewModelScope.launch {
            adServiceProvider
                .configure(
                    "1800",
                    parentCoroutineScope = this
                )
                .flatMap { adServiceProvider.get() }
                .onSuccess { adService ->
                    
                }
                .get(
                    onSuccess = { _state.value = PresentationState.Loaded(Unit) },
                    onError = { _state.value = PresentationState.Error(it.description) }
                )
        }
    }
}

private suspend fun <T, ActionResult> AdResult<T>.flatMap(
    action: suspend (T) -> AdResult<ActionResult>
): AdResult<ActionResult> {
    return when (this) {
        is AdResult.Success -> action(this.result)
        is AdResult.Error -> AdResult.Error(this.error)
    }
}

private suspend fun <T> AdResult<T>.onSuccess(
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

Now we can move on to the global parameters!

## Section 2: Setting & modifying global parameters

In this section, we will learn about [GlobalParameters] and [AdRequestGlobalParameters]. We will pass the [AccessMode] parameter depending on the user's permission and specify how the server should work with cookies each time [AdRequest] is executed.

### Step 1

Let’s continue working in the `MainViewModel` and focus on the `onLoad` method. Since the [AdServiceProvider.configure] method includes logic for loading cookies, we should pass user permission before the SDK makes this request. We can do this using the `globalParameters` parameter, which accepts [GlobalParameters].

[GlobalParameters] is an object for storing common global parameters that will be applied when creating an [AdRequest], [TagRequest], and [TrackingRequest].

We will create [GlobalParameters] with [AccessMode], which will depend on the user's choice. This way, the ad server will know whether it can identify the user using cookies at the [AdService] configuration stage.

**Note:** [GlobalParameters.accessMode] is not the only global parameter for [AdRequest], [TagRequest], and [TrackingRequest]. A list of all global parameters can be found in the [GlobalParameters] documentation.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        val globalParameters = GlobalParameters(
            accessMode = isDataCollectionAllowed.toAccessMode()
        )
        
        viewModelScope.launch {
            adServiceProvider
                .configure(
                    "1800",
                    parentCoroutineScope = this,
                    globalParameters = globalParameters
                )
                .flatMap { adServiceProvider.get() }
                .onSuccess { adService ->

                }
                .get(
                    onSuccess = { _state.value = PresentationState.Loaded(Unit) },
                    onError = { _state.value = PresentationState.Error(it.description) }
                )
        }
    }
}

private fun Boolean.toAccessMode() = if (this) AccessMode.OPT_IN else AccessMode.OPT_OUT
// ...
```

### Step 2

In addition, sometimes you need to be able to modify or remove the [GlobalParameters]. You can use [AdService.setGlobalParameters] and [AdService.removeGlobalParameter] for this purpose.

**Note:** You can pass multiple [GlobalParameter] at once to the [AdService.setGlobalParameters] method by separating them with commas.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        val globalParameters = GlobalParameters(
            accessMode = isDataCollectionAllowed.toAccessMode()
        )

        viewModelScope.launch {
            adServiceProvider
                .configure(
                    "1800",
                    parentCoroutineScope = this,
                    globalParameters = globalParameters
                )
                .flatMap { adServiceProvider.get() }
                .onSuccess { adService ->
                    adService.setGlobalParameters(
                        GlobalParameter(
                            GlobalParameters::externalUID,
                            ExternalUID("uid")
                        )
                    )

                    adService.removeGlobalParameter(GlobalParameters::externalUID)
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

### Step 3

Although [GlobalParameters] are added to each [AdRequest], [TagRequest], and [TrackingRequest], [AdRequest] has separate [AdRequestGlobalParameters] that will only be added to it.

We implement logic where we allow the server to read cookies if the user has given permission to use personal data. Otherwise, we prohibit the use of cookies. To do this, we use the `adRequestGlobalParameters` parameter with the [CookiesAccess] property passed.

**Note:** [AdRequestGlobalParameters.cookiesAccess] is not the only global parameter specific for [AdRequest]. A list of all global parameters can be found in the [AdRequestGlobalParameters] documentation.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        val globalParameters = GlobalParameters(
            accessMode = isDataCollectionAllowed.toAccessMode()
        )
        
        val adRequestGlobalParameters = AdRequestGlobalParameters(
            cookiesAccess = isDataCollectionAllowed.toCookiesAccess()
        )

        viewModelScope.launch {
            adServiceProvider
                .configure(
                    "1800",
                    parentCoroutineScope = this,
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

private fun Boolean.toCookiesAccess(): AdRequestGlobalParameters.CookiesAccess {
    return if (this) {
        AdRequestGlobalParameters.CookiesAccess.GET
    } else {
        AdRequestGlobalParameters.CookiesAccess.NO_COOKIES
    }
}
// ...
```

### Step 4

Just like with [GlobalParameters], you can modify and remove the [AdRequestGlobalParameter]. You can use [AdService.setAdRequestGlobalParameters] and [AdService.removeAdRequestGlobalParameter] for this purpose.

**Note:** You can pass multiple [AdRequestGlobalParameter] at once to the [AdService.setAdRequestGlobalParameters] method by separating them with commas.

**File:** `MainScreen.kt`

```kotlin
// ...
class MainViewModel(
    val adServiceProvider: AdServiceProviderInterface = ServiceLocator.adServiceProvider
) : ViewModel() {
    // ...
    fun onLoad(isDataCollectionAllowed: Boolean) {
        val globalParameters = GlobalParameters(
            accessMode = isDataCollectionAllowed.toAccessMode()
        )

        val adRequestGlobalParameters = AdRequestGlobalParameters(
            cookiesAccess = isDataCollectionAllowed.toCookiesAccess()
        )

        viewModelScope.launch {
            adServiceProvider
                .configure(
                    "1800",
                    parentCoroutineScope = this,
                    globalParameters = globalParameters,
                    adRequestGlobalParameters = adRequestGlobalParameters
                )
                .flatMap { adServiceProvider.get() }
                .onSuccess { adService ->
                    // ...
                    adService.setAdRequestGlobalParameters(
                        AdRequestGlobalParameter(
                            AdRequestGlobalParameters::isIpIdentified,
                            true
                        )
                    )
                    
                    adService.removeAdRequestGlobalParameter(
                        AdRequestGlobalParameters::isIpIdentified
                    )
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

Now the ad server will know whether it has permission to process personal data each time [AdRequest], [TagRequest], and [TrackingRequest] are executed. In addition, we have specified how the server should work with cookies when [AdRequest] is executed. Congratulations!

[AdServiceProvider.configure]:ad_sdk/com.adition.ad_sdk.api/-ad-service-provider/configure.html
[AdServiceProvider.get]:ad_sdk/com.adition.ad_sdk.api/-ad-service-provider/get.html

[AdService]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/index.html
[AdService.setAdRequestGlobalParameters]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/set-ad-request-global-parameters.html
[AdService.removeAdRequestGlobalParameter]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/remove-ad-request-global-parameter.html
[AdService.setGlobalParameters]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/set-global-parameters.html
[AdService.removeGlobalParameter]:ad_sdk/com.adition.ad_sdk.api.core/-ad-service/remove-global-parameter.html

[AdRequest]:ad_sdk/com.adition.ad_sdk.api.entities.request/-ad-request/index.html

[TagRequest]:ad_sdk/com.adition.ad_sdk.api.entities.request/-tag-request/index.html

[TrackingRequest]:ad_sdk/com.adition.ad_sdk.api.entities.request/-tracking-request/index.html

[GlobalParameters]:ad_sdk/com.adition.ad_sdk.api.entities.request.global_parameters/-global-parameters/index.html
[GlobalParameters.accessMode]:ad_sdk/com.adition.ad_sdk.api.entities.request.global_parameters/-global-parameters/access-mode.html
[GlobalParameter]:ad_sdk/com.adition.ad_sdk.api.entities.request.global_parameters/-global-parameter/index.html

[AdRequestGlobalParameters]:ad_sdk/com.adition.ad_sdk.api.entities.request.global_parameters/-ad-request-global-parameters/index.html
[AdRequestGlobalParameters.cookiesAccess]:ad_sdk/com.adition.ad_sdk.api.entities.request.global_parameters/-ad-request-global-parameters/cookies-access.html
[AdRequestGlobalParameter]:ad_sdk/com.adition.ad_sdk.api.entities.request.global_parameters/-ad-request-global-parameter/index.html

[AccessMode]:ad_sdk/com.adition.ad_sdk.api.entities.request.global_parameters/-access-mode/index.html

[CookiesAccess]:ad_sdk/com.adition.ad_sdk.api.entities.request.global_parameters/-ad-request-global-parameters/-cookies-access/index.html
