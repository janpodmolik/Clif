import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    /// Static initializer to log when extension loads
    override init() {
        super.init()
        logToFile("ShieldConfigurationExtension INIT")
    }

    private func logToFile(_ message: String) {
        ExtensionLogger.log(message, prefix: "[ShieldConfig]")
    }

    private func getShieldConfiguration() -> ShieldConfiguration {
        logToFile("getShieldConfiguration() called")
        // Check if this is Morning Shield
        logToFile("isMorningShieldActive=\(SharedDefaults.isMorningShieldActive)")
        if SharedDefaults.isMorningShieldActive {
            logToFile("Returning MORNING shield config")
            return getMorningShieldConfiguration()
        }

        // Regular shield during usage
        logToFile("Returning USAGE shield config")
        return getUsageShieldConfiguration()
    }

    private func getMorningShieldConfiguration() -> ShieldConfiguration {
        // Get current/yesterday's preset name
        let presetName: String
        if let savedPreset = SharedDefaults.todaySelectedPreset {
            presetName = savedPreset.capitalized
        } else {
            presetName = "Balanced" // Default
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "sun.horizon.fill"),
            title: ShieldConfiguration.Label(text: "Dobré ráno!", color: .label),
            subtitle: ShieldConfiguration.Label(
                text: "Jak náročný den chceš mít? Aktuálně: \(presetName)",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Otevřít Clif", color: .white),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Pokračovat s \(presetName)",
                color: .systemBlue
            )
        )
    }

    private func getUsageShieldConfiguration() -> ShieldConfiguration {
        logToFile("getUsageShieldConfiguration() START")
        let windPoints = SharedDefaults.monitoredWindPoints
        logToFile("windPoints=\(windPoints)")
        let windLevel = WindLevel.from(windPoints: windPoints)
        logToFile("windLevel=\(windLevel.rawValue) (\(windLevel.label))")

        let subtitleText: String
        let iconName: String
        let backgroundColor: UIColor

        if windPoints >= 100 {
            subtitleText = "Tvůj mazlíček byl odfouknut!"
            iconName = "wind"
            backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        } else {
            subtitleText = "Vítr: \(Int(windPoints))% (\(windLevel.label)) - Dej si pauzu"
            iconName = windLevel == .none ? "sun.max.fill" : "wind"
            backgroundColor = UIColor.systemBackground
        }

        logToFile("getUsageShieldConfiguration() returning config with subtitle: \(subtitleText)")
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: backgroundColor,
            icon: UIImage(systemName: iconName),
            title: ShieldConfiguration.Label(text: "Clif", color: .label),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Zavřít app", color: .white),
            primaryButtonBackgroundColor: .systemGray,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Odemknout", color: .systemBlue)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        logToFile("configuration(shielding application:) called")
        return getShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        logToFile("configuration(shielding application:in category:) called")
        return getShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        logToFile("configuration(shielding webDomain:) called")
        return getShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        logToFile("configuration(shielding webDomain:in category:) called")
        return getShieldConfiguration()
    }
}
