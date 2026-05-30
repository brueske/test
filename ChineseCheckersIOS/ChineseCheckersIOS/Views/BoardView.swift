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
    var animatingMove: AnimatingMove? = nil
    let onTap: (BoardPos) -> Void

    @State private var animProgress: Double = 1.0

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
                        if let pos = layout.nearest(to: val.location) { onTap(pos) }
                    }
            )
        }
        .onChange(of: animatingMove) { _, newMove in
            guard newMove != nil else { return }
            animProgress = 0.0
            withAnimation(.easeOut(duration: 0.25)) { animProgress = 1.0 }
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
            var drawPt = layout.pt(pos)

            // Interpolate position during animation
            if let anim = animatingMove, pos == anim.to, animProgress < 1.0 {
                let fromPt = layout.pt(anim.from)
                let toPt   = layout.pt(anim.to)
                let t = animProgress
                drawPt = CGPoint(
                    x: fromPt.x + (toPt.x - fromPt.x) * t,
                    y: fromPt.y + (toPt.y - fromPt.y) * t
                )
            }

            let color      = playerColor(player)
            let isSelected = pos == state.selectedPos || pos == state.jumpPos

            if isSelected {
                let gR   = r * 1.45
                let glow = CGRect(x: drawPt.x - gR, y: drawPt.y - gR, width: gR * 2, height: gR * 2)
                ctx.fill(Circle().path(in: glow), with: .color(color.opacity(0.30)))
            }

            let rect = CGRect(x: drawPt.x - r, y: drawPt.y - r, width: r * 2, height: r * 2)
            ctx.fill(Circle().path(in: rect), with: .color(color))

            let hR    = r * 0.38
            let hOff  = r * 0.28
            let hRect = CGRect(x: drawPt.x - hR * 0.9, y: drawPt.y - hOff - hR, width: hR * 1.8, height: hR * 1.4)
            ctx.fill(Ellipse().path(in: hRect), with: .color(.white.opacity(0.38)))
        }
    }
}
