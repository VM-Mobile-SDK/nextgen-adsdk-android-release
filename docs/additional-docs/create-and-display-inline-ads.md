---
layout: default
title: "1. Create and display inline ads"
---

# Create and display inline ads
This tutorial will guide you in creating a simple app that can load and display a list of advertisement.

## Section 1: First steps for working with AdSDK

Create and configure AdSDK for the subsequent creation and loading of advertisements.

### Step 1:
Let’s create a new Android project and remove all the unnecessary code. 
Make sure you added the packages correctly from the Readme


### Step 2
The entry point into the SDK is the `AdServic` class.
To make an easy start we just initialize the `AdService` in the `onCreate` Method of the `MainActivity`.
This is the first thing we should create, as it will be used to generate advertisements in the future. 
To do this, we will add this example:.
```kotlin 
runBlocking {
    val isSuccess = AdService.init("1800", applicationContext, EventHandler())
    Log.d("AdSDK", "Init is success: $isSuccess")
}
```
The only mandatory parameter when creating AdService is the networkID. 
Network ID is the ID of your advertising account.
Our Code should now look like this:
```kotlin 
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        runBlocking {
            val isSuccess = AdService.init("1800", applicationContext, EventHandler())
            Log.d("AdSDK", "Init is success: $isSuccess")
        }
        
        setContent {
            AdsdkdemoappandroidTheme {

            }
        }
    }
}
```
### Step 3
The next step will be to create a composable, which we will display upon successful creation of AdService. 
On this composable, we will be creating and displaying our advertisement.
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

        runBlocking {
            val isSuccess = AdService.init("1800", applicationContext, EventHandler())
            Log.d("AdSDK", "Init is success: $isSuccess")
        }
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
To create advertisements, we use the `Advertisement` object. To create `Advertisement` object, the only mandatory parameter is the `contentUnit` and `adTypes`. 
Content Unit is the unique ID of your advertising space and for ad type we use `AdComposeRenderRegistry.getAllRendererNames()` this will enable all available adTypes. 
This method returns an Advertisement object, which essentially is the advertisement you will be displaying.
Another important parameter is placementType. In this case, we need AdPlacementType.inline, which is the default, so we ignore it

```kotlin
@Composable
fun AdView() {
    var ad = Advertisement(
        "5192923",
        AdComposeRenderRegistry.getAllRendererNames()
    )
}
```

### Step 2
We can pass this `Advertisement` now to the `rememberAdState` composable:
The `rememberAdState` creates the `AdState` we will add to the Ad and we can observe the state of the ad and advertisement. 
There are multiple versions ob the `rememberAdState`. 
For example we could pass a content unit directly to the `rememberAdState` and it would create the `Advertisement` for us. 
```kotlin
@Composable
fun AdView() {
    var ad = Advertisement(
        "5192923",
        AdComposeRenderRegistry.getAllRendererNames()
    )
    val adState = rememberAdState(advertisement = ad)
}
```

### Step 3
We can pass the `AdState` to `Ad` composable.
The `Ad` is the main composable used to display the ad with provided adState.
```kotlin
fun AdView() {
    var ad = Advertisement(
        "5192923",
        AdComposeRenderRegistry.getAllRendererNames()
    )
    val adState = rememberAdState(advertisement = ad)

    Ad(adState = adState, modifier = Modifier)
}

```

Now we should see the Banner on our device:
<br>
<img src="images/first_ad.png" width="300"/>