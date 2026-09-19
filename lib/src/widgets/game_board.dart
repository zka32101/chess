import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:chess_tactics_master/src/widgets/chess_board.dart';
import 'package:chess_tactics_master/src/widgets/captured_pieces.dart';

/// Game container with board and controls
class GameBoard extends StatefulWidget {
  final chess_lib.Chess gameState;
  final Function(String, String, {String? promotion})? onMove;
  final Function()? onUndo;
  final Function()? onResign;
  final Function()? onDraw;
  final List<chess_lib.Move> moveHistory;
  final bool showMaterial;
  final bool isPlayerTurn;

  const GameBoard({
    Key? key,
    required this.gameState,
    this.onMove,
    this.onUndo,
    this.onResign,
    this.onDraw,
    this.moveHistory = const [],
    this.showMaterial = true,
    this.isPlayerTurn = true,
  }) : super(key: key);

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  String? _selectedSquare;
  List<String> _availableMoves = [];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Captured pieces display
          if (widget.showMaterial)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CapturedPieces(
                whiteCapturedPieces: _getWhiteCapturedPieces(),
                blackCapturedPieces: _getBlackCapturedPieces(),
              ),
            ),

          // Turn indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              widget.gameState.turn == chess_lib.Color.WHITE
                  ? 'White to Move'
                  : 'Black to Move',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.gameState.turn == chess_lib.Color.WHITE
                        ? Colors.grey[300]
                        : Colors.grey[700],
                  ),
            ),
          ),

          // Chess board
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ChessBoard(
              gameState: widget.gameState,
              onSquareTap: _handleSquareTap,
              selectedSquare: _selectedSquare,
              highlightedSquares: _availableMoves,
            ),
          ),

          // Game controls
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (widget.onUndo != null)
                    ElevatedButton.icon(
                      onPressed:
                          widget.moveHistory.isEmpty ? null : widget.onUndo,
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                    ),
                  if (widget.onResign != null)
                    ElevatedButton.icon(
                      onPressed: widget.onResign,
                      icon: const Icon(Icons.flag),
                      label: const Text('Resign'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  if (widget.onDraw != null)
                    ElevatedButton.icon(
                      onPressed: widget.onDraw,
                      icon: const Icon(Icons.handshake),
                      label: const Text('Offer Draw'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleSquareTap(String square) {
    if (!widget.isPlayerTurn) return;

    final piece = _getPieceAt(square);

    if (_selectedSquare == null) {
      // Select piece
      if (piece != null && piece.color == widget.gameState.turn) {
        setState(() {
          _selectedSquare = square;
          _availableMoves = _getLegalMovesForSquare(square);
        });
      }
    } else {
      // Attempt move or re-select
      if (square == _selectedSquare) {
        // Deselect
        setState(() {
          _selectedSquare = null;
          _availableMoves = [];
        });
      } else if (_availableMoves.contains(square)) {
        // Make move
        final from = _selectedSquare!;
        final to = square;

        // Handle promotion
        String? promotion;
        final piece = _getPieceAt(from);
        if (piece?.type == chess_lib.PieceType.pawn &&
            ((piece?.color == chess_lib.Color.WHITE && to[1] == '8') ||
                (piece?.color == chess_lib.Color.BLACK && to[1] == '1'))) {
          // Show promotion dialog
          _showPromotionDialog(from, to);
        } else {
          widget.onMove?.call(from, to);
          setState(() {
            _selectedSquare = null;
            _availableMoves = [];
          });
        }
      } else {
        // Select different piece
        if (piece != null && piece.color == widget.gameState.turn) {
          setState(() {
            _selectedSquare = square;
            _availableMoves = _getLegalMovesForSquare(square);
          });
        } else {
          setState(() {
            _selectedSquare = null;
            _availableMoves = [];
          });
        }
      }
    }
  }

  void _showPromotionDialog(String from, String to) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote Pawn'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['q', 'r', 'b', 'n'].map((promotion) {
            final labels = {
              'q': 'Queen',
              'r': 'Rook',
              'b': 'Bishop',
              'n': 'Knight',
            };
            return ElevatedButton(
              onPressed: () {
                widget.onMove?.call(from, to, promotion: promotion);
                Navigator.pop(context);
                setState(() {
                  _selectedSquare = null;
                  _availableMoves = [];
                });
              },
              child: Text(labels[promotion] ?? promotion),
            );
          }).toList(),
        ),
      ),
    );
  }

  chess_lib.Piece? _getPieceAt(String square) {
    try {
      final rank = int.parse(square[1]) - 1;
      final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
      return widget.gameState.board[rank][file];
    } catch (e) {
      return null;
    }
  }

  List<String> _getLegalMovesForSquare(String square) {
    return (widget.gameState.moves() as List<chess_lib.Move>)
        .where((move) => move.fromAlgebraic == square)
        .map((move) => move.toAlgebraic)
        .toList();
  }

  List<chess_lib.Piece> _getWhiteCapturedPieces() {
    final captured = <chess_lib.Piece>[];
    // Count pieces on board to determine captured
    final whitePieces = _countPieces(chess_lib.Color.WHITE);

    final initialCounts = {
      chess_lib.PieceType.pawn: 8,
      chess_lib.PieceType.knight: 2,
      chess_lib.PieceType.bishop: 2,
      chess_lib.PieceType.rook: 2,
      chess_lib.PieceType.queen: 1,
    };

    initialCounts.forEach((type, count) {
      final currentCount = whitePieces[type] ?? 0;
      final capturedCount = count - currentCount;
      for (int i = 0; i < capturedCount; i++) {
        captured.add(chess_lib.Piece(
          color: chess_lib.Color.WHITE,
          type: type,
        ));
      }
    });

    return captured;
  }

  List<chess_lib.Piece> _getBlackCapturedPieces() {
    final captured = <chess_lib.Piece>[];
    final blackPieces = _countPieces(chess_lib.Color.BLACK);

    final initialCounts = {
      chess_lib.PieceType.pawn: 8,
      chess_lib.PieceType.knight: 2,
      chess_lib.PieceType.bishop: 2,
      chess_lib.PieceType.rook: 2,
      chess_lib.PieceType.queen: 1,
    };

    initialCounts.forEach((type, count) {
      final currentCount = blackPieces[type] ?? 0;
      final capturedCount = count - currentCount;
      for (int i = 0; i < capturedCount; i++) {
        captured.add(chess_lib.Piece(
          color: chess_lib.Color.BLACK,
          type: type,
        ));
      }
    });

    return captured;
  }

  Map<chess_lib.PieceType, int> _countPieces(chess_lib.Color color) {
    final counts = <chess_lib.PieceType, int>{};
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final piece = widget.gameState.board[rank][file];
        if (piece != null && piece.color == color) {
          counts[piece.type] = (counts[piece.type] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}
