# AgentMonitor Makefile
# Builds and packages the AgentMonitor macOS menu bar app
# No Apple Developer Program required — uses ad-hoc signing

SCHEME = AgentMonitor
PROJECT = AgentMonitor.xcodeproj
BUILD_DIR = build
RELEASE_DIR = $(BUILD_DIR)/Release
APP_NAME = AgentMonitor.app
APP_PATH = $(RELEASE_DIR)/$(APP_NAME)
DMG_NAME = AgentMonitor.dmg
DMG_STAGING = $(BUILD_DIR)/dmg-staging

.PHONY: build run dmg clean release

## Build the Release .app (ad-hoc signed, no Developer Program needed)
build:
	xcodebuild -scheme $(SCHEME) \
		-project $(PROJECT) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR)/DerivedData \
		CONFIGURATION_BUILD_DIR=$(RELEASE_DIR) \
		build

## Build and launch the app
run: build
	open $(APP_PATH)

## Create a DMG for distribution (unsigned — users bypass Gatekeeper via right-click → Open)
dmg: build
	@echo "Creating DMG..."
	@rm -rf $(DMG_STAGING)
	@mkdir -p $(DMG_STAGING)
	@cp -r $(APP_PATH) $(DMG_STAGING)/
	@ln -s /Applications $(DMG_STAGING)/Applications
	@hdiutil create \
		-volname "AgentMonitor" \
		-srcfolder $(DMG_STAGING) \
		-ov \
		-format UDZO \
		$(DMG_NAME)
	@rm -rf $(DMG_STAGING)
	@echo "Created $(DMG_NAME)"

## Remove build artifacts
clean:
	@rm -rf $(BUILD_DIR) $(DMG_NAME)
	@echo "Cleaned build artifacts"

## Instructions for notarized public distribution (requires Apple Developer Program)
release:
	@echo ""
	@echo "=== Public Distribution (Notarized) ==="
	@echo "Requires Apple Developer Program (\$$99/year)"
	@echo ""
	@echo "Steps:"
	@echo "  1. Enroll at https://developer.apple.com/programs/"
	@echo "  2. Create Developer ID Application certificate in Xcode"
	@echo "  3. Update CODE_SIGN_IDENTITY in project.yml"
	@echo "  4. Run: xcodebuild -scheme AgentMonitor -configuration Release archive"
	@echo "  5. Notarize: xcrun notarytool submit AgentMonitor.dmg --apple-id <email> --team-id <team>"
	@echo "  6. Staple: xcrun stapler staple AgentMonitor.dmg"
	@echo ""
	@echo "For local use, 'make build && make run' is sufficient."
	@echo ""
