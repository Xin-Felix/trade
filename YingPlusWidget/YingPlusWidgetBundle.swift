import WidgetKit
import SwiftUI

@main
struct YingPlusWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClockWidget()
        WeatherWidget()
    }
}
