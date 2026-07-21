import Inject
import Renderer3D
import SwiftUI

struct KMeansImageView: View {
	@ObserveInjection var redraw

	@State var centroidsCount: Float = 10

	@State private var imageOld: NativeImage? = {
		guard let path = Bundle.main.path(forResource: "roses", ofType: "jpg") else { return nil }
		return NativeImage(contentsOfFile: path)
	}()
	@State private var imageNew: NativeImage? = nil

	@State private var dataset: KMeansSolver? = nil
	@State private var converged = false
	@State private var originalColor = true
	@State private var showImage = false
	@State private var isCalculating = false
	@State private var cameraState = CameraState()
	@State private var scene = Scene3D()

	private func setupUpdatedImage() {
		guard showImage && !originalColor else { return }
		guard let dataset = dataset, let image = imageOld else { return }
		isCalculating = true

		#if os(macOS)
			guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
				return
			}
		#elseif os(iOS)
			guard let cgImage = image.cgImage else { return }
		#endif

		let width = cgImage.width
		let height = cgImage.height

		let quantizedPoints = dataset.points.map { p in
			dataset.centroids[p.cluster]
		}
		self.imageNew = generateImage(from: quantizedPoints, width: width, height: height)
		isCalculating = false
	}

	private func setupSolver() {
		guard let imageOld else { return }

		isCalculating = true
		let centroids = Int(centroidsCount)
		Task {
			let newDataset = await Task.detached(priority: .userInitiated) {
				let points = generateImageSet(from: imageOld)
				let dataset = KMeansSolver(points: points, clusters: centroids)
				return dataset
			}.value
			self.dataset = newDataset
			isCalculating = false
		}
	}

	private func setupScene() {
		guard !showImage else { return }

		isCalculating = true
		let points =
			originalColor
			? dataset?.points.map({ p in
				Primitive.Cube(center: p.pos, size: 1, color: p.pos / 0xff)
			}) ?? []
			: dataset?.points.map({ p in
				Primitive.Cube(center: p.pos, size: 1, color: dataset!.centroids[p.cluster] / 0xff)
			}) ?? []

		let centers =
			dataset?.centroids.enumerated().map({ (i, p) in
				Primitive.Sphere(center: p, radius: 2, color: Vec3(0.2, 0.2, 0.2))
			}) ?? []

		scene.removeAll()
		scene.append(objects: points)
		scene.append(objects: centers)
		scene.finishDeclaration()
		self.isCalculating = false

	}

	private func copyToClipboard(_ text: String) {
		#if os(macOS)
			let pasteboard = NSPasteboard.general
			pasteboard.clearContents()
			pasteboard.setString(text, forType: .string)
		#elseif os(iOS)
			UIPasteboard.general.string = text
		#endif
	}

	var controls: some View {
		VStack {
			ImageHandler(
				imageOld: $imageOld, imageNew: $imageNew,
				saveDisabled: isCalculating || !showImage || originalColor)
			Slider(
				value: $centroidsCount, in: 1...40, step: 1,
				onEditingChanged: { editing in
					if editing { return }
					guard let currentDataset = dataset else { return }

					isCalculating = true
					converged = false

					let centroidsCount = Int(centroidsCount)
					guard centroidsCount != currentDataset.centroids.count else { return }
					Task {
						let updatedDataset = await Task.detached(priority: .userInitiated) {
							[currentDataset] in
							var localDataset = currentDataset
							localDataset.createCentroids(count: centroidsCount)
							return localDataset
						}.value

						self.dataset = updatedDataset
						self.isCalculating = false
					}
				}
			)

			Toggle("use original colors", isOn: $originalColor)
			Toggle("show image", isOn: $showImage)
			Button("nextStep") {
				guard let currentDataset = dataset else { return }
				isCalculating = true
				Task {
					let result = await Task.detached(priority: .userInitiated) {
						[currentDataset] in
						var localDataset = currentDataset
						let didConverge = localDataset.updateClusters()
						return (localDataset, didConverge)
					}.value

					self.dataset = result.0
					self.converged = result.1
					self.isCalculating = false
				}

			}.keyboardShortcut(.space, modifiers: []).buttonStyle(.bordered).tint(
				converged ? .green : nil
			).disabled(converged)
		}

	}

	var body: some View {
		HStack {
			if let dataset {
				List {
					Text("\(dataset.centroids.count)").font(.title)
					ForEach(Array(dataset.centroids.enumerated()), id: \.offset) { index, color in
						let uiColor = Color(
							red: Double(color.x) / 0xff,
							green: Double(color.y) / 0xff,
							blue: Double(color.z) / 0xff
						)
						let (x, y, z) = (Int(color.x), Int(color.y), Int(color.z))
						let hexString = String(format: "#%02X%02X%02X", x, y, z)
						HStack {
							Spacer()

							Text(hexString)
								.font(.title2)
								.fontWeight(.bold)
								.foregroundColor(.black)
								.padding(.horizontal, 16)
								.padding(.vertical, 8)
								.background(Color.white)
							Spacer()
						}
						.padding(.vertical, 8)
						.onTapGesture {
							copyToClipboard(hexString)
						}
						.background(uiColor)
					}
				}.frame(
					minWidth: nil, idealWidth: nil, maxWidth: 300, minHeight: nil, idealHeight: nil,
					maxHeight: nil, alignment: .center)
			}
			VStack {
				controls
					.opacity(isCalculating ? 0 : 1)
					.disabled(isCalculating)
					.overlay {
						if isCalculating {
							Text("please wait for the calculation to end")
								.multilineTextAlignment(.center)
						}
					}
				if showImage {
					if originalColor, let image = imageOld {
						#if os(macOS)
							Image(nsImage: image)
								.resizable()
								.scaledToFit()
						#elseif os(iOS)
							Image(uiImage: image)
								.resizable()
								.scaledToFit()
						#endif
					}
					if !originalColor, let image = imageNew {
						#if os(macOS)
							Image(nsImage: image)
								.resizable()
								.scaledToFit()
						#elseif os(iOS)
							Image(uiImage: image)
								.resizable()
								.scaledToFit()
						#endif
					}
				} else {
					Scene3DView(
						scene: $scene, cameraState: $cameraState,
						cameraCenter: Vec3(0xff / 2, 0xff / 2, 0xff / 2))
				}
			}
		}.onAppear {
			setupSolver()
		}
		.onChange(of: imageOld) {
			setupSolver()
		}
		.onChange(of: dataset) {
			setupScene()
			setupUpdatedImage()
		}
		.onChange(of: originalColor) {
			setupScene()
			setupUpdatedImage()
		}
		.onChange(of: showImage) {
			setupUpdatedImage()
		}
		.padding()
		.focusable()
		.focusEffectDisabled()
		.enableInjection()
	}
}

private func generateImage(from points: [Vec3], width: Int, height: Int) -> NativeImage? {
	guard points.count == width * height else { return nil }

	let colorSpace = CGColorSpaceCreateDeviceRGB()
	var pixels = [UInt8](repeating: 0, count: width * height * 4)

	for y in 0..<height {
		for x in 0..<width {
			let index = y * width + x
			let offset = index * 4
			let point = points[index]

			pixels[offset] = UInt8(point.x)
			pixels[offset + 1] = UInt8(point.y)
			pixels[offset + 2] = UInt8(point.z)
			pixels[offset + 3] = 255
		}
	}
	guard
		let context = CGContext(
			data: &pixels,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: width * 4,
			space: colorSpace,
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		)
	else {
		return nil
	}
	guard let cgImage = context.makeImage() else { return nil }
	#if os(macOS)
		return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
	#elseif os(iOS)
		return UIImage(cgImage: cgImage)
	#endif
}

private func generateImageSet(from uiImage: NativeImage) -> [Vec3] {
	#if os(macOS)
		guard let cgImage = uiImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
		else { return [] }
	#elseif os(iOS)
		guard let cgImage = uiImage.cgImage else { return [] }
	#endif

	let width = cgImage.width
	let height = cgImage.height
	let colorSpace = CGColorSpaceCreateDeviceRGB()
	var pixels = [UInt8](repeating: 0, count: width * height * 4)

	guard
		let context = CGContext(
			data: &pixels, width: width, height: height, bitsPerComponent: 8,
			bytesPerRow: width * 4, space: colorSpace,
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
	else {
		return []
	}

	context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

	var points: [Vec3] = []
	for y in 0..<height {
		for x in 0..<width {
			let offset = (y * width + x) * 4
			let r = Float(pixels[offset])
			let g = Float(pixels[offset + 1])
			let b = Float(pixels[offset + 2])

			points.append(Vec3(r, g, b))
		}
	}
	return points
}
