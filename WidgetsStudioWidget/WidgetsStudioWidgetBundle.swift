import WidgetKit
import SwiftUI

@main
struct WidgetsStudioWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClockWidget()
        WeatherWidget()
    }
}
