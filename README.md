# nekoton-flutter

Flutter plugin for TON wallets core

## How to build & run

1. Install Rust by running  
   `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

2. Install LLVM by running  
   `brew install llvm`

3. Add package to `pubspec.yaml` and run `flutter pub get` to load dependencies

4. Run build on package with following command  
   `flutter pub run nekoton_flutter:build /Your/Path/To/Android/NDK`
