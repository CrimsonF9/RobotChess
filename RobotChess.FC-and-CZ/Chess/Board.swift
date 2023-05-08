//
//  Board.swift
//  RobotChess.FC-and-CZ
//
//  Created by Fernando Castro on 4/7/23.
//
// This enumeration defines the different types of chess pieces, and assigns a numeric value to each type.
enum PieceType: String {
    case pawn
    case rook
    case knight
    case bishop
    case queen
    case king
 // This computed property returns the numeric value assigned to each piece type.
    var value: Int {
        switch self {
        case .pawn:
            return 1
        case .knight, .bishop:
            return 3
        case .rook:
            return 5
        case .queen:
            return 9
        case .king:
            return 0
        }
    }
}
// This enumeration defines the two possible colors of chess pieces: black and white.
enum Color: String {
    case white
    case black
// This computed property returns the opposite color of the current color.
    var other: Color {
        return self == .black ? .white : .black
    }
}
// This struct defines a chess piece, including its ID, type, and color.
struct Piece: Equatable, ExpressibleByStringLiteral {
    let id: String
    var type: PieceType
    let color: Color
// This initializer takes a string literal and extracts the color and type of the piece from the string.
    init(stringLiteral: String) {
        id = stringLiteral
        let chars = Array(stringLiteral)
        precondition(chars.count == 3)
        switch chars[0] {
        case "B": color = .black
        case "W": color = .white
        default:
            preconditionFailure()
        } // This struct defines a delta, which is the change in position of a chess piece.
        switch chars[1] {
        case "P": type = .pawn
        case "R": type = .rook
        case "N": type = .knight
        case "B": type = .bishop
        case "Q": type = .queen
        case "K": type = .king
        default:
            preconditionFailure()
        }
    }
}
// This struct defines a position on the chess board, using an x and y coordinate.
struct Delta: Hashable {
    var x, y: Int
}
// This function calculates the delta between two positions.
struct Position: Hashable {
    var x, y: Int
// This function adds a delta to a position to calculate a new position.
    static func - (lhs: Position, rhs: Position) -> Delta {
        return Delta(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func + (lhs: Position, rhs: Delta) -> Position {
        return Position(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    // This function updates a position by adding a delta to it.
    static func += (lhs: inout Position, rhs: Delta) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }
}
// This struct defines the chess board and the pieces currently on it.
struct Board: Equatable {
    private(set) var pieces: [[Piece?]]
}
// This extension defines some additional functionality for the Board struct.

    // This constant defines all of the positions on the chess board.
extension Board {
    static let allPositions = (0 ..< 8).flatMap { y in
        (0 ..< 8).map { Position(x: $0, y: y) }
    }
 // This computed property returns an array of all the positions on the board.
    var allPositions: [Position] { return Self.allPositions }

// All the pieces on the board with their positions.
    var allPieces: [(position: Position, piece: Piece)] {
        return allPositions.compactMap { position in
            pieces[position.y][position.x].map { (position, $0) }
        }
    }

 // Initialize the board with the starting position of the pieces.
    init() {
        pieces = [
            ["BR0", "BN1", "BB2", "BQ3", "BK4", "BB5", "BN6", "BR7"],
            ["BP0", "BP1", "BP2", "BP3", "BP4", "BP5", "BP6", "BP7"],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            ["WP0", "WP1", "WP2", "WP3", "WP4", "WP5", "WP6", "WP7"],
            ["WR0", "WN1", "WB2", "WQ3", "WK4", "WB5", "WN6", "WR7"],
        ]
    }

// Returns the piece at a given position, or nil if there is no piece there.
    func piece(at position: Position) -> Piece? {
        guard (0 ..< 8).contains(position.y), (0 ..< 8).contains(position.x) else {
            return nil
        }
        return pieces[position.y][position.x]
    }

// Returns the position of the first piece that satisfies a given condition.
    func firstPosition(where condition: (Piece) -> Bool) -> Position? {
        return allPieces.first(where: { condition($1) })?.position
    }
// Move a piece from one position to another.
    mutating func movePiece(from: Position, to: Position) {
        var pieces = self.pieces
        pieces[to.y][to.x] = piece(at: from)
        pieces[from.y][from.x] = nil
        self.pieces = pieces
    }

// Remove a piece from the board.
    mutating func removePiece(at position: Position) {
        var pieces = self.pieces
        pieces[position.y][position.x] = nil
        self.pieces = pieces
    }

// Promote a piece at a given position to a given piece type.
    mutating func promotePiece(at position: Position, to type: PieceType) {
        var piece = self.piece(at: position)
        piece?.type = type
        pieces[position.y][position.x] = piece
    }
}
