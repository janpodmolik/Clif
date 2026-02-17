import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private var players: [SoundEffect: AVAudioPlayer] = [:]

    private init() {
        preload()
    }

    enum SoundEffect: String, CaseIterable {
        case coin = "coin"
        case evolve = "evolve"
        case evolveBurst = "evolve_burst"
        case archiveAscend = "archive_ascend"
        case archiveWoosh = "archive_woosh"

        var fileExtension: String { "m4a" }
    }

    func play(_ effect: SoundEffect) {
        players[effect]?.currentTime = 0
        players[effect]?.play()
    }

    func stop(_ effect: SoundEffect) {
        players[effect]?.stop()
    }

    private func preload() {
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: effect.fileExtension) else {
                #if DEBUG
                print("[SoundManager] Missing sound file: \(effect.rawValue).\(effect.fileExtension)")
                #endif
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[effect] = player
            } catch {
                #if DEBUG
                print("[SoundManager] Failed to load \(effect.rawValue): \(error)")
                #endif
            }
        }
    }
}
