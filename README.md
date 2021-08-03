Extension builder to make [riverpod](https://pub.dev/packages/riverpod) providers for [floor](https://pub.dev/packages/floor) DAOs.

## Installation

Add to your `dev_dependencies` section.

Note: this assumes you are using `floor` and `riverpod_flutter`. No new dependencies are required, since you'll have them from those dependencies (ex: `build_runner`)

## Usage

1. Add to your `pubspec.yaml` in the `dev_dependncies` section
2. Use Floor annotations as normal
3. Run build_runner as normal
4. Use the providers from the generated `MyDao$Providers` class in the database part file

## Features and bugs

- Drop-in addition to `Floor` and `Riverpod`

TODO
- Revisit naming
- Tests
