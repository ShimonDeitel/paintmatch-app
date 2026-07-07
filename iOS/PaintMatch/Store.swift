import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    @Published var items: [PaintMatchItem] = []
    @Published var isPro: Bool = false

    /// Free tier limit. Kept comfortably above seed count so a fresh install
    /// never immediately hits the paywall.
    static let freeLimit = 6

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("paintmatch_items.json")
        load()
    }

    var canAddMore: Bool {
        isPro || items.count < Store.freeLimit
    }

    func add(_ item: PaintMatchItem) {
        items.append(item)
        save()
    }

    func update(_ item: PaintMatchItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func delete(_ item: PaintMatchItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    private func seedIfNeeded() -> [PaintMatchItem] {
        [
            PaintMatchItem(name: "Living Room", detail: "Sherwin-Williams", extra: "SW 7005", date: Date()),
            PaintMatchItem(name: "Kitchen", detail: "Behr", extra: "PPU7-19", date: Date()),
            PaintMatchItem(name: "Bedroom", detail: "Benjamin Moore", extra: "OC-45", date: Date())
        ]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([PaintMatchItem].self, from: data) else {
            items = seedIfNeeded()
            save()
            return
        }
        items = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
