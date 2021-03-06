//
//  FDChessboardView.swift
//  FDChessboardView
//
//  Created by William Entriken on 2/2/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import UIKit

struct FDChessboardSquare {
    /// From 0...7
    var file: Int
    
    /// From 0...7
    var rank: Int
    
    var algebriac: String {
        get {
            return String(UnicodeScalar(96 + file)) + String(rank)
        }
    }
    
    var index: Int {
        get {
            return rank * 8 + file
        }
        set {
            file = index % 8
            rank = index / 8
        }
    }
    
    init(index newIndex: Int) {
        file = newIndex % 8
        rank = newIndex / 8
    }
}

enum FDChessboardPiece: String {
    case WhitePawn = "wp"
    case BlackPawn = "bp"
    case WhiteKnight = "wn"
    case BlackKnight = "bn"
    case WhiteBishop = "wb"
    case BlackBishop = "bb"
    case WhiteRook = "wr"
    case BlackRook = "br"
    case WhiteQueen = "wq"
    case BlackQueen = "bq"
    case WhiteKing = "wk"
    case BlackKing = "bk"
}

protocol FDChessboardViewDataSource: class {
    /// What piece is on the square?
    func chessboardView(board: FDChessboardView, pieceForSquare square: FDChessboardSquare) -> FDChessboardPiece?
    
    /// The last move
    func chessboardViewLastMove(board: FDChessboardView) -> (from:FDChessboardSquare, to:FDChessboardSquare)?
    
    /// The premove
    func chessboardViewPremove(board: FDChessboardView) -> (from:FDChessboardSquare, to:FDChessboardSquare)?
}

protocol FDChessboardViewDelegate: class {
    /// Where can this piece move to?
    func chessboardView(board: FDChessboardView, legalDestinationsForPieceAtSquare from: FDChessboardSquare) -> [FDChessboardSquare]
    
    /// Before a move happens (cannot be stopped)
    func chessboardView(board: FDChessboardView, willMoveFrom from: FDChessboardSquare, to: FDChessboardSquare)
    
    /// After a move happened
    func chessboardView(board: FDChessboardView, didMoveFrom from: FDChessboardSquare, to: FDChessboardSquare)
    
    /// Before a move happens (cannot be stopped)
    func chessboardView(board: FDChessboardView, willMoveFrom from: FDChessboardSquare, to: FDChessboardSquare, withPromotion promotion: FDChessboardPiece)
    
    /// After a move happened
    func chessboardView(board: FDChessboardView, didMoveFrom from: FDChessboardSquare, to: FDChessboardSquare, withPromotion promotion: FDChessboardPiece)
}

class FDChessboardView: UIView {
    var lightBackgroundColor = UIColor(red: 222.0/255, green:196.0/255, blue:160.0/255, alpha:1)
    var darkBackgroundColor = UIColor(red: 160.0/255, green:120.0/255, blue:55.0/255, alpha:1)
    var targetBackgroundColor = UIColor(hue: 0.75, saturation:0.5, brightness:0.5, alpha:1.0)
    var legalBackgroundColor = UIColor(hue: 0.25, saturation:0.5, brightness:0.5, alpha:1.0)
    var lastMoveColor = UIColor(hue: 0.35, saturation:0.5, brightness:0.5, alpha:1.0)
    var premoveColor = UIColor(hue: 0.15, saturation:0.5, brightness:0.5, alpha:1.0)
    var pieceGraphicsDirectoryPath: String? = nil
    
    /// temporary until SVG is fixed
    private let lightPieceColor = UIColor.whiteColor()
    
    /// temporary until SVG is fixed
    private let darkPieceColor = UIColor.blackColor()
    
    weak var dataSource: FDChessboardViewDataSource? = nil {
        didSet {
            reloadData()
        }
    }

    weak var delegate: FDChessboardViewDelegate? = nil
    
    var doesAnimate: Bool = true
    var doesShowLegalSquares: Bool = true
    var doesShowLastMove: Bool = true
    var doesShowPremove: Bool = true
    
    private lazy var tilesAtIndex = [UIView]()
    
    private var pieceAtIndex = [Int : FDChessboardPiece]()
    
    private var pieceImageViewAtIndex = [Int : UIImageView]()
    
    private var lastMoveArrow: UIView? = nil
    
    private var premoveArrow: UIView? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    

    func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        for index in 0..<64 {
            let square = FDChessboardSquare(index: index)
            let tile = UIView()
            tile.backgroundColor = (index + index/8) % 2 == 0 ? darkBackgroundColor : lightBackgroundColor
            tile.translatesAutoresizingMaskIntoConstraints = false
            addSubview(tile)
            tilesAtIndex.append(tile)

            switch square.rank {
            case 0:
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0))
            case 7:
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Bottom, relatedBy: .Equal, toItem: tilesAtIndex[index - 8], attribute: .Top, multiplier: 1, constant: 0))
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Height, relatedBy: .Equal, toItem: tilesAtIndex[index - 8], attribute: .Height, multiplier: 1, constant: 0))
            default:
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Bottom, relatedBy: .Equal, toItem: tilesAtIndex[index - 8], attribute: .Top, multiplier: 1, constant: 0))
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Height, relatedBy: .Equal, toItem: tilesAtIndex[index - 8], attribute: .Height, multiplier: 1, constant: 0))
            }
            switch square.file {
            case 0:
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0))
            case 7:
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Left, relatedBy: .Equal, toItem: tilesAtIndex[index - 1], attribute: .Right, multiplier: 1, constant: 0))
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0))
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Width, relatedBy: .Equal, toItem: tilesAtIndex[index - 1], attribute: .Width, multiplier: 1, constant: 0))
            default:
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Left, relatedBy: .Equal, toItem: tilesAtIndex[index - 1], attribute: .Right, multiplier: 1, constant: 0))
                addConstraint(NSLayoutConstraint(item: tile, attribute: .Width, relatedBy: .Equal, toItem: tilesAtIndex[index - 1], attribute: .Width, multiplier: 1, constant: 0))
            }
        }
        self.layoutIfNeeded()
    }

    
    
    /*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
UITouch *touch = [touches anyObject];
CGPoint point = [touch locationInView:self];
NSInteger x = point.x*8/self.frame.size.width;
NSInteger y = 8-point.y*8/self.frame.size.height;
UIView *tile = self.tilesPerSquare[y*8+x];
tile.backgroundColor = self.targetBackgroundColor;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
UITouch *touch = [touches anyObject];
CGPoint point = [touch locationInView:self];
if (![self pointInside:point withEvent:event])
return;
NSInteger x = point.x*8/self.frame.size.width;
NSInteger y = 8-point.y*8/self.frame.size.height;
UIView *tile = self.tilesPerSquare[y*8+x];
tile.backgroundColor = self.legalBackgroundColor;
}
*/
    
    func setPiece(piece: FDChessboardPiece?, forSquare square: FDChessboardSquare){
        let index = square.index
        pieceAtIndex[index] = piece
        self.pieceImageViewAtIndex[index]?.removeFromSuperview()
        
        self.pieceImageViewAtIndex.removeValueForKey(index)

        guard let piece = piece else {
            return
        }
        
        let pieceImageView: UIImageView
        let fileName = piece.rawValue
        let pieceColor: UIColor
        
        switch piece {
        case .WhitePawn:
            pieceColor = lightPieceColor
        case .WhiteKnight:
            pieceColor = lightPieceColor
        case .WhiteBishop:
            pieceColor = lightPieceColor
        case .WhiteRook:
            pieceColor = lightPieceColor
        case .WhiteQueen:
            pieceColor = lightPieceColor
        case .WhiteKing:
            pieceColor = lightPieceColor
        case .BlackPawn:
            pieceColor = darkPieceColor
        case .BlackKnight:
            pieceColor = darkPieceColor
        case .BlackBishop:
            pieceColor = darkPieceColor
        case .BlackRook:
            pieceColor = darkPieceColor
        case .BlackQueen:
            pieceColor = darkPieceColor
        case .BlackKing:
            pieceColor = darkPieceColor
        }
        
        let image = UIImage(SVGNamed: fileName, targetSize: CGSizeMake(200, 200), fillColor: pieceColor)
        pieceImageView = UIImageView(image: image)
        pieceImageView.translatesAutoresizingMaskIntoConstraints = false
        self.pieceImageViewAtIndex[index] = pieceImageView
        self.addSubview(pieceImageView)
        
        let squareOne = self.tilesAtIndex.first!
        self.addConstraint(NSLayoutConstraint(item: pieceImageView, attribute: .Width, relatedBy: .Equal, toItem: squareOne, attribute: .Width, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: pieceImageView, attribute: .Height, relatedBy: .Equal, toItem: squareOne, attribute: .Height, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: pieceImageView, attribute: .Top, relatedBy: .Equal, toItem: self.tilesAtIndex[index], attribute: .Top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: pieceImageView, attribute: .Leading, relatedBy: .Equal, toItem: self.tilesAtIndex[index], attribute: .Leading, multiplier: 1, constant: 0))
        self.layoutIfNeeded()
    }
    
    func reloadData() {
        for index in 0 ..< 64 {
            let square = FDChessboardSquare(index: index)
            let newPiece = dataSource?.chessboardView(self, pieceForSquare:square)
            setPiece(newPiece, forSquare: square)
        }
        self.layoutIfNeeded()
    }
    
    func movePieceAtCoordinate(from: FDChessboardSquare, toCoordinate to: FDChessboardSquare) -> Bool {
        return true
    }
    
    func movePieceAtCoordinate(from: FDChessboardSquare, toCoordinate to: FDChessboardSquare, andPromoteTo piece: FDChessboardPiece) -> Bool {
        return true
    }
    
    func premovePieceAtCoordinate(from: FDChessboardSquare, toCoordinate to: FDChessboardSquare) -> Bool {
        return true
    }
    
    func premovePieceAtCoordinate(from: FDChessboardSquare, toCoordinate to: FDChessboardSquare, andPromoteTo piece: FDChessboardPiece) -> Bool {
        return true
    }
    
}