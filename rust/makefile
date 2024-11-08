.DEFAULT_GOAL := help
PROJECTNAME=$(shell basename $(shell dirname "$(PWD)"))
SOURCES=$(sort $(wildcard ./src/*.rs ./src/**/*.rs))
CARGO_TERM_COLOR=always
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
	@if [ $$(uname) == "Darwin" ] ; then cargo +nightly install cargo-lipo ; fi
	rustup target add aarch64-apple-ios x86_64-apple-ios --toolchain nightly
	cargo install cargo-ndk
	rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android --toolchain nightly

## :

# ##############################################################################
# # RECIPES
# ##############################################################################

## all: Compile iOS, Android and bindings targets
all: ios android

## ios: Compile the iOS universal library
ios: target/universal/release/libnekoton_flutter.a

target/universal/release/libnekoton_flutter.a: $(SOURCES)
	@if [ $$(uname) == "Darwin" ] ; then \
		cargo +nightly lipo --release ; \
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
	cargo +nightly ndk --target arm64-v8a --output-dir ../android/src/main/jniLibs build --release
	@echo "[DONE] $@"

target/armv7-linux-androideabi/release/libnekoton_flutter.so: $(SOURCES)
	cargo +nightly ndk --target armeabi-v7a --output-dir ../android/src/main/jniLibs build --release
	@echo "[DONE] $@"

target/i686-linux-android/release/libnekoton_flutter.so: $(SOURCES)
	cargo +nightly ndk --target x86 --output-dir ../android/src/main/jniLibs build --release
	@echo "[DONE] $@"

target/x86_64-linux-android/release/libnekoton_flutter.so: $(SOURCES)
	cargo +nightly ndk --target x86_64 --output-dir ../android/src/main/jniLibs build --release
	@echo "[DONE] $@"

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
