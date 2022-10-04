.DEFAULT_GOAL := help
PROJECTNAME=$(shell basename $(shell dirname "$(PWD)"))
SOURCES=$(sort $(wildcard ./src/*.rs ./src/**/*.rs))

SHELL := /bin/bash

# ##############################################################################
# # GENERAL
# ##############################################################################

.PHONY: help
help: makefile
	@echo
	@echo " Available actions in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'
	@echo

## init: Install missing dependencies.
.PHONY: init
init:
	rustup override set nightly
	@if [ $$(uname) == "Darwin" ] ; then cargo +nightly install cargo-lipo ; fi
	# rustup target add armv7-apple-ios armv7s-apple-ios i386-apple-ios ## deprecated
	rustup target add aarch64-apple-ios x86_64-apple-ios --toolchain nightly
	cargo +nightly install cargo-ndk
	rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android --toolchain nightly
	rustup target add aarch64-apple-darwin x86_64-apple-darwin --toolchain nightly
	rustup target add x86_64-pc-windows-gnu --toolchain nightly
	rustup target add x86_64-unknown-linux-gnu --toolchain nightly
	cargo +nightly install cbindgen

## :

# ##############################################################################
# # RECIPES
# ##############################################################################

## all: Compile iOS, Android and bindings targets
all: ios android bindings

## ios: Compile the iOS universal library
ios: target/universal/release/libnekoton_flutter.a

target/universal/release/libnekoton_flutter.a: $(SOURCES)
	@if [ $$(uname) == "Darwin" ] ; then \
		cargo lipo --release ; \
		cp $@ ../ios/libnekoton_flutter.a ; \
		else echo "Skipping iOS compilation on $$(uname)" ; \
	fi
	@echo "[DONE] $@"

## android: Compile the android targets (arm64, armv7 and i686)
android: target/aarch64-linux-android/release/libnekoton_flutter.so \
	target/armv7-linux-androideabi/release/libnekoton_flutter.so \
	target/i686-linux-android/release/libnekoton_flutter.so \
	target/x86_64-linux-android/release/libnekoton_flutter.so

target/aarch64-linux-android/release/libnekoton_flutter.so: $(SOURCES)
	cargo ndk --target arm64-v8a --output-dir ../android/src/main/jniLibs build --release
	@echo "[DONE] $@"

target/armv7-linux-androideabi/release/libnekoton_flutter.so: $(SOURCES)
	cargo ndk --target armeabi-v7a --output-dir ../android/src/main/jniLibs build --release
	@echo "[DONE] $@"

target/i686-linux-android/release/libnekoton_flutter.so: $(SOURCES)
	cargo ndk --target x86 --output-dir ../android/src/main/jniLibs build --release
	@echo "[DONE] $@"

target/x86_64-linux-android/release/libnekoton_flutter.so: $(SOURCES)
	cargo ndk --target x86_64 --output-dir ../android/src/main/jniLibs build --release
	@echo "[DONE] $@"

## macos: Compile the macOS libraries
macos: target/x86_64-apple-darwin/release/libnekoton_flutter.dylib \
	target/aarch64-apple-darwin/release/libnekoton_flutter.dylib

target/x86_64-apple-darwin/release/libnekoton_flutter.dylib: $(SOURCES)
	@if [ $$(uname) == "Darwin" ] ; then \
		cargo lipo --release --targets x86_64-apple-darwin ; \
		install_name_tool -id @rpath/../Frameworks/libnekoton_flutter_x86_64.dylib $@ ; \
		cp $@ ../macos/libnekoton_flutter_x86_64.dylib ; \
		else echo "Skipping macOS compilation on $$(uname)" ; \
	fi
	@echo "[DONE] $@"

target/aarch64-apple-darwin/release/libnekoton_flutter.dylib: $(SOURCES)
	@if [ $$(uname) == "Darwin" ] ; then \
		cargo lipo --release --targets aarch64-apple-darwin ; \
		install_name_tool -id @rpath/../Frameworks/libnekoton_flutter_aarch64.dylib $@ ; \
		cp $@ ../macos/libnekoton_flutter_aarch64.dylib ; \
		else echo "Skipping macOS compilation on $$(uname)" ; \
	fi
	@echo "[DONE] $@"

## windows: Compile the Windows libraries
windows: target/x86_64-pc-windows-gnu/release/nekoton_flutter.dll

target/x86_64-pc-windows-gnu/release/nekoton_flutter.dll: $(SOURCES)
	cargo build --target x86_64-pc-windows-gnu --release
	cp $@ ../windows/include/nekoton_flutter.dll
	@echo "[DONE] $@"

## linux: Compile the Linux libraries
linux: target/x86_64-unknown-linux-gnu/release/libnekoton_flutter.so

target/x86_64-unknown-linux-gnu/release/libnekoton_flutter.so: $(SOURCES)
	cargo build --target x86_64-unknown-linux-gnu --release ; \
	cp $@ ../linux/include/libnekoton_flutter.so ; \
	@echo "[DONE] $@"

## bindings: Generate the .h file for iOS
bindings: target/bindings.h

target/bindings.h: $(SOURCES)
	cbindgen src/lib.rs -c cbindgen.toml > $@
	@echo "[DONE] $@"

## :

# ##############################################################################
# # OTHER
# ##############################################################################

## clean:
.PHONY: clean
clean:
	cargo clean
	rm -f target/bindings.h target/bindings.src.h

## test:
.PHONY: test
test:
	cargo test
