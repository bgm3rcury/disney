# DisneyQueues

A private SwiftUI iPhone app for checking Disneyland Paris attraction wait times from Queue-Times.com.

## Features

- Three tabs: Disneyland Park, Disney Adventure World, and All Parks.
- Queue times from:
  - `https://queue-times.com/parks/4/queue_times.json`
  - `https://queue-times.com/parks/28/queue_times.json`
- Five-minute automatic refresh countdown.
- Manual pull-to-refresh and refresh button.
- Sort by open first, longest wait, shortest wait, or A-Z.
- Favorites saved locally on the phone.
- Queue-Times.com attribution in the app.

## Windows Build And Sideload Flow

Windows cannot compile iOS apps locally because the iOS SDK and Xcode build tools are macOS-only. This repo includes a GitHub Actions workflow that uses GitHub-hosted macOS to build an `.ipa`.

1. Push this repo to GitHub.
2. Open the repo on GitHub.
3. Go to `Actions`.
4. Run `Build iOS IPA`.
5. Download the `DisneyQueues-unsigned-ipa` artifact.
6. Extract the artifact zip to get `DisneyQueues.ipa`.
7. Open Sideloadly on Windows.
8. Connect your iPhone by USB.
9. Select `DisneyQueues.ipa`, enter your Apple ID, and install.

With a free Apple ID, sideloaded apps normally need reinstalling after about 7 days.

## Local Notes

The source can be edited on Windows, but build verification requires either GitHub Actions or a macOS machine with Xcode.
