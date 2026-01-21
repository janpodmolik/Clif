import SwiftUI

struct DailyLimitConfigStep: View {
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
                    Text(MinutesFormatter.long(minutes))
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
        VStack(spacing: 4) {
            Text(MinutesFormatter.long(coordinator.dailyLimitMinutes))
                .font(.title.weight(.bold))
                .foregroundStyle(.blue)

            Text("per day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}

#if DEBUG
#Preview {
    DailyLimitConfigStep()
        .environment(CreatePetCoordinator())
}
#endif
