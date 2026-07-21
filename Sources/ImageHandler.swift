import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
	import AppKit
	public typealias NativeImage = NSImage
#elseif os(iOS)
	import UIKit
	public typealias NativeImage = UIImage
#endif

struct ImageHandler: View {
	init(
		imageOld: Binding<NativeImage?>, imageNew: Binding<NativeImage?>, saveDisabled: Bool
	) {
		self._imageNew = imageNew
		self._imageOld = imageOld
		self.saveDisabled = saveDisabled
	}

	@State private var newImageSelection: PhotosPickerItem? = nil
	@Binding private var imageOld: NativeImage?
	@Binding private var imageNew: NativeImage?
	private var saveDisabled: Bool

	private func loadNewImage() {
		guard let imageSelection = newImageSelection else { return }
		imageSelection.loadTransferable(type: Data.self) { result in
			DispatchQueue.main.async {
				guard case .success(let data?) = result else { return }
				guard let nsImage = NativeImage(data: data) else { return }
				self.imageOld = nsImage
			}
		}
	}

	private func saveImageToDiskOrPhotos(image: NativeImage) {
		#if os(macOS)
			let savePanel = NSSavePanel()
			savePanel.allowedContentTypes = [.png, .jpeg]
			savePanel.canCreateDirectories = true
			savePanel.nameFieldStringValue = "kmeans_output.png"

			savePanel.begin { response in
				guard response == .OK, let url = savePanel.url else { return }
				guard let tiffData = image.tiffRepresentation,
					let bitmapImage = NSBitmapImageRep(data: tiffData),
					let pngData = bitmapImage.representation(using: .png, properties: [:])
				else { return }

				try? pngData.write(to: url)
			}
		#elseif os(iOS)
			PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
				guard status == .authorized || status == .limited else { return }
				PHPhotoLibrary.shared().performChanges {
					PHAssetChangeRequest.creationRequestForAsset(from: image)
				}
			}
		#endif
	}

	#if os(macOS)
		private func openImageWithPanel() {
			let openPanel = NSOpenPanel()
			openPanel.allowedContentTypes = [.image]
			openPanel.allowsMultipleSelection = false
			openPanel.canChooseDirectories = false
			openPanel.canChooseFiles = true

			openPanel.begin { response in
				guard response == .OK, let url = openPanel.url else { return }
				guard let loadedImage = NSImage(contentsOf: url) else { return }

				DispatchQueue.main.async {
					self.imageOld = loadedImage
				}
			}
		}
	#endif

	var body: some View {
		HStack {
			#if os(iOS)
				PhotosPicker(
					selection: $newImageSelection,
					matching: .images
				) {
					Text("load new image")
				}.onChange(
					of: newImageSelection,
					{
						loadNewImage()
					}
				).buttonStyle(.bordered)
			#elseif os(macOS)
				Button("Load New Image") {
					openImageWithPanel()
				}
				.buttonStyle(.bordered)
			#endif
			Button("save generated image") {
				if let imageNew {
					saveImageToDiskOrPhotos(image: imageNew)
				}
			}.buttonStyle(.bordered)
				.disabled(saveDisabled)
		}
	}

}
