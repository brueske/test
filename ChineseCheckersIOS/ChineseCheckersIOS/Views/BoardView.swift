import SwiftUI

// MARK: - Layout helper

struct BoardLayout {
    let cellSize: CGFloat
    let origin: CGPoint

    init(size: CGSize) {
        let cellW = size.width / 13.0
        let cellH = size.height / 15.0
        cellSize = min(cellW, cellH)
        let boardW = 12.0 * cellSize
        let boardH = 16.0 * cellSize * sqrt(3.0) / 2.0
        origin = CGPoint(x: (size.width - boardW) / 2.0, y: (size.height - boardH) / 2.0)
    }

    func pt(_ pos: BoardPos) -> CGPoint {
        Board.screenPoint(pos: pos, cellSize: cellSize, origin: origin)
    }

    func nearest(to tap: CGPoint) -> BoardPos? {
        let threshold = cellSize * 0.65
        var best: BoardPos? = nil
        var bestDist = threshold
        for pos in Board.allPositions {
            let p = pt(pos)
            let d = hypot(tap.x - p.x, tap.y - p.y)
            if d < bestDist { bestDist = d; best = pos }
        }
        return best
    }
}

// MARK: - Board view

struct BoardView: View {
    let state: GameState
    let onTap: (BoardPos) -> Void

    @State private var canvasSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let layout = BoardLayout(size: size)
                renderBoard(ctx: ctx, layout: layout)
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { val in
                        let layout = BoardLayout(size: geo.size)
                        if let pos = layout.nearest(to: val.location) {
                            onTap(pos)
                        }
                    }
            )
        }
    }

    // MARK: Rendering

    private func renderBoard(ctx: GraphicsContext, layout: BoardLayout) {
        drawHomeTriangle(ctx: ctx, layout: layout,
                         a: .init(row: 0, col: 12), b: .init(row: 3, col: 9), c: .init(row: 3, col: 15),
                         fill: .home1)
        drawHomeTriangle(ctx: ctx, layout: layout,
                         a: .init(row: 13, col: 9), b: .init(row: 13, col: 15), c: .init(row: 16, col: 12),
                         fill: .home2)
        drawLines(ctx: ctx, layout: layout)
        drawHoles(ctx: ctx, layout: layout)
        drawPieces(ctx: ctx, layout: layout)
    }

    private func drawHomeTriangle(ctx: GraphicsContext, layout: BoardLayout,
                                  a: BoardPos, b: BoardPos, c: BoardPos, fill: Color) {
        var path = Path()
        path.move(to: layout.pt(a))
        path.addLine(to: layout.pt(b))
        path.addLine(to: layout.pt(c))
        path.closeSubpath()
        ctx.fill(path, with: .color(fill))
    }

    private func drawLines(ctx: GraphicsContext, layout: BoardLayout) {
        var path = Path()
        for pos in Board.allPositions {
            let src = layout.pt(pos)
            for n in Board.neighbors(of: pos)
            where n.row > pos.row || (n.row == pos.row && n.col > pos.col) {
                path.move(to: src)
                path.addLine(to: layout.pt(n))
            }
        }
        ctx.stroke(path, with: .color(.boardLine), lineWidth: layout.cellSize * 0.04)
    }

    private func drawHoles(ctx: GraphicsContext, layout: BoardLayout) {
        let r = layout.cellSize * 0.17
        for pos in Board.allPositions {
            guard state.pieces[pos] == nil else { continue }
            let c = layout.pt(pos)
            let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
            ctx.fill(Circle().path(in: rect), with: .color(.hole))
        }
    }

    private func drawPieces(ctx: GraphicsContext, layout: BoardLayout) {
        let r = layout.cellSize * 0.36

        for (pos, player) in state.pieces {
            let c = layout.pt(pos)
            let color = playerColor(player)
            let isSelected = pos == state.selectedPos || pos == state.jumpPos

            if isSelected {
                // Outer glow ring
                let gR = r * 1.45
                let glow = CGRect(x: c.x - gR, y: c.y - gR, width: gR * 2, height: gR * 2)
                ctx.fill(Circle().path(in: glow), with: .color(color.opacity(0.30)))
            }

            // Piece body
            let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
            ctx.fill(Circle().path(in: rect), with: .color(color))

            // Specular highlight
            let hR = r * 0.38
            let hOff = r * 0.28
            let hRect = CGRect(x: c.x - hR * 0.9, y: c.y - hOff - hR, width: hR * 1.8, height: hR * 1.4)
            ctx.fill(Ellipse().path(in: hRect), with: .color(.white.opacity(0.38)))
        }
    }
}
