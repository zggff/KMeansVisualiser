public typealias Matrix = float4x4
public typealias Vec3 = SIMD3<Float>
public typealias Vec4 = SIMD4<Float>

extension FloatingPoint {
	var degreesToRadians: Self {
		return self * .pi / 180
	}
	var radiansToDegrees: Self {
		return self * 180 / .pi
	}
}

extension Matrix {
	static func projection(projectionFov fov: Float, near: Float, far: Float, aspect: Float)
		-> Matrix
	{
		let y = 1 / tan(fov * 0.5)
		let x = y / aspect
		let z = far / (far - near)
		return Matrix(
			columns: (
				Vec4(x, 0, 0, 0),
				Vec4(0, y, 0, 0),
				Vec4(0, 0, z, 1),
				Vec4(0, 0, z * -near, 0)
			)
		)
	}

	static func translation(_ dimensions: Vec3) -> Matrix {
		return Matrix(
			Vec4(1, 0, 0, 0),
			Vec4(0, 1, 0, 0),
			Vec4(0, 0, 1, 0),
			Vec4(dimensions.x, dimensions.y, dimensions.z, 1),
		)
	}
	static func scale(_ dimensions: Vec3) -> Matrix {
		return Matrix(diagonal: Vec4(dimensions.x, dimensions.y, dimensions.z, 1))
	}
	static func rotation(around axis: Vec3, radians angle: Float) -> Matrix {
		let u = normalize(axis)
		let (x, y, z) = (u.x, u.y, u.z)
		let cosv = cos(angle)
		let sinv = sin(angle)

		return Matrix(
			Vec4(
				x * x * (1 - cosv) + cosv, x * y * (1 - cosv) + z * sinv,
				x * z * (1 - cosv) - y * sinv, 0),
			Vec4(
				y * x * (1 - cosv) - z * sinv, y * y * (1 - cosv) + cosv,
				y * z * (1 - cosv) + x * sinv, 0),
			Vec4(
				z * x * (1 - cosv) + y * sinv, z * y * (1 - cosv) - x * sinv,
				z * z * (1 - cosv) + cosv, 0),
			Vec4(0, 0, 0, 1),
		)
	}
}
