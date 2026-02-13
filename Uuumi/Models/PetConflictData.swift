import Foundation

/// Data for the pet conflict resolution sheet.
/// Holds info about both local and cloud pets for display + resolution.
struct PetConflictData: Identifiable {
    let id = UUID()

    // MARK: - Local Pet Info

    let localPetName: String
    let localPetPhase: Int
    let localPetEssence: Essence?
    let localPetDaysAlive: Int
    let localPetIsBlown: Bool

    // MARK: - Cloud Pet Info

    let cloudDTO: ActivePetSupabaseDTO
    let cloudPetName: String
    let cloudPetPhase: Int
    let cloudPetEssence: Essence?
    let cloudPetDaysAlive: Int
    let cloudPetIsBlown: Bool

    // MARK: - Cloud Archived Pets

    let cloudArchivedDTOs: [ArchivedPetSupabaseDTO]

    init(localPet: Pet, cloudDTO: ActivePetSupabaseDTO, cloudArchivedDTOs: [ArchivedPetSupabaseDTO]) {
        self.localPetName = localPet.name
        self.localPetPhase = localPet.currentPhase
        self.localPetEssence = localPet.essence
        self.localPetDaysAlive = localPet.totalDays
        self.localPetIsBlown = localPet.isBlown

        self.cloudDTO = cloudDTO
        self.cloudPetName = cloudDTO.name
        self.cloudPetPhase = cloudDTO.evolutionHistory.currentPhase
        self.cloudPetEssence = cloudDTO.evolutionHistory.essence
        // Cloud pet doesn't have daysSinceCreation computed — derive from createdAt (calendar days)
        let calendar = Calendar.current
        let created = calendar.startOfDay(for: cloudDTO.evolutionHistory.createdAt)
        let today = calendar.startOfDay(for: Date())
        let daysFromCreation = calendar.dateComponents([.day], from: created, to: today).day ?? 0
        self.cloudPetDaysAlive = daysFromCreation + 1
        self.cloudPetIsBlown = cloudDTO.isBlownAway

        self.cloudArchivedDTOs = cloudArchivedDTOs
    }
}

#if DEBUG
extension PetConflictData {
    /// Preview-only init with raw values (no DTO dependency).
    static var preview: PetConflictData {
        let localPet = Pet.mock(name: "Fern", phase: 2, essence: .plant, totalDays: 7)
        let cloudDTO = ActivePetSupabaseDTO(
            from: PetDTO(from: Pet.mock(name: "Sprout", phase: 3, essence: .plant, totalDays: 14)),
            userId: UUID(),
            windPoints: 30,
            isBlownAway: false,
            hourlyAggregate: nil,
            hourlyPerDay: []
        )
        return PetConflictData(localPet: localPet, cloudDTO: cloudDTO, cloudArchivedDTOs: [])
    }
}
#endif
