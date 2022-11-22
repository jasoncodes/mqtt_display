.PHONY: run build install dist lint clean
.DEFAULT_GOAL := build

run: lint
	swift run

build: lint
	swift build --configuration release

install: build
	install -v -d ~/.local/bin
	install -v .build/release/mqtt_display ~/.local/bin
	BIN_PATH="$$HOME/.local/bin/mqtt_display" MQTT_URL="$${MQTT_URL?}" envsubst < launchd.template.plist > ~/Library/LaunchAgents/mqtt_display.plist
	if launchctl list | grep -q '\tmqtt_display$$'; then launchctl unload ~/Library/LaunchAgents/mqtt_display.plist; fi
	launchctl load ~/Library/LaunchAgents/mqtt_display.plist

dist: lint
	swift build --configuration release --arch arm64 --arch x86_64
	rm -rf dist
	mkdir dist
	cp launchd.template.plist .build/apple/Products/Release/
	tar cjf dist/mqtt_display.tar.bz2 -C .build/apple/Products/Release mqtt_display launchd.template.plist

lint:
	swiftlint --strict Package.swift Sources

clean:
	swift package clean
	rm -rf dist
