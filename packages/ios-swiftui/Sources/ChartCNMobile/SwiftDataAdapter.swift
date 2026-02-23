import Foundation

#if canImport(SwiftData)
import SwiftData

public protocol ChartSwiftDataMappable {
    func toChartRow() -> ChartRow
}

public struct SwiftDataFetchConfiguration<Entity: PersistentModel & ChartSwiftDataMappable> {
    public let predicate: Predicate<Entity>?
    public let sortDescriptors: [SortDescriptor<Entity>]
    public let limit: Int?

    public init(
        predicate: Predicate<Entity>? = nil,
        sortDescriptors: [SortDescriptor<Entity>] = [],
        limit: Int? = nil
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.limit = limit
    }
}

public final class SwiftDataAdapter {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func fetchRows<Entity>(
        _ config: SwiftDataFetchConfiguration<Entity>
    ) throws -> [ChartRow] where Entity: PersistentModel & ChartSwiftDataMappable {
        var descriptor = FetchDescriptor<Entity>(
            predicate: config.predicate,
            sortBy: config.sortDescriptors
        )

        if let limit = config.limit {
            descriptor.fetchLimit = max(0, limit)
        }

        let entities = try context.fetch(descriptor)
        return entities.map { $0.toChartRow() }
    }
}

#else

public protocol ChartSwiftDataMappable {
    func toChartRow() -> ChartRow
}

public final class SwiftDataAdapter {
    public init() {}

    public func fetchRows<Entity>(_ config: Any) throws -> [ChartRow] {
        throw ChartRuntimeError.unsupportedPlatform(
            "SwiftDataAdapter requires SwiftData and iOS 17+."
        )
    }
}

#endif
