import Foundation

/// 启动屏预加载完成后的首页数据包
struct PreloadedHomeData {
    let domesticIndices: [IndexItem]
    let globalIndices: [IndexItem]
    let watchlist: [StockData]
    let hotSectors: [SectorMoneyflowData]
    let dailyQuote: DailyQuoteData?
}

/// 启动屏完成后的整体结果
struct SplashResult {
    let preloadedHomeData: PreloadedHomeData
    let autoLoginError: String?
}
