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
        // Check if this is Day Start Shield (first use of the day, before preset selected)
        logToFile("isDayStartShieldActive=\(SharedDefaults.isDayStartShieldActive)")
        if SharedDefaults.isDayStartShieldActive {
            logToFile("Returning DAY START shield config")
            return getDayStartShieldConfiguration()
        }

        // Regular shield during usage
        logToFile("Returning USAGE shield config")
        return getUsageShieldConfiguration()
    }

    private func getDayStartShieldConfiguration() -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: DayStartGreeting.iconName),
            title: ShieldConfiguration.Label(text: DayStartGreeting.text, color: .label),
            subtitle: ShieldConfiguration.Label(
                text: "Jak náročný den chceš mít?",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Otevřít Uuumi", color: .white),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: nil
        )
    }

    private func getUsageShieldConfiguration() -> ShieldConfiguration {
        let petName = SharedDefaults.monitoredPetName
        let subtitleText = petName.map { "Blokováno pro \($0)" } ?? "Blokováno"

        logToFile("getUsageShieldConfiguration() subtitle: \(subtitleText)")
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "wind"),
            title: ShieldConfiguration.Label(text: "Uuumi", color: .label),
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
