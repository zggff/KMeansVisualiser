import Inject
import SwiftUI
import Renderer3D

struct Scene3DView: View {
	@ObserveInjection var redraw

	@State var yaw: Float = 0
	@State var pitch: Float = 0
	@State var distance: Float = 20.0

	let minDistance: Float = 4.0

	var models: [any Renderable]

	var body: some View {
		MetalView(
			backgroundColor: MTLClearColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0),
			camera: Camera(
				pitch: pitch.degrees, yaw: yaw.degrees, radius: distance,
				look_at: [0, 0, 0],
				origin: [0, 0, 0]),
			models: models,
			onScroll: { deltaY in
				distance = max(minDistance, distance - Float(deltaY))
			}
		).gesture(
			DragGesture()
				.onChanged { value in
					self.yaw += Float(value.velocity.width) / 100
					self.pitch += Float(value.velocity.height) / 100
				}.simultaneously(
					with: MagnifyGesture()
						.onChanged { value in
							let delta = Float(value.velocity)
							distance = max(minDistance, distance - delta * 5.0)
						})
		).enableInjection()
	}
}
