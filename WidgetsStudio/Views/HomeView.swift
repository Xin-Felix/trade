import SwiftUI

struct HomeView: View {
    @State private var weather: WeatherInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("加载天气中...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else if let weather = weather {
                    WeatherCard(weather: weather)
                }

                Button(action: { Task { await loadWeather() } }) {
                    Label("刷新天气", systemImage: "arrow.clockwise")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .navigationTitle("Widgets Studio")
            .task {
                await loadWeather()
            }
        }
    }

    private func loadWeather() async {
        isLoading = true
        errorMessage = nil
        do {
            weather = try await WeatherService.fetchBeijingWeather()
        } catch {
            errorMessage = "加载失败：\(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct WeatherCard: View {
    let weather: WeatherInfo

    var body: some View {
        VStack(spacing: 12) {
            Text(weather.city)
                .font(.headline)
            Text("\(Int(weather.temperature))°")
                .font(.system(size: 64, weight: .bold))
            Text(weather.description)
                .font(.title3)
            Text("更新于 \(weather.updatedAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    HomeView()
}
