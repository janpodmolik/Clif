import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func getShieldConfiguration() -> ShieldConfiguration {
        if SharedDefaults.isDayStartShieldActive {
            return getDayStartShieldConfiguration()
        }
        return getUsageShieldConfiguration()
    }

    private func getDayStartShieldConfiguration() -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .prominent,
            backgroundColor: .systemBlue,
            icon: UIImage.Shields.dailyPreset,
            title: ShieldConfiguration.Label(text: DayStartGreeting.text, color: .label),
            subtitle: ShieldConfiguration.Label(
                text: "What kind of day do you want?",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Start your day", color: .black),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil
        )
    }

    private func getUsageShieldConfiguration() -> ShieldConfiguration {
        let petName = SharedDefaults.monitoredPetName
        let titleText = petName.map { "Blocked for \($0)" } ?? "Blocked"
        let breakType = SharedDefaults.activeBreakType

        let subtitleText: String
        switch breakType {
        case .committed:
            subtitleText = "Check how much time is left in Uuumi."
        case .safety:
            subtitleText = "Check if it's safe to unlock in Uuumi."
        default:
            subtitleText = "You can safely end your break in Uuumi."
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .prominent,
            backgroundColor: .systemBlue,
            icon: UIImage.Shields.break,
            title: ShieldConfiguration.Label(text: titleText, color: .label),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Close", color: .white),
            primaryButtonBackgroundColor: .systemGray,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Unlock in Uuumi", color: .systemBlue)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        getShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        getShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        getShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        getShieldConfiguration()
    }
}
