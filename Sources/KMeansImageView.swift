import Inject
import Renderer3D
import SwiftUI

#if os(macOS)
	import AppKit
	public typealias UIImage = NSImage
#elseif os(iOS)
	import UIKit
#endif

struct KMeansImageView: View {
	@ObserveInjection var redraw

	@State var centroidsCount: Float = 3

	@State private var image: UIImage? = {
		guard let path = Bundle.main.path(forResource: "roses", ofType: "jpg") else { return nil }
		return UIImage(contentsOfFile: path)
	}()

	@State private var dataset: KMeansSolver? = nil
	@State private var converged = false
	@State private var originalColor = true
	@State private var showImage = false
	@State private var isCalculating = false
	@State private var cameraState = CameraState()
	@State private var scene = Scene3D()

	private func setupSolver() {
		guard let image else { return }
		let points = KMeansSolver.generateImageSet(from: image)
		dataset = KMeansSolver(points: points, clusters: 3)
	}

	private func setupScene() {
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
	}

	var body: some View {
		VStack {
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
				}).disabled(isCalculating)
			Text("\(centroidsCount)")

			Toggle("use original colors", isOn: $originalColor)
			Toggle("show image", isOn: $showImage)
			Button("nextStep") {
				guard let currentDataset = dataset else { return }
				isCalculating = true
				Task {
					let result = await Task.detached(priority: .userInitiated) { [currentDataset] in
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
			).disabled(converged).disabled(isCalculating)

			if showImage, let image = image {
				#if os(macOS)
					Image(nsImage: image)
						.resizable()
						.scaledToFit()
				#elseif os(iOS)
					Image(uiImage: image)
						.resizable()
						.scaledToFit()
				#endif
			} else {
				Scene3DView(
					scene: $scene, cameraState: $cameraState,
					cameraCenter: Vec3(0xff / 2, 0xff / 2, 0xff / 2))
			}
		}.onAppear { setupSolver() }.onChange(of: dataset, { setupScene() }).onChange(
			of: originalColor, { setupScene() }
		)
		.padding()
		.focusable()
		.focusEffectDisabled()
		.enableInjection()
	}
}

extension KMeansSolver {
	static func generateImageSet(from uiImage: UIImage) -> [Vec3] {
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
				let r = Float(pixels[offset]) / 255.0
				let g = Float(pixels[offset + 1]) / 255.0
				let b = Float(pixels[offset + 2]) / 255.0

				points.append(Vec3(r * 0xff, g * 0xff, b * 0xff))
			}
		}
		return points
	}
}
