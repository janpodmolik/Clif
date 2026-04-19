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
            backgroundBlurStyle: .extraLight,
            backgroundColor: nil,
            icon: loadShieldPetImage(happy: true) ?? UIImage.Shields.dailyPreset,
            title: ShieldConfiguration.Label(text: DayStartGreeting.text, color: .black),
            subtitle: ShieldConfiguration.Label(
                text: "What kind of day do you want?",
                color: .darkGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Start your day", color: .white),
            primaryButtonBackgroundColor: .black,
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
            backgroundBlurStyle: .extraLight,
            backgroundColor: nil,
            icon: loadShieldPetImage(happy: false) ?? UIImage.Shields.break,
            title: ShieldConfiguration.Label(text: titleText, color: .black),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: .darkGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Unlock in Uuumi", color: .white),
            primaryButtonBackgroundColor: .black,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Close", color: .black)
        )
    }

    private func loadShieldPetImage(happy: Bool) -> UIImage? {
        let url = happy ? ShieldImagePaths.happyPetImageURL : ShieldImagePaths.neutralPetImageURL
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
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
