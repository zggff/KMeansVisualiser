import Inject
import SwiftUI

struct ContentView: View {
	@ObserveInjection var redraw

	@State private var index = 0
	private var colors = [
		MTLClearColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 1.0),
		MTLClearColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0),
		MTLClearColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0),
	]

	var body: some View {
		VStack(spacing: 20) {
			Button("\(index + 1) out of \(colors.count)") {
				index += 1
				if index >= colors.count {
					index = 0
				}
			}
			MetalView(backgroundColor: colors[index])
		}
		.padding()
		.enableInjection()
	}
}
