import MetalKit

extension Vertex {
	static var defaultLayout: MTLVertexDescriptor {
		let vertexDescriptor = MTLVertexDescriptor()
		vertexDescriptor.attributes[0].format = .float3
		vertexDescriptor.attributes[0].bufferIndex = 0
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
		return vertexDescriptor
	}
}

private func buildPipeline(device: MTLDevice) -> MTLRenderPipelineState {
	let pipeline: MTLRenderPipelineState
	let pipelineDescriptor = MTLRenderPipelineDescriptor()
	let library = device.makeDefaultLibrary()!

	pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexMain")
	pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentMain")
	pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
	pipelineDescriptor.vertexDescriptor = Vertex.defaultLayout

	do {
		pipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
		return pipeline
	} catch {
		fatalError()
	}
}

class MetalRenderer: NSObject, MTKViewDelegate {
	var parent: MetalView
	var device: MTLDevice!
	var commandQueue: MTLCommandQueue!
	var pipeline: MTLRenderPipelineState

	var sceneUniforms = SceneUniforms()
	var mesh: Mesh
	let allocator: MTKMeshBufferAllocator

	init(_ parent: MetalView, device: MTLDevice) {
		self.parent = parent
		self.device = device
		self.allocator = MTKMeshBufferAllocator(device: device)
		self.commandQueue = device.makeCommandQueue()
		self.pipeline = buildPipeline(device: device)

		self.mesh = Mesh.sphere(device)
		self.sceneUniforms.cameraTranslation = Matrix.translation([0, 0, -4]).inverse

		super.init()
	}

	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		let aspect = Float(view.bounds.width) / Float(view.bounds.height)
		sceneUniforms.projection = Matrix.projection(
			projectionFov: Float(70).degreesToRadians,
			near: 0.1,
			far: 100,
			aspect: aspect)
	}

	func draw(in view: MTKView) {
		guard let drawable = view.currentDrawable else { return }

		let commandBuffer = commandQueue.makeCommandBuffer()!
		let renderPassDescriptor = view.currentRenderPassDescriptor!

		renderPassDescriptor.colorAttachments[0].clearColor = self.parent.backgroundColor
		renderPassDescriptor.colorAttachments[0].loadAction = .clear
		renderPassDescriptor.colorAttachments[0].storeAction = .store

		let renderEncoder = commandBuffer.makeRenderCommandEncoder(
			descriptor: renderPassDescriptor)!
		renderEncoder.setCullMode(.back)
		renderEncoder.setRenderPipelineState(pipeline)

		let instances = [
			ModelUniforms(
				translation:
					Matrix.translation([-0.2, 0, 0])
					* Matrix.rotation(around: [1, 1, 0], radians: Float(50).degreesToRadians)
					* Matrix.scale([1, 1.5, 1]), color: [1, 0, 0]),
			ModelUniforms(
				translation:
					Matrix.translation([1, 0, 0])
					* Matrix.rotation(around: [1, 1, 0], radians: Float(50).degreesToRadians)
					* Matrix.scale([1, 1, 1]), color: [0, 1, 0]),

		]

		let sceneBuffer = device.makeBuffer(
			bytes: &sceneUniforms,
			length: MemoryLayout<SceneUniforms>.stride,
			options: []
		)!

		let modelBuffer = device.makeBuffer(
			bytes: instances,
			length: instances.count * MemoryLayout<ModelUniforms>.stride,
			options: []
		)!

		renderEncoder.setVertexBuffer(mesh.vertex, offset: 0, index: 0)
		renderEncoder.setVertexBuffer(sceneBuffer, offset: 0, index: 1)
		renderEncoder.setVertexBuffer(modelBuffer, offset: 0, index: 2)

		renderEncoder.drawIndexedPrimitives(
			type: .triangle, indexCount: mesh.count, indexType: .uint16,
			indexBuffer: mesh.index,
			indexBufferOffset: 0, instanceCount: instances.count)

		renderEncoder.endEncoding()

		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
}
