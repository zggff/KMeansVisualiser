import SwiftUI

@main
struct SwiftUIMetalApp: App {
	@StateObject var router = Router(path: [.kmeansImage])
	var body: some Scene {
		WindowGroup {
			NavigationStack(path: $router.path) {
				HomeView().environmentObject(router).navigationDestination(for: AppRoute.self) {
					route in
					route.destinationView(router: router)
				}
			}
		}
	}
}

final class Router: ObservableObject {
	@Published var path = NavigationPath()
	init(path routes: [AppRoute]) {
		for route in routes {
			self.path.append(route)
		}

	}
	func push(_ route: AppRoute) {
		path.append(route)
	}
	func pop() {
		if path.isEmpty {
			path.removeLast()
		}
	}
	func reset() {
		path.removeLast(path.count)
	}
}

enum AppRoute: Hashable {
	case home
	case kmeansMouse
	case kmeansImage
}

extension AppRoute {
	@ViewBuilder
	@MainActor
	func destinationView(router: Router) -> some View {
		switch self {
			case .home: HomeView().environmentObject(router)
			case .kmeansMouse: KMeansMouseView().environmentObject(router)
			case .kmeansImage: KMeansImageView().environmentObject(router)
		}
	}
}

struct HomeView: View {
	@EnvironmentObject var router: Router
	var body: some View {
		Button("go to a mouse view") {
			router.push(.kmeansMouse)
		}.buttonStyle(.bordered)
		Button("go to an image view") {
			router.push(.kmeansImage)
		}.buttonStyle(.bordered)

	}
}
