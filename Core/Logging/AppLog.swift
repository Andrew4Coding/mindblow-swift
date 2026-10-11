import OSLog

nonisolated enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.absolutecinema.mindblow"

    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let haptics = Logger(subsystem: subsystem, category: "haptics")
    static let input = Logger(subsystem: subsystem, category: "input")
    static let storage = Logger(subsystem: subsystem, category: "storage")
}
