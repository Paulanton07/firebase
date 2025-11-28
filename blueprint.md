
# Blueprint: theSocial Radio App

## Overview

A Flutter application that combines a radio player with a voice messaging feature.

## Implemented Features

*   **Radio Player:** A functional radio player.

## Current Task: Add Voice Messaging

### Plan

1.  **Create Voice Messaging Page:**
    *   Create a new file `lib/voice_messaging_page.dart`.
    *   Design a UI with the following elements:
        *   A button to start and stop recording.
        *   A list to display recorded voice messages.
        *   A playback mechanism for each message.

2.  **Add Navigation:**
    *   Add a new item to the main navigation in `lib/main.dart` to navigate to the `VoiceMessagingPage`.

3.  **Implement Recording:**
    *   Use the `record` package to capture audio from the device's microphone.
    *   Save the recorded audio file locally.

4.  **Implement Firebase Integration:**
    *   Upload the recorded audio file to Firebase Storage.
    *   Create a new `voice_messages` collection in Cloud Firestore.
    *   Store metadata for each voice message in a Firestore document, including:
        *   The URL of the audio file in Firebase Storage.
        *   A timestamp.
        *   The duration of the recording.

5.  **Implement Playback:**
    *   Use the `audioplayers` package to stream and play the audio from the Firebase Storage URL.

6.  **Display Voice Messages:**
    *   Fetch the list of voice messages from Firestore and display them on the `VoiceMessagingPage`.
