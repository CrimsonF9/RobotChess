//
//  Game.swift
//  RobotChess.FC-and-CZ
//
//  Created by Fernando Castro on 4/12/23.
//

// Defines a struct for a move, which is equatable (can be compared for equality).
struct Move: Equatable {
    var from, to: Position
}
// Stores the from and to positions of a move.
enum GameState {
    // Represents the state where no player is in check and there are legal moves to make.
    case idle
    // Represents the state where a player is in check.
    case check
    // Represents the state where a player is in checkmate (i.e. there are no legal moves to make).
    case checkMate
    // Represents the state where the game is in stalemate (i.e. no player is in check, but there are no legal moves to make).
    case staleMate
}

// Defines a struct to represent a game.
struct Game {
    // Stores the game board (a `Board` struct).
    private(set) var board: Board
    // Stores the history of moves made in the game (an array of `Move` structs).
    private(set) var history: [Move]
}

// Adds some additional functionality to the `Game` struct.
extension Game {
    // Returns the current turn, based on the color of the last piece moved.
    var turn: Color {
        // Uses `flatMap` to get the last move in the history, if it exists.
        return history.last.flatMap {
            // Uses optional chaining to get the piece at the "to" position of the last move, then gets the opposite color of that piece (i.e. the color of the player who just moved).
            board.piece(at: $0.to)?.color.other
        } ?? .white
        // If there is no history, returns white as the first player to move.
    }
    // Determines the current state of the game (idle, check, checkmate, or stalemate).
    var state: GameState {
        // Gets the color of the current turn.
        let color = turn
        // Creates a copy of the current game board.
        let canMove = allMoves(for: color).contains(where: { move in
            var newBoard = self
            newBoard.board.movePiece(from: move.from, to: move.to)
            // Makes a move on the copy of the board.
            return !newBoard.kingIsInCheck(for: color)
        })
        // If the current player is not in check, returns either `idle` or `staleMate`, depending on whether the player can make any legal moves.
        if kingIsInCheck(for: color) {
            return canMove ? .check : .checkMate
        }
        return canMove ? .idle : .staleMate
    }
    // Initializes a new game.
    init() {
        // Creates a new game board.
        board = Board()
        // Initializes the move history to an empty array.
        history = []
    }

    // MARK: Game logic
    // Returns true if there is a piece at the given position that can be selected by the player whose turn it is.
    func canSelectPiece(at position: Position) -> Bool {
        return board.piece(at: position)?.color == turn
    }
    // Returns true if a piece can move from the given position by the given delta.
    
    func canMove(from: Position, by: Delta) -> Bool {
        return canMove(from: from, to: from + by)
    }
    // Returns true if a piece can move from the given position to the given position.
    
    func canMove(from: Position, to: Position) -> Bool {
        guard let this = board.piece(at: from) else {
            return false
        }
        let delta = to - from
        if let other = board.piece(at: to) {
            guard other.color != this.color else {
                return false
            }
            if this.type == .pawn {
                return pawnCanTake(from: from, with: delta)
            }
        }
        switch this.type {
        case .pawn:
            if enPassantTakePermitted(from: from, to: to) {
                return true
            }
            if delta.x != 0 {
                return false
            }
            switch this.color {
            case .white:
                if from.y == 6 {
                    return [-1, -2].contains(delta.y) &&
                        !board.piecesExist(between: from, and: to)
                }
                return delta.y == -1
            case .black:
                if from.y == 1 {
                    return [1, 2].contains(delta.y) &&
                        !board.piecesExist(between: from, and: to)
                }
                return delta.y == 1
            }
            // Returns true if a rook can move from the given position to the given position.
        case .rook:
            return (delta.x == 0 || delta.y == 0) &&
                !board.piecesExist(between: from, and: to)
            // Returns true if a bishop can move from the given position to the given position.
        case .bishop:
            return abs(delta.x) == abs(delta.y) &&
                !board.piecesExist(between: from, and: to)
            // Returns true if a queen can move from the given position to the given position.
        case .queen:
            return (delta.x == 0 || delta.y == 0 || abs(delta.x) == abs(delta.y)) &&
                !board.piecesExist(between: from, and: to)
            // Returns true if a king can move from the given position to the given position.
        case .king:
            if abs(delta.x) <= 1, abs(delta.y) <= 1 {
                return true
            }
            return castlingPermitted(from: from, to: to)
            // Returns true if a knight can move from the given position to the given position.
        case .knight:
            return [
                Delta(x: 1, y: 2),
                Delta(x: -1, y: 2),
                Delta(x: 2, y: 1),
                Delta(x: -2, y: 1),
                Delta(x: 1, y: -2),
                Delta(x: -1, y: -2),
                Delta(x: 2, y: -1),
                Delta(x: -2, y: -1),
            ].contains(delta)
        }
    }

    func pieceIsThreatened(at position: Position) -> Bool {
        return board.allPositions.contains(where: { canMove(from: $0, to: position) })
    }

    func positionIsThreatened(_ position: Position, by color: Color) -> Bool {
        return board.allPieces.contains(where: { from, piece in
            guard piece.color == color else {
                return false
            }
            if piece.type == .pawn {
                return pawnCanTake(from: from, with: position - from)
            }
            return canMove(from: from, to: position)
        })
    }

    func kingPosition(for color: Color) -> Position {
        board.firstPosition(where: {
           $0.type == .king && $0.color == color
        }) ?? .init(x: 0, y: 0)
    }

    func kingIsInCheck(for color: Color) -> Bool {
        pieceIsThreatened(at: kingPosition(for: color))
    }

    mutating func move(from: Position, to: Position) {
        assert(canMove(from: from, to: to))
        switch board.piece(at: from)?.type {
        case .pawn where enPassantTakePermitted(from: from, to: to):
            board.removePiece(at: Position(x: to.x, y: to.y - (to.y - from.y)))
        case .king where abs(to.x - from.x) > 1:
            let kingSide = (to.x == 6)
            let rookPosition = Position(x: kingSide ? 7 : 0, y: to.y)
            let rookDestination = Position(x: kingSide ? 5 : 3, y: to.y)
            board.movePiece(from: rookPosition, to: rookDestination)
        default:
            break
        }
        board.movePiece(from: from, to: to)
        history.append(Move(from: from, to: to))
    }

    func canPromotePiece(at position: Position) -> Bool {
        if let pawn = board.piece(at: position), pawn.type == .pawn,
            (pawn.color == .white && position.y == 0) ||
            (pawn.color == .black && position.y == 7) {
            return true
        }
        return false
    }

    mutating func promotePiece(at position: Position, to type: PieceType) {
        assert(canPromotePiece(at: position))
        board.promotePiece(at: position, to: type)
    }

    func movesForPiece(at position: Position) -> [Position] {
        return board.allPositions.filter { canMove(from: position, to: $0) }
    }

    // MARK: AI

    func nextMove(for color: Color) -> Move? {
        var bestMove: Move?
        var bestState: GameState?
        var bestScore = 0.0
        for move in allMoves(for: color).shuffled() {
            var newBoard = self
            newBoard.move(from: move.from, to: move.to)
            if newBoard.kingIsInCheck(for: color) {
                continue
            }
            var newScore = Double(board.piece(at: move.to)?.type.value ?? 0)
            if newBoard.canPromotePiece(at: move.to) {
                newBoard.promotePiece(at: move.to, to: .queen)
                newScore += 8
            }
            switch newBoard.state {
            case .checkMate:
                break
            case .staleMate:
                if bestMove != nil {
                    continue
                }
            case .check:
                if newBoard.pieceIsThreatened(at: move.to),
                    let piece = newBoard.board.piece(at: move.to) {
                    newScore -= Double(piece.type.value) * 0.9
                }
                switch bestState {
                case .check where newScore >= bestScore,
                     .idle where newScore >= bestScore,
                     .staleMate, nil:
                    break
                case .check, .checkMate, .idle:
                    continue
                }
            case .idle:
                var worstLossRisk = 0
                for (_, piece) in newBoard.allThreats(for: color) {
                    worstLossRisk = max(worstLossRisk, piece.type.value)
                }
                newScore -= Double(worstLossRisk) * 0.9
                switch bestState {
                case .idle where newScore > bestScore,
                     .check where newScore > bestScore,
                     .staleMate, nil:
                    break
                case .idle where newScore == bestScore && !newBoard.pieceIsThreatened(at: move.to):
                    guard let bestMove = bestMove, let piece = board.piece(at: move.from) else {
                        break
                    }
                    // Encourage castling
                    if piece.type == .king, abs(move.to.x - move.from.x) > 1 {
                        newScore += 0.5
                        break
                    }
                    // Discourage moving king or rook
                    if [.king, .rook].contains(piece.type) {
                        continue
                    }
                    // All other things being equal, try to get pawn to other side
                    if piece.type == .pawn, board.piece(at: bestMove.from)?.type != .pawn ||
                        (color == .black && move.to.y > bestMove.to.y) ||
                        (color == .white && move.to.y < bestMove.to.y) {
                        break
                    }
                    continue
                case .check, .checkMate, .idle:
                    continue
                }
            }
            if bestMove != nil, history.count > 1,
                history.dropLast().last == Move(from: move.to, to: move.from) {
                continue
            }
            bestMove = move
            bestState = newBoard.state
            bestScore = newScore
        }
        return bestMove
    }
}

private extension Game {
    func allMoves(for color: Color) ->
        LazySequence<FlattenSequence<LazyMapSequence<[Position], LazyFilterSequence<[Move]>>>> {
        return board.allPieces
            .compactMap { $1.color == color ? $0 : nil }
            .lazy.flatMap { self.allMoves(for: $0) }
    }

    func allMoves(for position: Position) -> LazyFilterSequence<[Move]> {
        return board.allPositions
            .map { Move(from: position, to: $0) }
            .lazy.filter { self.canMove(from: $0.from, to: $0.to) }
    }

    func allThreats(for color: Color) -> LazyFilterSequence<[(position: Position, piece: Piece)]> {
        return board.allPieces.lazy.filter { position, piece in
            return piece.color == color && self.pieceIsThreatened(at: position)
        }
    }

    func pawnCanTake(from: Position, with delta: Delta) -> Bool {
        guard abs(delta.x) == 1, let pawn = board.piece(at: from) else {
            return false
        }
        assert(pawn.type == .pawn)
        switch pawn.color {
        case .white:
            return delta.y == -1
        case .black:
            return delta.y == 1
        }
    }

    func enPassantTakePermitted(from: Position, to: Position) -> Bool {
        guard let this = board.piece(at: from),
            pawnCanTake(from: from, with: to - from),
            let lastMove = history.last, lastMove.to.x == to.x,
            let piece = board.piece(at: lastMove.to),
            piece.type == .pawn, piece.color != this.color
        else {
            return false
        }
        switch piece.color {
        case .white:
            return lastMove.from.y == to.y + 1 && lastMove.to.y == to.y - 1
        default:
            return lastMove.from.y == to.y - 1 && lastMove.to.y == to.y + 1
        }
    }

    func pieceHasMoved(at position: Position) -> Bool {
        return history.contains(where: { $0.from == position })
    }

    func castlingPermitted(from: Position, to: Position) -> Bool {
        guard let this = board.piece(at: from) else {
            return false
        }
        assert(this.type == .king)
        let kingsRow = this.color == .black ? 0 : 7
        guard from.y == kingsRow, to.y == kingsRow,
            from.x == 4, [2, 6].contains(to.x) else {
            return false
        }
        let kingPosition = Position(x: 4, y: kingsRow)
        if pieceHasMoved(at: kingPosition) {
            return false
        }
        let isKingSide = (to.x == 6)
        let rookPosition = Position(x: isKingSide ? 7 : 0, y: kingsRow)
        if pieceHasMoved(at: rookPosition) {
            return false
        }
        return !(isKingSide ? 5 ... 6 : 1 ... 3).contains(where: {
            board.piece(at: Position(x: $0, y: kingsRow)) != nil
        }) && !(isKingSide ? 4 ... 6 : 2 ... 4).contains(where: {
            positionIsThreatened(Position(x: $0, y: kingsRow), by: this.color.other)
        })
    }
}

private extension Board {
    func piecesExist(between: Position, and: Position) -> Bool {
        let step = Delta(
            x: between.x > and.x ? -1 : (between.x < and.x ? 1 : 0),
            y: between.y > and.y ? -1 : (between.y < and.y ? 1 : 0)
        )
        var position = between
        position += step
        while position != and {
            if piece(at: position) != nil {
                return true
            }
            position += step
        }
        return false
    }
}
