import Foundation
import CoreGraphics

final class StarCanvasField {
    var stars: [StarCanvasStar] = []
    private var lastUpdate = Date.now
    private var generatedForSize: CGSize = .zero

    func ensureStars(in size: CGSize, count: Int = 60) {
        guard size != generatedForSize else { return }
        generatedForSize = size
        stars = (0..<count).map { _ in
            StarCanvasStar(
                x: Double.random(in: -50...size.width),
                y: Double.random(in: 0...size.height),
                size: Double.random(in: 1...3)
            )
        }
        lastUpdate = .now
    }

    func update(date: Date) {
        let delta = min(date.timeIntervalSince1970 - lastUpdate.timeIntervalSince1970, 1.0)
        let width = generatedForSize.width

        for star in stars {
            star.x -= delta * 1
            if star.x < -50 {
                star.x = width
            }
        }
        lastUpdate = date
    }
}
