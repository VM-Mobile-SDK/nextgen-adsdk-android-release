# nextgen-adsdk-android-release
This repo contains the github packages for using Aditions nextgen AdSDK in Android.

## Authorization

Although the repository is public, you need any Github account with a token to add the dependency to your project. To create a token, you need to go to:

*Github Settings > Developer settings > Personal access tokens > Tokens (classic) > Generate new token (classic)*

Here you can enter any name and expiration date. Of the mandatory ones, you need to specify **read:packages** permission.

At this point, you have everything you need to connect the dependency. You can read more about tokens [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#personal-access-tokens-classic) if you want.

## Add the repository dependency

Add the repository to your settings.gradle file and set the correct credentials, where username is the username of your github account, password is the token that was created in the Authorisation step.
(via gradle.properties or environment variables)
```Groovy
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven {
            name = "GitHubPackages"

            url = uri("https://maven.pkg.github.com/VM-Mobile-SDK/nextgen-adsdk-android-release")

            credentials {
        		username = project.findProperty("gpr.user") ?: System.getenv("USERNAME")
            	password = project.findProperty("gpr.key") ?: System.getenv("TOKEN")
            }
        }
    }
}
```
Alternative add the credentials via .env file:
```Groovy
def props = new Properties()
file(".env").withInputStream { props.load(it) }

...
            credentials {
                username = props.getProperty("USERNAME")
                password = props.getProperty("TOKEN")
            }
```

For Maven you can look here:\
https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-apache-maven-registry#installing-a-package


## Add the package dependencies
In the build.gradle file you have to add your credentials:
```Groovy
....

dependencies {
    implementation 'com.adition.adsdk:sdk_core:x.x.x'
    implementation 'com.adition.adsdk:sdk_presentation_compose:x.x.x'
}

```
For Maven you can look here:\
https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-apache-maven-registry#installing-a-package


## Using the SDK

## Initialize and configure the AdService

How to setup the AdService :

```kotlin

import android.app.Application
import com.adsdk.sdk_core.AdService
import com.adsdk.sdk_core.EventHandler
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch


class App : Application() {
    override fun onCreate() {
        super.onCreate()

        AdService.init("1800", this, EventHandler())
        AdService.getInstance().setCachePath(cacheDir.path + "/ad_cache")
        AdService.getInstance().setCacheSize(20)
        GlobalScope.launch {
            AdService.getInstance().configure()
        }

    }
}
```

## Register the Renderer

Here is an example how to setup the default Renderers for Compose:


```kotlin
AdComposeRenderRegistry.registerDefaultAdRenderers()
```

## Requesting Ads & using AdState

Here is example how you can use the AdState in composable:

```kotlin

@Composable
fun MainScreen(viewModel: MainViewModel) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        LazyColumn() {
            items(1) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        val adState = rememberAdState("4810915")
                        Ad(adState = adState, modifier = Modifier
                            .width(500.dp)
                            .height(300.dp))

                    }

            }
        }
    }
}

```

The advertisement will emit events during its lifecycle: `Loading`, `Caching`, `AdReadyToDisplay` and, conditionally, `Error`. 

You can observe them like this:

```kotlin

                        when (val state = adState.state) {
                            is AdState.State.Error -> {
                                Text(text = "error")
                                state.throwable.printStackTrace()
                            }
                            is AdState.State.Loading -> CircularProgressIndicator(
                                modifier = Modifier.size(
                                    64.dp
                                )
                            )
                            is AdState.State.Caching -> {
                                Text(text = "Loading ad...")
                            }
                            is AdState.State.AdReadyToDisplay -> {
                            }
                        }

```

You can observe the events like this:

```kotlin
                    AdService.getInstance().eventHandler!!.events.collectLatest {
                        Log.e("MainActivity", "Collected EVENT - $it")
                    }
```

## Aditional documentation

You can find aditional documentation explaining the use of the SDK [here](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/sdk_core/index.html).




