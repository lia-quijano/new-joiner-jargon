import SwiftUI

struct WelcomeView: View {
    @Environment(GlossaryStore.self) private var store
    @Environment(SettingsManager.self) private var settings

    @State private var selectedPacks: Set<String> = []

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome to New Joiner Jargon")
                        .font(.largeTitle.bold())
                    Text("Pick the teams you work closest with. We'll pre-load your glossary with the jargon you're most likely to encounter — you can always capture more as you go.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Industry grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(IndustryPack.all) { pack in
                        WelcomePackCard(
                            pack: pack,
                            isSelected: selectedPacks.contains(pack.id)
                        ) {
                            if selectedPacks.contains(pack.id) {
                                selectedPacks.remove(pack.id)
                            } else {
                                selectedPacks.insert(pack.id)
                            }
                        }
                    }
                }

                // Footer
                HStack(alignment: .center) {
                    Group {
                        if selectedPacks.isEmpty {
                            Text("Select the teams that match your role")
                        } else {
                            Text("\(selectedTermCount) terms from \(selectedPacks.count) \(selectedPacks.count == 1 ? "team" : "teams") selected")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button("Skip for now") {
                        settings.hasCompletedOnboarding = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                    Button {
                        let selected = IndustryPack.all.filter { selectedPacks.contains($0.id) }
                        if !selected.isEmpty {
                            store.seedIndustryPacks(selected)
                        }
                        settings.hasCompletedOnboarding = true
                    } label: {
                        Text(selectedPacks.isEmpty ? "Start with empty glossary" : "Populate my glossary →")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectedTermCount: Int {
        IndustryPack.all
            .filter { selectedPacks.contains($0.id) }
            .reduce(0) { $0 + $1.terms.count }
    }
}

private struct WelcomePackCard: View {
    let pack: IndustryPack
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    private var sampleTerms: [String] {
        Array(pack.terms.prefix(3).map { $0.term })
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: pack.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : pack.color)

                    Spacer()

                    Text("\(pack.terms.count) terms")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }

                Text(pack.name)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(sampleTerms, id: \.self) { term in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(isSelected ? Color.white.opacity(0.5) : pack.color.opacity(0.5))
                                .frame(width: 4, height: 4)
                            Text(term)
                                .font(.caption2)
                                .foregroundStyle(isSelected ? .white.opacity(0.75) : .secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                          ? AnyShapeStyle(pack.color)
                          : AnyShapeStyle(Color.secondary.opacity(isHovered ? 0.1 : 0.06)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) { isHovered = hovering }
        }
    }
}
