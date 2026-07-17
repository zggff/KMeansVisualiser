import Metal

protocol Renderable {
	var translation: Matrix { get }
	var color: Vec3 { get }

	static var mesh: Mesh? { get set }
	static func createMesh(for device: MTLDevice) -> Mesh
}

extension Renderable {
	var uniform: InstanceUniforms {
		InstanceUniforms(
			translation: self.translation, color: self.color)
	}
	static func getMesh(for device: MTLDevice) -> Mesh {
		if let existingMesh = mesh {
			return existingMesh
		}
		let newMesh = createMesh(for: device)
		mesh = newMesh
		return newMesh
	}
}

enum Primitive {
	struct Cube: Renderable {
		let center: Vec3
		let size: Vec3
		let color: Vec3
		var translation: Matrix { Matrix.translation(center) * Matrix.scale(size) }

		static var mesh: Mesh? = nil
		static func createMesh(for device: MTLDevice) -> Mesh {
			return Mesh.cube(device)!
		}
	}
	struct Sphere: Renderable {
		let center: Vec3
		let radius: Float
		let color: Vec3
		var translation: Matrix {
			Matrix.translation(center) * Matrix.scale(Vec3(repeating: radius))
		}

		static var mesh: Mesh? = nil
		static func createMesh(for device: MTLDevice) -> Mesh {
			return Mesh.sphere(device)!
		}
	}
}
