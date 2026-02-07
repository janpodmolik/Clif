import Foundation

final class StarCanvasStar {
    var x: Double
    var y: Double
    let size: Double
    /// 0 = fast flashing, >0 = slower blooming with blur effect
    let flickerInterval: Double

    init(x: Double, y: Double, size: Double) {
        self.x = x
        self.y = y
        self.size = size

        // Larger stars in the upper third get a blooming effect
        if size > 2 && y < 300 {
            flickerInterval = Double.random(in: 3...20)
        } else {
            flickerInterval = 0
        }
    }
}
