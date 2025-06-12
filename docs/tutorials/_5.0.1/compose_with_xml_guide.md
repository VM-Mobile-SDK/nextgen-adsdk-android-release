---
layout: default
title: "How to use AdSDK with XML views"
nav_order: 9
---

# How to use AdSDK with XML views

You can follow the tutorial documentation almost entirely. We will highlight the few differences in this guide.

We'll also provide some examples of how to integrate the functionality.

## AdSDK configuration

For setting up [AdService], creating [AdRequest] and [Advertisement], you can follow the [previous tutorial](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/5.0.1/first-steps.html) exactly, as it does not include any Compose-specific code.

The first thing to be careful about when following the tutorial is how the advertisement state is shared in the view model. In the tutorial, we use `mutableStateOf`, which is a feature from Jetpack Compose. An alternative could be [MutableLiveData](https://developer.android.com/reference/androidx/lifecycle/MutableLiveData).

## Use AdSDK composable with views

The major difference when using XML instead of Compose comes when you try to use the [Ad] or the [Interstitial] composable, since they are built with Compose. To integrate them into an XML-based layout, you’ll need to use Android's `setContent()`.

There are several ways to do this. You can use the XML layout. 

```xml
<androidx.compose.ui.platform.ComposeView
    android:id="@+id/composeView1"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content" />
```

```kotlin
is ResultState.Success -> {
    findViewById<ComposeView>(R.id.composeView1).setContent {
        Ad(it.data)
    }
}
```

You can also create the layout in the code directly.

```kotlin
ComposeView(context).apply {
    layoutParams = AdsListView.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
    )
    setContent {
        Interstitial(viewModel.interstitialState)
    }
}
```

For more information, you can refer to the [Compose documentation](https://developer.android.com/develop/ui/compose/migrate/interoperability-apis/compose-in-views).

[AdService]:sdk_core/com.adition.sdk_core.api.core/-ad-service/index.html
[Advertisement]:sdk_core/com.adition.sdk_core.api.core/-advertisement/index.html
[AdRequest]:sdk_core/com.adition.sdk_core.api.entities.request/-ad-request/index.html
[Ad]:sdk_presentation_compose/com.adition.sdk_presentation_compose.api/-ad.html
[Interstitial]:sdk_presentation_compose/com.adition.sdk_presentation_compose.api/-interstitial.html

