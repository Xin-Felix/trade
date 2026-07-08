import WidgetKit
import SwiftUI

struct WeatherEntry: TimelineEntry {
    let date: Date
    let temperature: Double
    let description: String
}

struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), temperature: 25, description: "晴天")
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        fetchWeather { entry in
            completion(entry ?? placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        fetchWeather { entry in
            let entries: [WeatherEntry]
            let policy: TimelineReloadPolicy
            if let entry = entry {
                entries = [entry]
                policy = .after(Date().addingTimeInterval(1800))
            } else {
                entries = [self.placeholder(in: context)]
                policy = .after(Date().addingTimeInterval(300))
            }
            completion(Timeline(entries: entries, policy: policy))
        }
    }

    private func fetchWeather(completion: @escaping (WeatherEntry?) -> Void) {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=39.9042&longitude=116.4074&current_weather=true")!
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current_weather"] as? [String: Any],
                  let temp = current["temperature"] as? Double,
                  let code = current["weathercode"] as? Int else {
                completion(nil)
                return
            }
            let entry = WeatherEntry(date: Date(), temperature: temp, description: weatherDescription(code: code))
            completion(entry)
        }
        task.resume()
    }
}

private func weatherDescription(code: Int) -> String {
    switch code {
    case 0: return "晴天"
    case 1, 2, 3: return "多云"
    case 45, 48: return "雾"
    case 51...55, 61...65, 80...82: return "下雨"
    case 71...77, 85...86: return "下雪"
    case 95...99: return "雷暴"
    default: return "未知"
    }
}

struct WeatherWidgetEntryView: View {
    var entry: WeatherProvider.Entry

    var body: some View {
        VStack(spacing: 4) {
            Text("北京")
                .font(.caption2)
            Text("\(Int(entry.temperature))°")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(entry.description)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.clear, for: .widget)
    }
}

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("天气")
        .description("显示当前天气")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
