import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func getShieldConfiguration() -> ShieldConfiguration {
        let windPoints = SharedDefaults.monitoredWindPoints

        let subtitleText: String
        if windPoints >= 100 {
            subtitleText = "Your pet was blown away!"
        } else {
            subtitleText = "Wind: \(Int(windPoints))% - Take a break to calm it"
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.white,
            icon: UIImage(systemName: "leaf.fill"),
            title: ShieldConfiguration.Label(text: "Clif", color: .black),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: .gray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Close App", color: .white),
            primaryButtonBackgroundColor: .systemGray,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Unlock", color: .systemBlue)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return getShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return getShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return getShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return getShieldConfiguration()
    }
}
