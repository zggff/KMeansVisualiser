import Inject
import Renderer3D
import SwiftUI

struct KMeansMouseView: View {
	@ObserveInjection var redraw

	@State var centroidsCount: Float = 3

	@State private var dataset: KMeansSolver = KMeansSolver(
		points: KMeansSolver.generateMouseSet(), clusters: 3)
	@State private var converged = false
	@State private var cameraState = CameraState()
	@State private var scene = Scene3D()

	private func setupScene() {
		let colors = [
			Vec3(0.8, 0, 0), Vec3(0.8, 0.8, 0), Vec3(0, 0.8, 0), Vec3(0, 0.8, 0.8), Vec3(0, 0, 0.8),
		]
		let points = dataset.points.map({ p in
			Primitive.Sphere(center: p.pos, radius: 1, color: colors[p.cluster % colors.count])
		})
		let centers = dataset.centroids.enumerated().map({ (i, p) in
			Primitive.Cube(center: p, size: 2, color: Vec3(0.2, 0.2, 0.2))
		})

		scene.draw { ctx in
			ctx.append(objects: points)
			ctx.append(objects: centers)
		}
	}

	var body: some View {
		VStack {
			Slider(value: $centroidsCount, in: 1...5, step: 1).onChange(
				of: centroidsCount,
				{
					let centroidsCount = Int(centroidsCount)
					if centroidsCount != dataset.centroids.count {
						dataset.createCentroids(count: centroidsCount)
					}
				})
			Button("regenerate with \(Int(centroidsCount)) centroids") {
				converged = false
				dataset = KMeansSolver(
					points: KMeansSolver.generateMouseSet(), clusters: Int(centroidsCount))
			}.keyboardShortcut("r", modifiers: []).buttonStyle(.bordered)

			Button("nextStep") {
				converged = dataset.updateClusters()
			}.keyboardShortcut(.space, modifiers: []).buttonStyle(.bordered).tint(
				converged ? .green : nil
			).disabled(converged)
			Scene3DView(scene: scene, cameraState: $cameraState)
		}.onAppear { setupScene() }.onChange(of: dataset, { setupScene() })
			.padding()
			.focusable()
			.focusEffectDisabled()
			.enableInjection()
	}
}
