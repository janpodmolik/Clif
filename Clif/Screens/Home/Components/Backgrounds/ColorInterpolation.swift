import SwiftUI

extension Color {
    func getComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let uiColor = UIColor(self)
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }

    func interpolated(to other: Color, amount: Double) -> Color {
        let from = self.getComponents()
        let to = other.getComponents()

        let r = (1 - amount) * from.red + amount * to.red
        let g = (1 - amount) * from.green + amount * to.green
        let b = (1 - amount) * from.blue + amount * to.blue
        let a = (1 - amount) * from.alpha + amount * to.alpha

        return Color(.displayP3, red: r, green: g, blue: b, opacity: a)
    }
}

extension Array where Element == Gradient.Stop {
    func interpolated(amount: Double) -> Color {
        guard let initialStop = self.first else {
            fatalError("Attempted to read color from empty stop array.")
        }

        var firstStop = initialStop
        var secondStop = initialStop

        for stop in self {
            if stop.location < amount {
                firstStop = stop
            } else {
                secondStop = stop
                break
            }
        }

        let totalDifference = secondStop.location - firstStop.location

        if totalDifference > 0 {
            let relativeDifference = (amount - firstStop.location) / totalDifference
            return firstStop.color.interpolated(to: secondStop.color, amount: relativeDifference)
        } else {
            return firstStop.color.interpolated(to: secondStop.color, amount: 0)
        }
    }
}
