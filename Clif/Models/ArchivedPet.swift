import Foundation

struct ArchivedPet: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let archivedAt: Date
    let finalStreak: Int
    let totalDays: Int

    var isBlown: Bool { evolutionHistory.isBlown }
    var finalPhase: Int { evolutionHistory.currentPhase }
    var essence: Essence { evolutionHistory.essence }
    var isCompleted: Bool { finalPhase == evolutionHistory.maxPhase && !isBlown }

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        archivedAt: Date = Date(),
        finalStreak: Int,
        totalDays: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.archivedAt = archivedAt
        self.finalStreak = finalStreak
        self.totalDays = totalDays ?? Calendar.current.dateComponents(
            [.day],
            from: evolutionHistory.createdAt,
            to: archivedAt
        ).day ?? 0
    }
}

// MARK: - Mock Data

extension ArchivedPet {
    static func mock(
        name: String = "Fern",
        phase: Int = 4,
        isBlown: Bool = false,
        daysAgo: Int = 14,
        streak: Int = 12
    ) -> ArchivedPet {
        let calendar = Calendar.current
        let createdAt = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

        var events: [EvolutionEvent] = []
        if phase > 1 {
            for p in 2...phase {
                let offset = -daysAgo + (p * 3)
                let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                events.append(EvolutionEvent(fromPhase: p - 1, toPhase: p, date: date))
            }
        }

        let blownAt = isBlown ? calendar.date(byAdding: .day, value: -1, to: Date()) : nil

        return ArchivedPet(
            name: name,
            evolutionHistory: EvolutionHistory(
                createdAt: createdAt,
                essence: .plant,
                events: events,
                blownAt: blownAt
            ),
            purpose: "Social Media",
            finalStreak: streak
        )
    }

    static func mockList() -> [ArchivedPet] {
        [
            .mock(name: "Fern", phase: 4, isBlown: false, daysAgo: 28, streak: 21),
            .mock(name: "Ivy", phase: 4, isBlown: false, daysAgo: 45, streak: 18),
            .mock(name: "Moss", phase: 3, isBlown: false, daysAgo: 14, streak: 9),
            .mock(name: "Sprout", phase: 2, isBlown: true, daysAgo: 10, streak: 4),
            .mock(name: "Leaf", phase: 1, isBlown: true, daysAgo: 5, streak: 2)
        ]
    }
}
