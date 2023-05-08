//
//  BoardView.swift
//  RobotChess.FC-and-CZ
//
//  Created by Fernando Castro on 4/16/23.
//

import UIKit
// Define an extension to the Piece class.
private extension Piece {
 // Compute the image name for a Piece object.
    var imageName: String {
        return "\(type.rawValue)_\(color.rawValue)"
    }
}
// Declare a BoardViewDelegate protocol.
protocol BoardViewDelegate: AnyObject {
    func boardView(_ boardView: BoardView, didTap position: Position)
}
 // Define a method that will be called when a board square is tapped.

// Declare a BoardView class.
class BoardView: UIView {
 // Declare a weak delegate variable of type BoardViewDelegate.
    weak var delegate: BoardViewDelegate?

// Declare arrays to keep track of the squares, pieces, and move indicators on the board.
    private(set) var squares: [UIImageView] = []
    private(set) var pieces: [String: UIImageView] = [:]
    private(set) var moveIndicators: [UIView] = []

// Declare a board variable of type Board, and update the pieces on the board whenever the board variable is set.
    var board = Board() {
        didSet { updatePieces() }
    }

// Declare a selection variable of type Position, and update the selected piece whenever the selection variable is set.
    var selection: Position? {
        didSet { updateSelection() }
    }

    // Declare a moves variable of type [Position], and update the move indicators whenever the moves variable is set.
    var moves: [Position] = [] {
        didSet { updateMoveIndicators() }
    }
// Define a function to jiggle a piece at a given position.
    func jigglePiece(at position: Position) {
        if let piece = board.piece(at: position) {
            pieces[piece.id]?.jiggle()
        }
    }
// Define a function to pulse a piece at a given position.
    func pulsePiece(at position: Position, completion: (() -> Void)?) {
        if let piece = board.piece(at: position) {
            pieces[piece.id]?.pulse(completion: completion)
        }
    }
// Define an initializer for the BoardView class.
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedSetup()
    }
// Define an initializer for the BoardView class.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedSetup()
    }
// Define a function to set up the board view.
    private func sharedSetup() {
// Create an image view for each square on the board, and add it to the view hierarchy.

        for i in 0 ..< 8 {
            for j in 0 ..< 8 {
                let white = i % 2 == j % 2
                let image = UIImage(named: white ? "square_white": "square_black")
                let view = UIImageView(image: image)
                squares.append(view)
                addSubview(view)
            }
        }
// Create an image view for each piece on the board, and add it to the view hierarchy.
        for row in board.pieces {
            for piece in row {
                guard let piece = piece else {
                    continue
                }
                let view = UIImageView()
                view.contentMode = .scaleAspectFit
                pieces[piece.id] = view
                addSubview(view)
            }
        }
// Create a view for each move indicator on the board, and add it to the view hierarchy.
        for _ in 0 ..< 8 {
            for _ in 0 ..< 8 {
                let view = UIView()
                view.backgroundColor = .white
                moveIndicators.append(view)
                addSubview(view)
            }
        }
// This adds a tap gesture recognizer to the view.
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }
// This method is called when the view is tapped.
    // It calculates the position of the tap and sends it to the delegate.
    @objc private func didTap(_ gesture: UITapGestureRecognizer) {
        let size = squareSize
        let location = gesture.location(in: self)
        let position = Position(
            x: Int(location.x / size.width),
            y: Int(location.y / size.height)
        )
        delegate?.boardView(self, didTap: position)
    }
// This method updates the pieces on the board.
    // It loops through the pieces on the board, and updates the corresponding views.
    private func updatePieces() {
        var usedIDs = Set<String>()
        let size = squareSize
        for (i, row) in board.pieces.enumerated() {
            for (j, piece) in row.enumerated() {
                guard let piece = piece, let view = pieces[piece.id] else {
                    continue
                }
                usedIDs.insert(piece.id)
                view.image = UIImage(named: piece.imageName)
                view.frame = frame(x: j, y: i, size: size)
                view.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0)
            }
        }
 // This loop sets the alpha of any unused pieces to 0.
        for (id, view) in pieces where !usedIDs.contains(id) {
            view.alpha = 0
        }
// This method is called to update the selection.
        updateSelection()
    }

// This method updates the selection on the board.
// It loops through the pieces on the board, and sets the
//alpha of the selected piece to 0.5, and 1 otherwise.
    private func updateSelection() {
        for (i, row) in board.pieces.enumerated() {
            for (j, piece) in row.enumerated() {
                guard let piece = piece, let view = pieces[piece.id] else {
                    continue
                }
                view.alpha = selection == Position(x: j, y: i) ? 0.5 : 1
            }
        }
    }

    private func updateMoveIndicators() {
        let size = squareSize
        for i in 0 ..< 8 {
            for j in 0 ..< 8 {
                let position = Position(x: j, y: i)
                let view = moveIndicators[i * 8 + j]
                view.frame = frame(x: j, y: i, size: size)
                view.layer.cornerRadius = size.width / 2
                view.layer.transform = CATransform3DMakeScale(0.2, 0.2, 0)
                view.alpha = moves.contains(position) ? 0.5 : 0
            }
        }
    }

// This method updates the move indicators on the board.
    // It loops through the squares on the board, and sets the alpha of the move indicators to 0.5 for any square that contains a valid move.
    private var squareSize: CGSize {
        let bounds = self.bounds.size
        return CGSize(width: ceil(bounds.width / 8), height: ceil(frame.height / 8))
    }

// This method returns the size of each square on the board.
    private func frame(x: Int, y: Int, size: CGSize) -> CGRect {
        let offset = CGPoint(x: CGFloat(x) * size.width, y: CGFloat(y) * size.height)
        return CGRect(origin: offset, size: size)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
// Get the size of each square on the board.
        let size = squareSize
// Loop through each position on the board and set the frame of the corresponding square view.
        for i in 0 ..< 8 {
            for j in 0 ..< 8 {
                squares[i * 8 + j].frame = frame(x: j, y: i, size: size)
            }
        }
// Update the pieces and move indicators on the board.
        updatePieces()
        updateMoveIndicators()
    }
}

private extension UIImageView {
    func pulse(
        scale: CGFloat = 1.5,
        duration: TimeInterval = 0.6,
        completion: (() -> Void)? = nil
    ) {
// Create a new UIImageView with the same frame and image as the current UIImageView.
        let pulseView = UIImageView(frame: frame)
        pulseView.image = image
// Add the new UIImageView to the superview.
        superview?.addSubview(pulseView)
        UIView.animate(
// Animate the pulse effect by scaling up the new UIImageView and reducing its alpha, and removing it from the superview when done.
            withDuration: 0.6,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                pulseView.transform = .init(scaleX: 2, y: 2)
                pulseView.alpha = 0
            }, completion: { _ in
                pulseView.removeFromSuperview()
                completion?()
            }
        )
    }
}

