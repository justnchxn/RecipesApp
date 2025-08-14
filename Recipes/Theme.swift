import SwiftUI

// Themes

struct AppTheme: Equatable {
    let name: String
    let bgTop: Color
    let bgBottom: Color
    let card: Color
    let text: Color
    let subtext: Color
    let accent: Color
    let chipStroke: Color
    let chipFill: Color
}

enum ThemeKind: String, CaseIterable, Identifiable {
    case citrus, matcha, neon
    case sunset, ocean
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .citrus: return "Citrus Pop"
        case .matcha: return "Matcha Minimal"
        case .neon:   return "Night Market"
        case .sunset: return "Sunset Sorbet"
        case .ocean:  return "Ocean Breeze"
        }
    }
    var emoji: String {
        switch self {
        case .citrus: return "🍋"
        case .matcha: return "🍵"
        case .neon:   return "🌃"
        case .sunset: return "🌅"
        case .ocean:  return "🌊"
        }
    }
    var colorScheme: ColorScheme {
        switch self {
        case .neon: return .dark
        default:    return .light
        }
    }
    var theme: AppTheme {
        switch self {
        case .citrus:
            return AppTheme(
                name: "Citrus Pop",
                bgTop: Color(hex:"#F9D923"), bgBottom: Color(hex:"#2CD9C5"),
                card: Color.white.opacity(0.92),
                text: .black.opacity(0.92), subtext: .black.opacity(0.55),
                accent: Color(hex:"#FF7A00"),
                chipStroke: Color(hex:"#5B8CFF"),
                chipFill: Color(hex:"#F9D923").opacity(0.2)
            )
        case .matcha:
            return AppTheme(
                name: "Matcha Minimal",
                bgTop: Color(hex:"#FFF8EC"), bgBottom: Color(hex:"#EAF6EF"),
                card: .white,
                text: Color(hex:"#1F2937"), subtext: Color(hex:"#1F2937").opacity(0.6),
                accent: Color(hex:"#A3D9A5"),
                chipStroke: Color(hex:"#A3D9A5"),
                chipFill: .clear
            )
        case .neon:
            return AppTheme(
                name: "Night Market Neon",
                bgTop: Color(hex:"#1B0E1E"), bgBottom: Color(hex:"#3D2C8D"),
                card: Color.white.opacity(0.06),
                text: Color(hex:"#FDFDFE"), subtext: .white.opacity(0.7),
                accent: Color(hex:"#FF4D80"),
                chipStroke: Color(hex:"#00E5FF"),
                chipFill: Color(hex:"#B9FF66")
            )
        case .sunset:
            return AppTheme(
                name: "Sunset Sorbet",
                bgTop: Color(hex:"#FF9E80"),
                bgBottom: Color(hex:"#FF7EB3"),
                card: Color.white.opacity(0.94),
                text: .black.opacity(0.92),
                subtext: .black.opacity(0.55),
                accent: Color(hex:"#FF5C93"),
                chipStroke: Color(hex:"#7A77FF"),
                chipFill: Color(hex:"#FFD1A7").opacity(0.25)
            )
        case .ocean:
            return AppTheme(
                name: "Ocean Breeze",
                bgTop: Color(hex:"#7BC6FF"),
                bgBottom: Color(hex:"#5FE1D4"),
                card: .white,
                text: Color(hex:"#0B2239"),
                subtext: Color(hex:"#0B2239").opacity(0.6),
                accent: Color(hex:"#0FA3B1"),
                chipStroke: Color(hex:"#1F4FD8"),
                chipFill: Color(hex:"#E0F7FA")
            )
        }
    }
}

// Theme manager

final class ThemeManager: ObservableObject {
    @AppStorage("theme.kind") private var storedKind: String = ThemeKind.citrus.rawValue
    @Published var kind: ThemeKind = .citrus {
        didSet { storedKind = kind.rawValue }
    }
    var theme: AppTheme { kind.theme }
    init() { kind = ThemeKind(rawValue: storedKind) ?? .citrus }
}

// Helpers

struct ThemedBackground: ViewModifier {
    let t: AppTheme
    func body(content: Content) -> some View {
        LinearGradient(colors: [t.bgTop, t.bgBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            .overlay(content)
    }
}

extension View {
    func themedBackground(_ t: AppTheme) -> some View { modifier(ThemedBackground(t: t)) }
    func listUsesTheme(_ t: AppTheme) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .tint(t.accent)
    }
}

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        let v = UInt64(h, radix: 16) ?? 0
        self = Color(
            red:   Double((v >> 16) & 0xFF)/255,
            green: Double((v >> 8)  & 0xFF)/255,
            blue:  Double(v & 0xFF)/255
        )
    }
}

struct QtyChip: View {
    let n: Int
    let t: AppTheme
    var body: some View {
        Text("x\(n)")
            .font(.caption2).bold().monospacedDigit()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(t.chipFill, in: Capsule())
            .overlay(Capsule().stroke(t.chipStroke.opacity(0.85), lineWidth: t.chipFill == .clear ? 1 : 0.8))
    }
}
