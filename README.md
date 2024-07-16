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

## Aditional documentation

You can learn more about how to work with the SDK in the [documentation](https://vm-mobile-sdk.github.io/nextgen-adsdk-android-release/sdk_core/index.html).


