# rexy_demo

A Flutter Maps Demo

## Getting Started

There are two different implementations available.
One is a modified version of packt and another one is built from scratch.
- [Watch the demo video](./videos/mapsDemo.mp4)

## To get API Key follow these steps

- Go to [Google Cloud Console](https://console.cloud.google.com/google/maps-apis/new?project=atnosoft-live)
- Enable Maps SDK for Android 
- On the left navbar click on credentails and then click on `Create Credentials` button.
- This will give you an API Key copy it (keep it safe)
- Open the repo and go to flutter-maps-demo/android/app/src/main/AndroidManifest.xml
- Inside the `<application>` tag add this line
    `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR API KEY"/>`
    and replace 'YOUR API KEY' with the API Key from the google cloud console.
