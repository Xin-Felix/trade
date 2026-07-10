import SwiftUI

@main
struct YingPlusApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil  // 跟随系统
        }
    }
}
