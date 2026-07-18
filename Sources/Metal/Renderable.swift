import Metal

private enum MeshCache {
	private static var meshes: [ObjectIdentifier: Mesh] = [:]
	static func mesh<T: Renderable>(for type: T.Type, device: MTLDevice) -> Mesh {
		let id = ObjectIdentifier(type)
		if let existingMesh = meshes[id] {
			return existingMesh
		}
		let newMesh = T.createMesh(for: device)
		meshes[id] = newMesh
		return newMesh
	}
}

protocol Renderable {
	var translation: Matrix { get }
	var color: Vec3 { get }
	static func createMesh(for device: MTLDevice) -> Mesh
}

extension Renderable {
	func mesh(for device: MTLDevice) -> Mesh {
		return MeshCache.mesh(for: Self.self, device: device)
	}
}

extension Renderable {
	var uniform: InstanceUniforms {
		InstanceUniforms(
			translation: self.translation, color: self.color)
	}
}

enum Primitive {
	struct Cube: Renderable {
		let center: Vec3
		let size: Vec3
		let color: Vec3
		var translation: Matrix { Matrix.translation(center) * Matrix.scale(size) }

		static func createMesh(for device: MTLDevice) -> Mesh {
            print("making a cube mesh")
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

		static func createMesh(for device: MTLDevice) -> Mesh {
            print("making a sphere mesh")
			return Mesh.sphere(device, vertex_cnt: 10)!
		}
	}
}
