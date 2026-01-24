import Foundation

/// Shared logger for extensions that can't use print() to console.
/// Logs to a shared file in the App Group container.
enum ExtensionLogger {

    private static let logFileName = "extension_log.txt"

    /// Logs a message to the shared extension log file.
    /// - Parameters:
    ///   - message: The message to log
    ///   - prefix: Optional prefix to identify the source (e.g., "[ShieldAction]")
    static func log(_ message: String, prefix: String = "") {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else { return }

        let logURL = containerURL.appendingPathComponent(logFileName)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let formattedPrefix = prefix.isEmpty ? "" : " \(prefix)"
        let line = "[\(timestamp)]\(formattedPrefix) \(message)\n"

        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logURL)
        }
    }
}
