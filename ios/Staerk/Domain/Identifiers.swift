import Foundation

enum StaerkID {
    static func make(_ prefix: String) -> String {
        "\(prefix)_\(UUID().uuidString.lowercased())"
    }
}
