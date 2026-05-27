import SwiftUI

extension Color {
    static let appBg      = Color(red: 0.97, green: 0.96, blue: 1.00)
    static let p1         = Color(red: 1.00, green: 0.42, blue: 0.42)   // coral
    static let p2         = Color(red: 0.31, green: 0.80, blue: 0.77)   // teal
    static let home1      = Color(red: 1.00, green: 0.91, blue: 0.91)   // pale coral
    static let home2      = Color(red: 0.88, green: 0.97, blue: 0.97)   // pale teal
    static let boardLine  = Color(red: 0.82, green: 0.79, blue: 0.90)
    static let hole       = Color(red: 0.90, green: 0.88, blue: 0.96)
    static let moveHint   = Color(red: 0.42, green: 0.39, blue: 1.00)   // vivid purple
    static let textMain   = Color(red: 0.15, green: 0.15, blue: 0.22)
}

func playerColor(_ player: Int) -> Color { player == 1 ? .p1 : .p2 }
func homeColor(_ player: Int) -> Color   { player == 1 ? .home1 : .home2 }
