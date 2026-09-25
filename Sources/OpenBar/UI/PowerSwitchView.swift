import SwiftUI

/// OPEN BAR's master switch: a large power button that glows while the app
/// is tidying the menu bar and goes dark when it is switched off.
struct PowerSwitchView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var hover = OpenBarHoverState()
    @StateObject private var breath = BreathingState()

    private let diameter: CGFloat = 112
    private var isOn: Bool { model.isEnabled }

    var body: some View {
        VStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    model.setEnabled(!isOn)
                }
            } label: {
                ZStack {
                    // Soft halo that breathes while switched on.
                    Circle()
                        .fill(OpenBarTheme.accent.opacity(isOn ? 0.22 : 0))
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(isOn && breath.isExpanded ? 1.34 : 1.12)
                        .blur(radius: 14)

                    Circle()
                        .fill(isOn ? AnyShapeStyle(onGradient) : AnyShapeStyle(OpenBarTheme.control))
                        .overlay {
                            Circle().stroke(
                                isOn ? Color.white.opacity(0.38) : Color.primary.opacity(0.12),
                                lineWidth: 1
                            )
                        }
                        .shadow(color: OpenBarTheme.accent.opacity(isOn ? 0.75 : 0), radius: 18)
                        .shadow(color: OpenBarTheme.accent.opacity(isOn ? 0.4 : 0), radius: 40)
                        .frame(width: diameter, height: diameter)

                    Image(systemName: "power")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(isOn ? Color.white : OpenBarTheme.muted)
                        .shadow(color: .white.opacity(isOn ? 0.6 : 0), radius: 6)
                }
                .frame(width: diameter + 40, height: diameter + 40)
                .scaleEffect(hover.isHovered ? 1.04 : 1)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) { hover.isHovered = hovering }
            }
            .accessibilityLabel(L("OPEN BAR master switch"))
            .accessibilityValue(isOn ? L("On") : L("Off"))
            .help(isOn ? L("Click to turn off") : L("Click to turn on"))

            VStack(spacing: 4) {
                Text(isOn ? L("OPEN BAR is on") : L("OPEN BAR is off"))
                    .font(.system(size: 15, weight: .semibold))
                Text(isOn ? L("Tucking icons away") : L("All icons are showing"))
                    .font(.system(size: 11))
                    .foregroundStyle(OpenBarTheme.muted)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breath.isExpanded = true
            }
        }
    }

    private var onGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#7DB4FF"), OpenBarTheme.accent, Color(hex: "#3F72E6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private final class BreathingState: ObservableObject {
    @Published var isExpanded = false
}
