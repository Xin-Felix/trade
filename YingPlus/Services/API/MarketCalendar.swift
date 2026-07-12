import Foundation

/// A 股市场时间工具：判断交易时段、交易日、最近/下一个交易日等
enum MarketCalendar {
    nonisolated static var timeZone: TimeZone { TimeZone(identifier: "Asia/Shanghai")! }

    /// 当前是否处于 A 股交易时段（工作日 09:30-11:30, 13:00-15:00）
    nonisolated static func isTradingTime(_ date: Date = Date()) -> Bool {
        guard isTradeDay(date) else { return false }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return false }
        let minutes = hour * 60 + minute

        let morningStart = 9 * 60 + 30   // 570
        let morningEnd   = 11 * 60 + 30  // 690
        let afternoonStart = 13 * 60     // 780
        let afternoonEnd   = 15 * 60     // 900

        return (minutes >= morningStart && minutes <= morningEnd)
            || (minutes >= afternoonStart && minutes <= afternoonEnd)
    }

    /// 是否为交易日（粗略：非周末；暂未处理法定节假日）
    nonisolated static func isTradeDay(_ date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let weekday = calendar.component(.weekday, from: date)
        return weekday != 1 && weekday != 7
    }

    /// 最近的交易日（向前找，含当天）
    nonisolated static func latestTradeDate(_ date: Date = Date()) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var d = date
        while !isTradeDay(d) {
            d = calendar.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return d
    }

    /// 下一个交易日开盘时间（用于盘后缓存失效点）
    nonisolated static func nextTradingDayOpenTime(_ date: Date = Date()) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var d = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        while !isTradeDay(d) {
            d = calendar.date(byAdding: .day, value: 1, to: d) ?? d
        }
        var components = calendar.dateComponents([.year, .month, .day], from: d)
        components.hour = 9
        components.minute = 30
        components.second = 0
        return calendar.date(from: components) ?? d
    }

    /// 最近一次收盘时间
    nonisolated static func latestCloseTime(_ date: Date = Date()) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let tradeDate = latestTradeDate(date)
        var components = calendar.dateComponents([.year, .month, .day], from: tradeDate)
        components.hour = 15
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? tradeDate
    }

    /// 格式化日期为 "yyyyMMdd"
    nonisolated static func formatTradeDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}
