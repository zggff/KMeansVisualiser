// import Inject
// import Renderer3D
// import SwiftUI
//
// struct CameraState: Observable {
// 	var yaw: Float = 0
// 	var pitch: Float = 0
// 	var distance: Float = 100
// }
//
// struct Scene3DView: View {
// 	init(
// 		scene: Scene3D,
// 		cameraState: Binding<CameraState>,
// 		cameraCenter: Vec3 = Vec3(0, 0, 0)
// 	) {
// 		self.scene = scene
// 		self._cameraState = cameraState
// 		self.cameraCenter = cameraCenter
// 	}
//
// 	@ObserveInjection var redraw
// 	@Binding var cameraState: CameraState
// 	var scene: Scene3D
//
// 	let minDistance: Float = 4.0
//
// 	var cameraCenter: Vec3 = Vec3(0, 0, 0)
//
// 	var body: some View {
// 		MetalView(
// 			backgroundColor: MTLClearColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0),
// 			camera: Camera(
// 				pitch: cameraState.pitch.degrees, yaw: cameraState.yaw.degrees,
// 				radius: cameraState.distance,
// 				look_at: cameraCenter,
// 				origin: cameraCenter),
// 			scene: scene,
// 			onScroll: { deltaY in
// 				cameraState.distance = max(minDistance, cameraState.distance - Float(deltaY))
// 			}
// 		).gesture(
// 			DragGesture()
// 				.onChanged { value in
// 					self.cameraState.yaw += Float(value.velocity.width) / 100
// 					self.cameraState.pitch += Float(value.velocity.height) / 100
// 				}.simultaneously(
// 					with: MagnifyGesture()
// 						.onChanged { value in
// 							let delta = Float(value.velocity)
// 							cameraState.distance = max(
// 								minDistance, cameraState.distance - delta * 5.0)
// 						})
// 		).enableInjection()
// 	}
// }
