import Foundation

struct WeatherInfo: Identifiable {
    let id = UUID()
    let temperature: Double
    let description: String
    let city: String
    let updatedAt: Date
}
