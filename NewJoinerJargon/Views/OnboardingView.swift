import SwiftUI

struct WelcomeView: View {
    @Environment(GlossaryStore.self) private var store
    @Environment(SettingsManager.self) private var settings

    @State private var step = 0
    @State private var selectedSectors: Set<String> = []
    @State private var selectedFunctions: Set<String> = []

    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if step < 2 {
                headerSection
                    .padding(.bottom, 24)
                gridSection
            } else {
                accessibilitySection
            }

            footerSection
                .padding(.top, 16)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(step == 0
                 ? "Which industry are you in?"
                 : "Which teams will you work closest with?")
                .font(.largeTitle.bold())
                .id("title-\(step)")
                .transition(.opacity)
            Text(step == 0
                 ? "Pick the sector that best describes the company or role you're joining. We'll pre-load the jargon you're most likely to encounter."
                 : "Select the functions you'll collaborate with most. You can always capture more terms as you go.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .id("subtitle-\(step)")
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    // MARK: - Grids (steps 0 & 1)

    @ViewBuilder
    private var gridSection: some View {
        ZStack {
            if step == 0 {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(IndustryPack.sectors) { pack in
                            WelcomePackCard(
                                pack: pack,
                                isSelected: selectedSectors.contains(pack.id)
                            ) {
                                if selectedSectors.contains(pack.id) {
                                    selectedSectors.remove(pack.id)
                                } else {
                                    selectedSectors.insert(pack.id)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(IndustryPack.functions) { pack in
                            WelcomePackCard(
                                pack: pack,
                                isSelected: selectedFunctions.contains(pack.id)
                            ) {
                                if selectedFunctions.contains(pack.id) {
                                    selectedFunctions.remove(pack.id)
                                } else {
                                    selectedFunctions.insert(pack.id)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .frame(maxHeight: .infinity)
        .clipped()
    }

    // MARK: - Accessibility step (step 2)

    private var accessibilitySection: some View {
        let alreadyGranted = AccessibilityService.hasPermission

        return VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: alreadyGranted ? "checkmark.circle.fill" : "keyboard")
                    .font(.system(size: 52))
                    .foregroundStyle(alreadyGranted ? .green : .secondary)

                VStack(spacing: 8) {
                    Text(alreadyGranted ? "You're all set" : "Allow Accessibility access")
                        .font(.title2.bold())

                    Text(alreadyGranted
                         ? "NJJ can already read highlighted text across all your apps. Press ⌃⌥J anywhere to capture a term."
                         : "NJJ uses macOS Accessibility to read the text you highlight — in Slack, Notion, your browser, anywhere. Without it, the ⌃⌥J hotkey can't capture your selection.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 400)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            Button("← Back") {
                withAnimation(.easeInOut(duration: 0.3)) { step -= 1 }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(step > 0 ? 1 : 0)
            .disabled(step == 0)

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(step == i ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut, value: step)
                }
            }

            Spacer()

            footerTrailing
        }
    }

    @ViewBuilder
    private var footerTrailing: some View {
        switch step {
        case 0:
            Button("Continue →") {
                withAnimation(.easeInOut(duration: 0.3)) { step = 1 }
            }
            .buttonStyle(.borderedProminent)
            .environment(\.controlActiveState, .key)

        case 1:
            HStack(spacing: 12) {
                if selectedTermCount > 0 {
                    Text("\(selectedTermCount) terms from \(selectedPackCount) \(selectedPackCount == 1 ? "pack" : "packs")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Continue →") {
                    withAnimation(.easeInOut(duration: 0.3)) { step = 2 }
                }
                .buttonStyle(.borderedProminent)
                .environment(\.controlActiveState, .key)
            }

        default:
            HStack(spacing: 12) {
                if !AccessibilityService.hasPermission {
                    Button("Skip") { seedAndFinish() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                Button {
                    if !AccessibilityService.hasPermission {
                        AccessibilityService.requestPermission()
                    }
                    seedAndFinish()
                } label: {
                    Text(AccessibilityService.hasPermission ? "Get started →" : "Open System Settings →")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .environment(\.controlActiveState, .key)
            }
        }
    }

    // MARK: - Helpers

    private func seedAndFinish() {
        let allSelected = IndustryPack.all.filter {
            selectedSectors.contains($0.id) || selectedFunctions.contains($0.id)
        }
        if !allSelected.isEmpty { store.seedIndustryPacks(allSelected) }
        settings.hasCompletedOnboarding = true
    }

    private var selectedTermCount: Int {
        IndustryPack.all
            .filter { selectedSectors.contains($0.id) || selectedFunctions.contains($0.id) }
            .reduce(0) { $0 + $1.terms.count }
    }

    private var selectedPackCount: Int {
        selectedSectors.count + selectedFunctions.count
    }
}

// MARK: - Pack Card

private struct WelcomePackCard: View {
    let pack: IndustryPack
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    private var sampleTerms: [String] {
        pack.terms
            .filter { $0.displayLabel != $0.term }
            .prefix(3)
            .map { $0.displayLabel }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    if let customIcon = pack.customIcon {
                        Image(customIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    } else {
                        Image(systemName: pack.icon)
                            .font(.title2)
                            .foregroundStyle(pack.color)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.body)
                        .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.3))
                }

                Text(pack.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(sampleTerms, id: \.self) { term in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(pack.color.opacity(0.5))
                                .frame(width: 4, height: 4)
                            Text(term)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Text("\(pack.terms.count) terms")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(isSelected ? 0.12 : (isHovered ? 0.1 : 0.06)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.primary.opacity(0.25) : Color.secondary.opacity(0.15),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) { isHovered = hovering }
        }
    }
}
