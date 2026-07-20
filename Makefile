ENTITLEMENTS := t.entitlements

.PHONY: build release test clean

build:
	swift build
	codesign --force --sign - --entitlements $(ENTITLEMENTS) $$(swift build --show-bin-path)/t

release:
	swift build -c release
	codesign --force --sign - --entitlements $(ENTITLEMENTS) $$(swift build -c release --show-bin-path)/t

test:
	swift test

clean:
	swift package clean
