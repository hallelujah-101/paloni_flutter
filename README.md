# Gemi frontend

A Flutter chat app with a Cloud Run app backend.

## Flutter usage

I have found flutter ideal for developing front-end components within the timeframe I built the project in. A few resources mentioned in the template application:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Getting Started

### Setting up a Google Cloud account and a Firestore database

This project is built on Google Cloud resources and uses a Firestore database as a memory store. The steps below are required to setup these resources.

- Log into your google cloud account and create a project 
  - [Setting up a Google Cloud account and Project](https://developers.google.com/workspace/guides/create-project)
  
- Setting up a Firestore remote configurations 
  - [Remote Configurations Setup](https://firebase.google.com/docs/remote-config)
        
- Refer to the ReadMe of the backend application for how to set it up
  - [Setup backend](https://github.com/hallelujah-101/palona-webapp)

- Deploy application to Firebase
  - [Firebase hosting how to](https://firebase.google.com/docs/app-hosting/get-started)
  - Use the remote config tab in firebase to set the parameters(variables):
      * {"cloudRunHost": "Link to backend app"}

### Running the application

```Bash
flutter clean
```
```Bash
flutter build web
```
```Bash
flutter run
```
