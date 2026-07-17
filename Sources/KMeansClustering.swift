struct KMeansSolver {
	static func generateRandomSphericalCluster(center: Vec3, radius: Float, count: Int) -> [Vec3] {
		return (0..<count).map({ _ in
			Vec3(
				Float.random(in: 0...radius),
				Float.random(in: 0...(2 * .pi)),
				Float.random(in: 0...(2 * .pi))
			).polar + center
		})
	}

	static func generateMouseSet() -> [Vec3] {
		var points: [Vec3] = []
		points.append(
			contentsOf: generateRandomSphericalCluster(center: [15, 10, 0], radius: 10, count: 20))
		points.append(
			contentsOf: generateRandomSphericalCluster(center: [-15, 10, 0], radius: 10, count: 22))
		points.append(
			contentsOf: generateRandomSphericalCluster(center: [0, 0, 0], radius: 20, count: 40))
		return points
	}

	var points: [ClusteredPoint]
	var centroids: [Vec3]
	let bounds: (Vec3, Vec3)

	init(points: [Vec3], clusters: Int) {
		let first = points.first ?? Vec3(0, 0, 0)
		var upper = first
		var lower = first
		for p in points {
			lower.x = min(lower.x, p.x)
			lower.y = min(lower.y, p.y)
			lower.z = min(lower.z, p.z)
			upper.x = max(upper.x, p.x)
			upper.y = max(upper.y, p.y)
			upper.z = max(upper.z, p.z)

		}
		self.bounds = (lower, upper)
		self.centroids = (0..<clusters).map({ _ in
			Vec3(
				Float.random(in: lower.x...upper.x),
				Float.random(in: lower.y...upper.y),
				Float.random(in: lower.z...upper.z),
			)
		})
		self.points = points.map { p in ClusteredPoint(pos: p, cluster: 0) }
		self.assignToClusters()
	}

	mutating func assignToClusters() {
		for i in 0..<points.count {
			let pos = points[i].pos
			for (id, center) in centroids.enumerated() {
				if (pos - center).length < (pos - centroids[points[i].cluster]).length {
					points[i].cluster = id
				}
			}
		}
	}

	mutating func updateClusters() {
		for (id, _) in centroids.enumerated() {
			let matchingPoints = self.points.filter({ p in p.cluster == id })
			guard !matchingPoints.isEmpty else {
				centroids[id] = Vec3(
					Float.random(in: bounds.0.x...bounds.1.x),
					Float.random(in: bounds.0.y...bounds.1.y),
					Float.random(in: bounds.0.z...bounds.1.z),
				)
				continue
			}
			self.centroids[id] =
				matchingPoints.reduce(
					into: Vec3(0, 0, 0), { partialResult, p in partialResult += p.pos })
				/ Float(matchingPoints.count)
		}
        self.assignToClusters()
	}

}

struct ClusteredPoint {
	let pos: Vec3
	var cluster: Int
}
