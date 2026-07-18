struct KMeansSolver {
	static func generateRandomSphericalCluster(center: Vec3, radius: Float, count: Int) -> [Vec3] {
		return (0..<count).map({ _ in
			Vec3(
				radius * pow(Float.random(in: 0...1), 1 / 3),
				asin(Float.random(in: -1...1)),
				Float.random(in: 0...(2 * .pi))
			).polar + center
		})
	}

	static func generateMouseSet() -> [Vec3] {
		var points: [Vec3] = []
		points.append(
			contentsOf: generateRandomSphericalCluster(
				center: [80, 50, 0], radius: 40, count: 1000))
		points.append(
			contentsOf: generateRandomSphericalCluster(
				center: [-80, 50, 10], radius: 40, count: 1000))
		points.append(
			contentsOf: generateRandomSphericalCluster(
				center: [0, -20, 0], radius: 100, count: 10000))
		return points
	}

	var points: [ClusteredPoint]
	var centroids: [Vec3] = []
	let bounds: (Vec3, Vec3)

	private var converged: Bool = false

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
		self.points = points.map { p in ClusteredPoint(pos: p, cluster: 0) }
        self.createCentroids(count: clusters)
	}

	mutating func createCentroids(count: Int) {
		self.centroids = (0..<count).map({ _ in
			Vec3(
				Float.random(in: bounds.0.x...bounds.1.x),
				Float.random(in: bounds.0.y...bounds.1.y),
				Float.random(in: bounds.0.z...bounds.1.z),
			)
		})
        self.assignToClusters()
	}

	mutating func assignToClusters() {
		for i in 0..<points.count {
			let pos = points[i].pos
			var bestDist = Float.infinity
			var bestId = 0
			for (id, center) in centroids.enumerated() {
				let dist = (pos - center).lengthSquared
				if dist < bestDist {
					bestDist = dist
					bestId = id
				}
			}
			points[i].cluster = bestId
		}
	}

	mutating func updateClusters() -> Bool {
		if converged {
			return converged
		}
		let newCentroids = centroids.enumerated().map({ (id, _) in
			let matchingPoints = self.points.filter({ p in p.cluster == id })
			guard !matchingPoints.isEmpty else {
				return Vec3(
					Float.random(in: bounds.0.x...bounds.1.x),
					Float.random(in: bounds.0.y...bounds.1.y),
					Float.random(in: bounds.0.z...bounds.1.z),
				)
			}
			return matchingPoints.reduce(
				into: Vec3(0, 0, 0), { partialResult, p in partialResult += p.pos })
				/ Float(matchingPoints.count)

		})
		converged = zip(centroids, newCentroids).allSatisfy({ (a, b) in
			(a - b).lengthSquared < Float.ulpOfOne
		})
		if !converged {
			centroids = newCentroids
			assignToClusters()
		}
		return converged
	}

}

struct ClusteredPoint {
	let pos: Vec3
	var cluster: Int
}
