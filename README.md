# AWS Solution Clickstream Analytics SDK for Swift

## Introduction

Clickstream iOS SDK can help you easily report in-app events on iOS. After the event is reported, statistics and analysis of specific scenario data can be completed on AWS Clickstream solution.

The SDK relies on the Amplify for Swift Core Library and is developed according to the Amplify Swift SDK plug-in specification. In addition to this, we've added commonly used preset event statistics to make it easier to use.

## Platform Support

The Clickstream SDK supports iOS 13+.

## How to build&test locally

### Config your code format

Install [swiftformat plugin](https://github.com/nicklockwood/SwiftFormat#xcode-source-editor-extension) in your Xcode, and config shortcut for code format.

### Config your code lint

Install [swiftlint](https://github.com/realm/SwiftLint), and execute the below command at the project root folder:

```bash
swiftlint
```

### Build

Open an termial window, at the root project folder to execute: 

```bash
swift build
```

### Test

```bash
swift test
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under [Apache 2.0 License](./LICENSE).
