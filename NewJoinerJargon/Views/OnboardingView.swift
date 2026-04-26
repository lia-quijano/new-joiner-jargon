import SwiftUI

struct OnboardingView: View {
    @Environment(GlossaryStore.self) private var store
    @Environment(SettingsManager.self) private var settings

    @State private var selectedPacks: Set<String> = []

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.blue)
                Text("New Joiner Jargon")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Pick your team")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("We'll pre-load the jargon you're most likely to encounter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(IndustryPack.all) { pack in
                    IndustryCard(pack: pack, isSelected: selectedPacks.contains(pack.id)) {
                        if selectedPacks.contains(pack.id) {
                            selectedPacks.remove(pack.id)
                        } else {
                            selectedPacks.insert(pack.id)
                        }
                    }
                }
            }

            Spacer()

            Divider()

            HStack {
                Button("Skip for now") {
                    settings.hasCompletedOnboarding = true
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Button {
                    let selected = IndustryPack.all.filter { selectedPacks.contains($0.id) }
                    if !selected.isEmpty {
                        store.seedIndustryPacks(selected)
                    }
                    settings.hasCompletedOnboarding = true
                } label: {
                    Label(
                        selectedPacks.isEmpty ? "Start empty" : "Populate my glossary",
                        systemImage: selectedPacks.isEmpty ? "arrow.right" : "sparkles"
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(width: 360)
    }
}

private struct IndustryCard: View {
    let pack: IndustryPack
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: pack.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : pack.color)
                Text(pack.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                Text("\(pack.terms.count) terms")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.75) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? pack.color : Color.secondary.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
