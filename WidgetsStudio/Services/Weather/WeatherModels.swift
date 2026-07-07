import Foundation

struct WeatherResponse: Decodable {
    let currentWeather: CurrentWeather

    struct CurrentWeather: Decodable {
        let temperature: Double
        let weathercode: Int
    }
}
