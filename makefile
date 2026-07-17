ROOT_FOLDER:=Sources

SOURCES:=$(shell find $(ROOT_FOLDER) -iname "*.swift")

buildServer.json: KMeans.xcodeproj
	xcode-build-server config -project *.xcodeproj

KMeans.xcodeproj: project.yml
	xcodegen generate

KMeans.app: .build/Build/Products/Debug/KMeans.app
	cp -r $< $@

.build/Build/Products/Debug/KMeans.app: $(SOURCES) KMeans.xcodeproj
	xcodebuild \
		-project KMeans.xcodeproj \
		-scheme KMeans \
		-destination "platform=macOS"
		-derivedDataPath .build
