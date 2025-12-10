import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    private func getShieldConfiguration() -> ShieldConfiguration {
        let progress = SharedDefaults.currentProgress
        let dailyLimit = SharedDefaults.dailyLimitMinutes
        let phase = ClifPhase.from(progress: progress)
        
        // Calculate remaining time
        let usedMinutes = (dailyLimit * progress) / 100
        let remainingMinutes = max(0, dailyLimit - usedMinutes)
        
        let subtitleText: String
        if remainingMinutes > 0 {
            subtitleText = "\(remainingMinutes) min remaining (\(progress)%)"
        } else {
            subtitleText = "Limit reached (\(progress)%)"
        }
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.white,
            icon: UIImage(named: phase.imageName),
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
