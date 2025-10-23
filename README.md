# PALONA AI Front-end

A Flutter chat app with a Cloud Run app backend.

## Flutter usage

I have found flutter ideal for developing front-end components within the timeframe I built the project in. A few resources mentioned in the template application:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Getting Started

### Setting up Vertex AI Search and Reasoning engine 

This project is built on Google Cloud resources and uses a Firestore database as a memory store. The steps below are required to setup these resources.

- Log into your google cloud account and create a project 
  - [Setting up a Google Cloud account and Project](https://developers.google.com/workspace/guides/create-project)
  
- Setting up a Firestore database for chat history
  - [Setup a firestore database through the console](https://cloud.google.com/firestore/native/docs/manage-databases)
  - Open up the database in the console and create a collection
  - Place the database and collection names in the respective fields in the config.dart file
    
- Refer to the ReadMe of the backend application for how to set it up
  - [Setup backend](https://github.com/hallelujah-101/palona-webapp)
  - Place the link to the application in the 'cloudRunHost' section 

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
