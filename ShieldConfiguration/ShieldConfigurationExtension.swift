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
        let subtitleText = SharedDefaults.notificationsAuthorized
            ? "What kind of day do you want?"
            : "Notifications are off — open Uuumi from your Home Screen to pick a preset."

        return ShieldConfiguration(
            backgroundBlurStyle: .extraLight,
            backgroundColor: nil,
            icon: loadShieldPetImage(happy: true) ?? UIImage.Shields.dailyPreset,
            title: ShieldConfiguration.Label(text: DayStartGreeting.text, color: .black),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
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

        // The Unlock flow works via a local notification — when notifications are
        // denied, tapping Unlock would silently do nothing, so instruct manual open.
        let subtitleText: String
        if !SharedDefaults.notificationsAuthorized {
            subtitleText = "Notifications are off — open Uuumi from your Home Screen to unlock."
        } else {
            switch breakType {
            case .committed:
                subtitleText = "Tap Unlock to open Uuumi and manage your break."
            case .safety:
                subtitleText = "Tap Unlock to open Uuumi and check if it's safe."
            default:
                subtitleText = "Tap Unlock to open Uuumi and end your break."
            }
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .extraLight,
            backgroundColor: nil,
            icon: loadShieldPetImage(happy: false) ?? UIImage.Shields.break,
            title: ShieldConfiguration.Label(text: titleText, color: .black),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: .darkGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Unlock", color: .white),
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
