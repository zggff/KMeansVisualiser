import Inject
import SwiftUI
import Renderer3D

struct ContentView: View {
	@ObserveInjection var redraw

	@State var centroidsCount: Float = 3

	@State private var dataset: KMeansSolver = KMeansSolver(
		points: KMeansSolver.generateMouseSet(), clusters: 3)
	@State private var converged = false

	private var models: [Renderable] {
		let colors = [
			Vec3(0.8, 0, 0), Vec3(0.8, 0.8, 0), Vec3(0, 0.8, 0), Vec3(0, 0.8, 0.8), Vec3(0, 0, 0.8),
		]
		let points = dataset.points.map({ p in
			Primitive.Sphere(center: p.pos, radius: 1, color: colors[p.cluster % colors.count])
		})
		let centers = dataset.centroids.enumerated().map({ (i, p) in
			Primitive.Cube(center: p, size: Vec3(2, 2, 2), color: Vec3(0.2, 0.2, 0.2))
		})
		return points + centers
	}

	var body: some View {
		HStack {
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
				Scene3DView(models: models)
			}
		}
		.padding()
		.focusable()
		.focusEffectDisabled()
		.enableInjection()
	}
}
