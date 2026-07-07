import Foundation

enum WeatherService {
    static func fetchBeijingWeather() async throws -> WeatherInfo {
        let response: WeatherResponse = try await NetworkService.shared.request(
            "https://api.open-meteo.com/v1/forecast?latitude=39.9042&longitude=116.4074&current_weather=true"
        )

        return WeatherInfo(
            temperature: response.currentWeather.temperature,
            description: weatherDescription(code: response.currentWeather.weathercode),
            city: "北京",
            updatedAt: Date()
        )
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
