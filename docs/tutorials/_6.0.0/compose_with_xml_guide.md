---
layout: default
title: "How to use AdSDK with XML views"
nav_order: 10
---

# How to use AdSDK with XML views

Working with AdSDK is no different, as most APIs are not tied to UI frameworks in any way.

What you need to pay attention to are the two AdSDK Composable components: [Ad] and [Interstitial].

## Use Ad & Interstitial Composable with Views

The major difference when using XML instead of Compose comes when you try to use the [Ad] or the [Interstitial] composable, since they are built with Compose. To integrate them into an XML-based layout, you’ll need to use Android's `setContent()`.

There are several ways to do this.

### XML

```xml
<androidx.compose.ui.platform.ComposeView
    android:id="@+id/composeView1"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content" />
```

```kotlin
findViewById<ComposeView>(R.id.composeView1).setContent {
    Interstitial(interstitialState)
}
```

### Code

```kotlin
ComposeView(context).apply {
    layoutParams = AdsListView.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
    )
    setContent {
        Ad(it.data)
    }
}
```

For more information, you can refer to the [Compose documentation](https://developer.android.com/develop/ui/compose/migrate/interoperability-apis/compose-in-views).

[Ad]:ad_sdk/com.adition.ad_sdk.api.presentation/-ad.html
[Interstitial]:com.adition.ad_sdk.api.presentation/-interstitial.html
