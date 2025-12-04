Here’s a concise, compatibility-first plan to guide your Flutter app stack and setup.

## Plan: Flutter Radio + Voice STT/Translate

Use a hybrid architecture: ExoPlayer-backed audio for radio playback, a simple recorder for voice notes, cloud STT/translation as default for best accuracy, and on-device fallbacks for privacy/offline. Pin Flutter/Android toolchain versions, isolate plugins behind service interfaces, and use foreground services correctly on Android 14+ to ensure reliability.

### Steps
1. Define service interfaces: `AudioPlaybackService`, `RecorderService`, `TranscriptionService`, `TranslationService` with swap-able implementations.
2. Choose packages: radio via `just_audio` + `audio_service`; recording via `record`; STT cloud default + `vosk_flutter` fallback; translation via Google Cloud + ML Kit fallback.
3. Pin toolchain: Flutter `3.24.x`, Dart `3.5.x`, Gradle `8.10.2`, AGP `8.8.0`, Kotlin `2.0.21`, Java `17`; avoid AGP 8.6–8.7.
4. Configure Android: foreground service types (`mediaPlayback`, `microphone`), permissions (`RECORD_AUDIO`, `INTERNET`), audio focus via `audio_session`, cleartext/network security for local proxies.
5. Set recording formats: AAC LC (`.m4a`) or WAV PCM16; target 16 kHz mono PCM for STT pipelines; add simple transcoding if needed.
6. Implement state management with `Riverpod`/`Bloc`, centralize permissions UX, model downloads/cache management, and fallback logic for offline modes.
7. Create compatibility CI: lock versions with FVM, run integration tests on Firebase Test Lab across Android 8–15, verify foreground/background behavior and localization.

### Further Considerations
1. STT choice: Default cloud (Google/Azure/OpenAI) for accuracy; offline fallback with Vosk; Whisper.cpp only on high-end devices.
2. Translation choice: Default Google Cloud; ML Kit offline packs for selected languages to control app size.
3. Target locales/devices: Which languages and minimum device tier? This informs model selection and storage budgets.

---

Research summary (late 2025)

Core packages and Android requirements
- Audio streaming (radio)
  - `just_audio` (ExoPlayer-based): radio HTTP MP3/AAC, HLS, ICY metadata; add `INTERNET`, handle cleartext if using local proxy; ExoPlayer preferred over MediaPlayer. GitHub: https://github.com/ryanheise/just_audio; pub: https://pub.dev/packages/just_audio
  - `audio_service`: background playback, media notification, Android Auto; requires foreground service permissions (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` on SDK 34). GitHub: https://github.com/ryanheise/audio_service; pub: https://pub.dev/packages/audio_service
  - Alternatives: `media_kit` (advanced backends), `flutter_sound` (player+recorder but less ideal for radio).

- Audio recording (voice messages)
  - `record`: simple, reliable; Android `RECORD_AUDIO`; supports AAC/WAV/FLAC; minSdk ~23; stream mode for STT. GitHub: https://github.com/llfbandit/record; pub: https://pub.dev/packages/record
  - `flutter_sound`: broader surface (player+recorder); minSdk 21; multiple codecs. GitHub: https://github.com/canardoux/flutter_sound; pub: https://pub.dev/packages/flutter_sound

- Speech-to-Text (transcription)
  - `speech_to_text`: native recognizer (Google app); best for short utterances; not ideal for long-form meetings. GitHub: https://github.com/csdcorp/speech_to_text; pub: https://pub.dev/packages/speech_to_text
  - On-device offline: `vosk_flutter` (Vosk models 50–200 MB; good for streaming mic). GitHub: https://github.com/alphacep/vosk-api; pub: https://pub.dev/packages/vosk_flutter
  - On-device high-accuracy: whisper.cpp via custom wrapper (no official plugin); heavy engineering; model sizes 40 MB–2.9 GB.
  - Cloud STT: Google Cloud Speech-to-Text (streaming), Azure Speech, OpenAI Whisper API; trade privacy for accuracy and simplicity.

- Translation (voice/text)
  - On-device: `google_mlkit_translation` (downloadable language packs). Pub: https://pub.dev/packages/google_mlkit_translation
  - Cloud: Google Cloud Translation, Azure Translator, OpenAI models.

On-device vs cloud STT/Translation
- Privacy: on-device keeps data local; cloud requires disclosure/consent.
- Latency: on-device near-real-time; cloud depends on network but usually fast.
- Cost: on-device free after model download; cloud pay-as-you-go.
- Model size: on-device models can be large; cloud has no device storage.
- Accuracy: cloud generally superior; Whisper (cloud or high-end on-device) is high accuracy; Vosk acceptable for constrained domains.
- Flutter integration: `speech_to_text` easiest but limited; `vosk_flutter` straightforward; Whisper requires native work; cloud is simple HTTP/gRPC.

Suggested app architecture
- State management: Riverpod or Bloc; keep audio/playback state separate from transcription/translation state.
- Service abstraction: interfaces per feature with DI; swap implementations (cloud vs offline) at runtime based on user settings and capability checks.
- Background services: `audio_service` for playback; foreground service for long recordings (`microphone` type) on Android 14+.
- Permissions: centralize flows; rationale screens; graceful fallbacks.
- Caching/offline: manage Vosk/Whisper models and ML Kit packs; storage quotas; allow removal.
- Internationalization: Flutter `intl`; map UI language to STT locale IDs and translation target codes.
- Audio pipeline: `audio_session` for focus; record at 16 kHz mono PCM when feeding STT.

Compatibility strategy
- Flutter/Dart pins: Flutter `3.24.x` (stable), Dart `3.5.x`.
- Android build toolchain: Gradle `8.10.2`, AGP `8.8.0` (avoid 8.6–8.7), Kotlin `2.0.21`, Java `17`.
- NDK: only if integrating whisper.cpp (pin r26c).
- Audio codec support: prefer AAC LC or WAV PCM16 for broad compatibility; avoid Opus unless minSdk 29.
- ExoPlayer vs MediaPlayer: ExoPlayer via `just_audio` for radio/HLS/metadata.
- Foreground services: `mediaPlayback` for radio; `microphone` for recording; handle Doze/battery optimization.
- Network: allow cleartext or network security config when using local proxy (e.g., 127.0.0.1).

Testing strategy
- Unit: service interfaces, locale mapping, caching, retry.
- Integration: `integration_test` for flows; simulate permissions; verify notifications.
- Audio mocks: local MP3/HLS streams; ICY metadata; network loss.
- Device farm: Firebase Test Lab/AWS Device Farm across Android 8–15; include low-end devices.
- Localization: ensure STT/translation language selections work; RTL layouts.

Build & release
- Play policies: prominent disclosure for recording; clear opt-in; no stealth.
- Data Safety: declare mic data and network transmission; retention policy.
- Permission rationale: in-app explanations; fallbacks if denied.
- 64-bit and ABI splits: enable; for whisper.cpp consider `arm64-v8a` only.
- ProGuard/R8: keep rules for `vosk_flutter` (`com.sun.jna.*`) and any plugin specifics.
- OSS licensing: include attributions as needed.

Pros/cons and final recommendation
- On-device path: private, offline; heavier storage/engineering; accuracy varies.
- Cloud path: high accuracy, small app; ongoing cost/privacy.

Final stack recommendation (Dec 2025)
- Radio: `just_audio` + `audio_service` + `audio_session`.
- Recording: `record` (AAC LC or WAV PCM16).
- STT: default Google Cloud Speech-to-Text (streaming); offline fallback `vosk_flutter`; optional Whisper.cpp for high-end devices.
- Translation: default Google Cloud Translation; offline `google_mlkit_translation` packs for selected languages.
- Version pins: Flutter `3.24.x`, Dart `3.5.x`, Gradle `8.10.2`, AGP `8.8.0`, Kotlin `2.0.21`, Java `17`; plugins pinned to latest stable compatible versions.

Notes on implementation details
- Foreground service types: set `android:foregroundServiceType="mediaPlayback"` for playback and `"microphone"` for recording on SDK 34+.
- Cleartext/network security: configure if using local proxy for headers/caching.
- Locale selection: map UI language to STT locale and model choices; manage ML Kit downloads with progress and storage checks.
