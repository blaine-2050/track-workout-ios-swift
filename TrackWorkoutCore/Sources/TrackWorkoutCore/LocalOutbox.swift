import Foundation

public struct OutboxItem: Codable, Hashable, Sendable {
    public let event: WorkoutEvent
    public let enqueuedAt: Date

    public init(event: WorkoutEvent, enqueuedAt: Date = Date()) {
        self.event = event
        self.enqueuedAt = enqueuedAt
    }
}

public struct LocalOutbox: Codable, Sendable {
    public private(set) var items: [OutboxItem]

    public init(items: [OutboxItem] = []) {
        self.items = items
    }

    public mutating func enqueue(_ event: WorkoutEvent) {
        items.append(OutboxItem(event: event))
    }

    public mutating func clearProcessed(ids: Set<UUID>) {
        items.removeAll(where: { ids.contains($0.event.id) })
    }
}
