import Inject
import SwiftUI

struct ContentView: View {
	@ObserveInjection var redraw
	@State private var dataset: KMeansSolver = KMeansSolver(points: KMeansSolver.generateMouseSet(), clusters: 4)


	private var models: [Renderable] {
		let colors = [
			Vec3(0.8, 0, 0), Vec3(0.8, 0.8, 0), Vec3(0, 0.8, 0), Vec3(0, 0.8, 0.8), Vec3(0, 0, 0.8),
		]
		let points = dataset.points.map({ p in
			Primitive.Sphere(center: p.pos, radius: 1, color: colors[p.cluster % colors.count])
		})
		let centers  = dataset.centroids.enumerated().map({ (i, p) in
			Primitive.Cube(center: p, size: Vec3(2, 2, 2), color: Vec3(0.2, 0.2, 0.2))
		})
		return points + centers
	}

	var body: some View {
		HStack {
			VStack {
				Button("regenerate") {
					dataset = KMeansSolver(points: KMeansSolver.generateMouseSet(), clusters: 4)
				}.keyboardShortcut("r", modifiers: []).buttonStyle(.bordered)

				Button("nextStep") {
					dataset.updateClusters()
				}.keyboardShortcut(.space, modifiers: [])
				Scene3DView(models: models).buttonStyle(.bordered)
			}
		}
		.padding()
		.focusable()
		.focusEffectDisabled()
		.enableInjection()
	}
}
