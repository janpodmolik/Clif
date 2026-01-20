import SwiftUI

struct DailyModeSelectionStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    private let minuteOptions = [15, 30, 45, 60, 90, 120, 150, 180, 240, 300, 360]

    var body: some View {
        @Bindable var coordinator = coordinator

        VStack(spacing: 8) {
            Text("Set your daily limit")
                .font(.title3.weight(.semibold))

            Text("How much time per day do you want to allow?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Picker("Daily Limit", selection: $coordinator.dailyLimitMinutes) {
                ForEach(minuteOptions, id: \.self) { minutes in
                    Text(formatMinutes(minutes))
                        .tag(minutes)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)

            limitDescription

            Spacer()
        }
        .padding(.top)
    }

    @ViewBuilder
    private var limitDescription: some View {
        let minutes = coordinator.dailyLimitMinutes

        VStack(spacing: 4) {
            Text(formatMinutes(minutes))
                .font(.title.weight(.bold))
                .foregroundStyle(.blue)

            Text("per day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

#if DEBUG
#Preview {
    DailyModeSelectionStep()
        .environment(CreatePetCoordinator())
}
#endif
