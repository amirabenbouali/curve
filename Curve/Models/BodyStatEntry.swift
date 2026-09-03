import Foundation
import SwiftData

@Model
final class BodyStatEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var weight: Double?
    var bodyFatPercentage: Double?
    var notes: String = ""

    init(date: Date = Date(), weight: Double? = nil, bodyFatPercentage: Double? = nil, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.weight = weight
        self.bodyFatPercentage = bodyFatPercentage
        self.notes = notes
    }
}
