protocol Renderable {
	var meshId: MeshType { get }
	var translation: Matrix { get }
	var color: Vec3 { get }
}

extension Renderable {
	var uniform: InstanceUniforms {
		InstanceUniforms(
			translation: self.translation, color: self.color)
	}
}

enum Primitive: Renderable {
	case cube(center: Vec3, size: Vec3, color: Vec3)
	case sphere(center: Vec3, radius: Float, color: Vec3)

	var meshId: MeshType {
		return switch self {
			case .cube: MeshType.Cube
			case .sphere: MeshType.Sphere
		}
	}
	var translation: Matrix {
		return switch self {
			case .cube(let center, let size, _):
				Matrix.translation(center) * Matrix.scale(size)
			case .sphere(let center, let radius, _):
				Matrix.translation(center) * Matrix.scale(Vec3(repeating: radius))
		}
	}

	var color: Vec3 {
		return switch self {
			case .cube(_, _, let color): color
			case .sphere(_, _, let color): color
		}
	}
}
