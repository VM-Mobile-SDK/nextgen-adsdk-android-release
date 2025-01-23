---
layout: default
title: "3. Create and display interstitial ad section"
---

# Create and display interstitial ad section
A full-screen advertisement that fills the host app’s interface is known as an interstitial ad. 
In this tutorial we are going to add interstitial ad into our application.

## Section 1: Interstitial Ad Object

In this section we will create an interstitial [Advertisement](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core/-advertisement/index.html) object.

### Step 1
Lets change the structure of our `AdsdkdemoappandroidTheme` composable.
We create a `MainContent` composable and move the `AdView` call over there.
```kotlin 
AdsdkdemoappandroidTheme { 
    MainContent(viewModel)
}
```

```kotlin 
@Composable
fun MainContent(viewModel: MainViewModel) {
    Box(modifier = Modifier.fillMaxSize()) {
        AdView(viewModel)
    }
}
```

### Step 2
To create a interstitial banner we use the [Advertisement](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core/-advertisement/index.html) class again. Only difference this time we add the different [placementType](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/4.4.0/sdk_core/com.adition.sdk_core.internal.entities/-placement-type/index.html) `INTERSTITIAL`
We add the `interstitialAd` in the `MainViewModel`.
```kotlin 
var interstitialAd: Advertisement = Advertisement(
    "5192923",
    AdComposeRenderRegistry.getAllRendererNames(),
    placementType = PlacementType.INTERSTITIAL
)
```

### Step 3
We can add now a composable for the fullscreen interstitial.
```kotlin 
@Composable
fun ShowInterstitial(viewModel: MainViewModel) {
    var adState = rememberAdState(viewModel.interstitialAd)
    Box (
        contentAlignment = Alignment.Center,
        modifier = Modifier.fillMaxSize()
    ){
        Ad(adState = adState)
    }
}
```

### Step 4
To trigger the interstitial composable we will use a button which we add at the bottom.
```kotlin 
@Composable
fun BottomButton(onClick: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize()) {
        Button(
            onClick = onClick,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 16.dp)
        ) {
            Text("Show interstitial")
        }
    }
}
```

### Step 5
To control the interstitial presentation we will use a state value, which will be set to true if we click on the button.
```kotlin 
val showInterstitialComposable = remember { mutableStateOf(false) }

BottomButton(
    onClick = {
        showInterstitialComposable.value = !showInterstitialComposable.value
    }
)
```

### Step 6
Now lets structure this all together in our `MainContent` composable we created above.
```kotlin 
@Composable
fun MainContent(viewModel: MainViewModel) {
    val showInterstitialComposable = remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxSize()) {
        AdView(viewModel)
        BottomButton(
            onClick = {
                showInterstitialComposable.value = !showInterstitialComposable.value
            }
        )
        if (showInterstitialComposable.value) {
            ShowInterstitial(viewModel)
        }
    }
}
```