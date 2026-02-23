import Foundation

public enum ChartSpecLoader {
    public static func load(from data: Data) throws -> ChartSpec {
        let decoder = JSONDecoder()
        return try decoder.decode(ChartSpec.self, from: data)
    }

    public static func load(from url: URL) throws -> ChartSpec {
        let data = try Data(contentsOf: url)
        return try load(from: data)
    }
}
