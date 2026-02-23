import Foundation

public enum ChartRuntimeError: Error, LocalizedError {
    case unsupportedPlatform(String)
    case invalidSpec(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedPlatform(let message):
            return message
        case .invalidSpec(let message):
            return message
        }
    }
}
