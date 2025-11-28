# Project Setup Guide

This project is a Flutter application integrated with Firebase. To run this project locally on your Windows machine, you need to set up the development environment.

## Prerequisites

### 1. Install Flutter SDK
The "engine" that runs your app.
1.  Download the Flutter SDK for Windows: [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)
2.  Extract the zip file to `C:\src\flutter` (or a similar folder).
3.  Add `C:\src\flutter\bin` to your **User Path** environment variable.

### 2. Install Android Studio (for Android SDK)
Required to build the Android version of the app.
1.  Download and install Android Studio: [https://developer.android.com/studio](https://developer.android.com/studio)
2.  During installation, ensure **Android SDK**, **Android SDK Platform-Tools**, and **Android Virtual Device** are selected.
3.  Open Android Studio, go to **Settings > Languages & Frameworks > Android SDK**, and install the SDK for **Android 13 (API 33)** or later.

### 3. Verify Installation
Open a new terminal (PowerShell) and run:
```powershell
flutter doctor
```
This command will tell you if anything is missing.

## Running the App

Once the setup is complete:

1.  **Get Dependencies**:
    ```powershell
    flutter pub get
    ```

2.  **Run on Android Emulator**:
    *   Open Android Studio and start an Emulator.
    *   Run:
        ```powershell
        flutter run
        ```

3.  **Run on Web**:
    ```powershell
    flutter run -d chrome
    ```

## Project Features
*   **Authentication**: Login and Sign Up with Firebase Auth.
*   **Radio Player**: Stream radio stations.
*   **Voice Messaging**: Record and share voice messages using Firebase Storage.
*   **Theming**: Multiple theme options (Deep Purple, Vibrant Green, Neon Blue).
