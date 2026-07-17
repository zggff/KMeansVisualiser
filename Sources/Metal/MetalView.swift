import MetalKit
import SwiftUI

#if os(macOS)
	public typealias NativeView = NSView
	public typealias NativeApplication = NSApplication
	public typealias ViewRepresentable = NSViewRepresentable
	public typealias ViewRepresentableContext = NSViewRepresentableContext
	public typealias ViewControllerRepresentable = NSViewControllerRepresentable

#elseif os(iOS)
	public typealias NativeView = UIView
	public typealias NativeApplication = UIApplication
	public typealias ViewRepresentable = UIViewRepresentable
	public typealias ViewRepresentableContext = UIViewRepresentableContext
	public typealias ViewControllerRepresentable = UIViewControllerRepresentable
#endif

struct MetalView: ViewRepresentable {
	let backgroundColor: MTLClearColor
    let camera: Camera
    let models: [Renderable]

    var onScroll: ((CGFloat) -> Void)? = nil

    private static let device: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("No Metal device")
        }
        return device
    }()
	func makeCoordinator() -> MetalRenderer {
		MetalRenderer(self, device: Self.device)
	}

	func makeNSView(context: ViewRepresentableContext<MetalView>) -> MTKView {
		let mtkView = CustomMTKView()
		mtkView.delegate = context.coordinator
		mtkView.preferredFramesPerSecond = 60
		mtkView.enableSetNeedsDisplay = true
        mtkView.depthStencilPixelFormat = .depth32Float

		mtkView.device = Self.device
		mtkView.framebufferOnly = false
		mtkView.drawableSize = mtkView.frame.size

        mtkView.scrollHandler = onScroll
		return mtkView
	}

    private class CustomMTKView: MTKView {
        var scrollHandler: ((CGFloat) -> Void)?
        
        #if os(macOS)
        override func scrollWheel(with event: NSEvent) {
            if let scrollHandler = scrollHandler {
                scrollHandler(event.deltaY)
            } else {
                super.scrollWheel(with: event)
            }
        }
        #endif
    }

	func updateNSView(_ uiView: MTKView, context: ViewRepresentableContext<MetalView>) {
		context.coordinator.parent = self
		#if os(macOS)
			uiView.needsDisplay = true
		#elseif os(iOS)
			uiView.setNeedsDisplay()
		#endif
	}

	func makeUIView(context: ViewRepresentableContext<MetalView>) -> MTKView {
		return makeNSView(context: context)
	}

	func updateUIView(_ uiView: MTKView, context: ViewRepresentableContext<MetalView>) {
		updateNSView(uiView, context: context)
	}
}
