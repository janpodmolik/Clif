import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    private func getShieldConfiguration() -> ShieldConfiguration {
        let progress = SharedDefaults.currentProgress
        let phase = ClifPhase.from(progress: progress)
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.white,
            icon: UIImage(named: phase.imageName),
            title: ShieldConfiguration.Label(text: "Clif", color: .black),
            subtitle: ShieldConfiguration.Label(text: "\(phase.message) (\(progress)%)", color: .gray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Open Anyway", color: .white),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: nil
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
