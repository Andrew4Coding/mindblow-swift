# Mindblow

Blow into your phone to inflate a tire, and stop before it pops. The microphone
hears your breath live; nothing is recorded or stored. Single-player keeps a
local leaderboard, two-player passes the phone between turns. A **Hold to
Inflate** button works when blowing isn't an option or the microphone is off.

## Requirements

- Xcode (see [`.xcode-version`](.xcode-version))
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): the `.xcodeproj` is generated from [`project.yml`](project.yml) and is not committed
- iOS 26.0+, iPhone, portrait

```bash
brew install xcodegen
```

## Getting started

```bash
xcodegen generate
open MindBlow.xcodeproj
```

Re-run `xcodegen generate` after changing `project.yml` or adding/removing
files, and commit `project.yml`, not the generated project.

Run the unit tests:

```bash
xcodebuild test -project MindBlow.xcodeproj -scheme MindBlow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Architecture

MVVM with `@Observable` view models. Views own no game logic, view models own
no UI, and every side effect (microphone, audio, haptics, storage) sits behind
a protocol injected from one composition root, so view models are testable and
previews run without hardware.

```
App/            Entry point, AppEnvironment (composition root)
Core/
  Input/        BlowDetecting protocol, microphone engine, FFT feature extraction, BlowEstimator
  Audio/        SoundPlaying protocol, AVAudioPlayer service, audio session setup
  Haptics/      HapticsProviding protocol, CoreHaptics service
  Storage/      PreferencesStoring + LeaderboardStoring (UserDefaults-backed)
  Preview/      In-memory stubs used by previews and tests
Features/       One folder per screen: View + ViewModel
  Game/  GameModeSelection/  HowToPlay/  Leaderboard/  SaveScore/  Skins/  Settings/
Models/         GameMode, TireSkin, LeaderboardEntry
UI/             Shared components and effects (confetti, particles)
Resources/      Assets, audio, string catalogs, privacy manifest
Tests/          Swift Testing suites
```

Signal path: `MicrophoneBlowDetector` → `AudioFeatureExtractor` (vDSP, audio
thread) → `BlowEstimator` (calibration and smoothing, pure) → `GameViewModel`.

## Localization

English and Indonesian via `Resources/Localizable.xcstrings` and
`Resources/InfoPlist.xcstrings`.

## Releasing with Fastlane

Lanes live in [`fastlane/Fastfile`](fastlane/Fastfile). Authentication uses an
App Store Connect API key: copy `fastlane/.env.default` to `fastlane/.env` and
fill it in (it is gitignored, as is the `.p8` key).

```bash
bundle install
bundle exec fastlane ios beta            # build + upload to TestFlight (internal)
bundle exec fastlane ios beta_external   # + submit to Beta App Review
bundle exec fastlane ios release         # build + upload binary and metadata
bundle exec fastlane ios metadata        # push text metadata only
bundle exec fastlane ios build           # local signed .ipa, no upload
bundle exec fastlane ios bump            # build number = latest TestFlight + 1
```

Store text is in `fastlane/metadata/en-US/`. The build number is kept in
`project.yml` and bumped by the lanes.
