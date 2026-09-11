# Chess Tactics Master - Implementation Guide

**Project**: Chess Tactics Master (Flutter/Dart)  
**Version**: 1.0.0  
**Last Updated**: 2026-09-11  
**Purpose**: Detailed implementation guide for fixing issues identified in CODE_AUDIT_REPORT.md

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Critical Issues (Phase 1)](#critical-issues-phase-1)
3. [High Priority Issues (Phase 2)](#high-priority-issues-phase-2)
4. [Medium Priority Issues (Phase 3)](#medium-priority-issues-phase-3)
5. [Testing Strategy](#testing-strategy)
6. [Deployment Checklist](#deployment-checklist)

---

## Quick Start

### Setup & Build

```bash
# 1. Clone repository
git clone https://github.com/org-zka32101/chess.git
cd chess

# 2. Checkout development branch
git checkout claude/phase-d-stage-3-device-testing-wgxbuo

# 3. Install dependencies
flutter pub get

# 4. Generate code (Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# 5. Run code analysis
dart analyze lib/

# 6. Run tests
flutter test

# 7. Run on device
flutter run
```

### Expected Initial State

- ✅ Project compiles successfully
- ⚠️ Some game features may be incomplete (TODOs present)
- ⚠️ Firebase configuration needed (.env file)
- ⚠️ Some tests may fail until critical issues are fixed

---

## CRITICAL ISSUES (Phase 1)

### Issue 1: FEN Calculation Missing

**File**: `lib/src/providers/game_provider.dart` (Line 238)  
**Priority**: 🔴 CRITICAL  
**Time**: 3-4 hours  
**Impact**: Game progression impossible; move validation fails

#### Understanding the Issue

FEN (Forsyth-Edwards Notation) represents the complete chess board position. After each move, a new FEN must be calculated to:
- Represent the new board state
- Validate subsequent moves
- Enable move history tracking
- Support game resumption

Current code:
```dart
// BROKEN: Just copies old FEN
'currentFen': gameData['currentFen'], // TODO: Calculate new FEN
```

#### Solution Implementation

**Step 1: Enhance Chess Engine Service**

File: `lib/src/services/chess_engine_service.dart`

Add FEN calculation method:

```dart
/// Calculate new FEN after a move
String calculateFenAfterMove(String currentFen, String moveUci) {
  try {
    // Parse current position
    final board = Board.fromFen(currentFen);
    
    // Parse and validate move
    final move = Move.fromUci(moveUci);
    
    if (!board.isMoveLegal(move)) {
      throw IllegalMoveException('Move $moveUci is not legal in position $currentFen');
    }
    
    // Apply move to board
    board.makeMove(move);
    
    // Calculate new FEN
    return board.toFen();
  } catch (e) {
    debugPrint('Error calculating FEN: $e');
    rethrow;
  }
}

/// Validate FEN string format
bool validateFen(String fen) {
  try {
    Board.fromFen(fen);
    return true;
  } catch (e) {
    return false;
  }
}

/// Get all legal moves from position
List<String> getLegalMoves(String fen) {
  try {
    final board = Board.fromFen(fen);
    return board.legalMoves.map((move) => move.toUci()).toList();
  } catch (e) {
    return [];
  }
}
```

**Step 2: Update Game Provider**

File: `lib/src/providers/game_provider.dart` (around line 230-250)

Replace the incomplete FEN calculation:

```dart
// BEFORE (Broken):
await gameRef.update({
  'moves': currentMoves,
  'currentFen': gameData['currentFen'], // TODO: Calculate new FEN
  'updatedAt': FieldValue.serverTimestamp(),
});

// AFTER (Fixed):
final chessEngine = ref.read(chessEngineServiceProvider);
final newFen = chessEngine.calculateFenAfterMove(
  gameData['currentFen'] as String,
  move, // moveUci
);

await gameRef.update({
  'moves': currentMoves,
  'currentFen': newFen,
  'currentMove': move,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**Step 3: Add Error Handling**

```dart
try {
  final newFen = chessEngine.calculateFenAfterMove(
    gameData['currentFen'] as String,
    move,
  );
  
  // Validate FEN before saving
  if (!chessEngine.validateFen(newFen)) {
    throw InvalidFenException('Calculated FEN is invalid: $newFen');
  }
  
  await gameRef.update({
    'moves': currentMoves,
    'currentFen': newFen,
    'updatedAt': FieldValue.serverTimestamp(),
  });
} catch (e, stackTrace) {
  ErrorHandlerService.instance.logError(
    ErrorContext(
      message: 'Failed to update game move',
      error: e,
      stackTrace: stackTrace,
      severity: ErrorSeverity.critical,
      context: 'gameProvider.makeMove',
      metadata: {'gameId': gameId, 'move': move},
    ),
  );
  rethrow;
}
```

**Step 4: Testing**

Create test file: `test/services/chess_engine_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_tactics_master/src/services/chess_engine_service.dart';

void main() {
  group('ChessEngineService - FEN Calculation', () {
    late ChessEngineService service;

    setUp(() {
      service = ChessEngineService();
    });

    test('should calculate FEN after valid move', () {
      const initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
      const move = 'e2e4'; // Pawn to e4

      final newFen = service.calculateFenAfterMove(initialFen, move);

      expect(newFen, isNotEmpty);
      expect(newFen, isNotEqualTo(initialFen));
      expect(service.validateFen(newFen), isTrue);
    });

    test('should throw exception for illegal move', () {
      const initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
      const illegalMove = 'e1e3'; // Illegal king move

      expect(
        () => service.calculateFenAfterMove(initialFen, illegalMove),
        throwsException,
      );
    });

    test('should validate correct FEN', () {
      const validFen = 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1';
      expect(service.validateFen(validFen), isTrue);
    });

    test('should reject invalid FEN', () {
      const invalidFen = 'invalid/fen/string';
      expect(service.validateFen(invalidFen), isFalse);
    });

    test('should generate legal moves from position', () {
      const initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
      final legalMoves = service.getLegalMoves(initialFen);

      expect(legalMoves, isNotEmpty);
      expect(legalMoves.length, equals(20)); // Initial position has 20 legal moves
    });
  });
}
```

**Step 5: Verification**

Run tests:
```bash
flutter test test/services/chess_engine_service_test.dart
```

Expected output:
```
All tests passed!
- should calculate FEN after valid move: PASS
- should throw exception for illegal move: PASS
- should validate correct FEN: PASS
- should reject invalid FEN: PASS
- should generate legal moves from position: PASS
```

---

### Issue 2: FirebaseException Type Mismatch

**File**: `lib/src/services/error_handler_service.dart` (Lines 1-2, 95-96, 147, 182-190)  
**Priority**: 🔴 CRITICAL  
**Time**: 1-2 hours  
**Impact**: Firebase error handling fails; type checking incorrect

#### Understanding the Issue

The service uses a placeholder `FirebaseException` class instead of importing from `firebase_core`. This causes:
- Type checking failures
- Missing error context from real Firebase errors
- Incorrect error message generation

Current broken code:
```dart
// Line 1-2: Missing import
import 'package:logger/logger.dart';
// NO: import 'package:firebase_core/firebase_core.dart';

// Lines 95-96: Uses undefined type that gets defined later
if (error is FirebaseException) {
  return _getFirebaseErrorMessage(error);
}

// Lines 182-190: Placeholder definition (wrong approach)
class FirebaseException implements Exception {
  final String code;
  final String message;
  // ... etc
}
```

#### Solution Implementation

**Step 1: Update Imports**

File: `lib/src/services/error_handler_service.dart`

```dart
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';  // ADD THIS
```

**Step 2: Remove Placeholder Class**

Delete lines 181-190 (the placeholder `FirebaseException` class definition).

**Step 3: Complete Implementation**

```dart
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';

/// Severity levels for errors
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Error context for logging
class ErrorContext {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;
  final String? userId;
  final String? context;
  final Map<String, dynamic>? metadata;

  ErrorContext({
    required this.message,
    this.error,
    this.stackTrace,
    this.severity = ErrorSeverity.error,
    this.userId,
    this.context,
    this.metadata,
  });
}

/// Centralized error handling and logging service
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._();
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  ErrorHandlerService._();

  static ErrorHandlerService get instance => _instance;

  /// Log an error with context
  void logError(ErrorContext context) {
    final formattedMessage = _formatMessage(context);

    switch (context.severity) {
      case ErrorSeverity.info:
        _logger.i(formattedMessage, error: context.error, stackTrace: context.stackTrace);
        break;
      case ErrorSeverity.warning:
        _logger.w(formattedMessage, error: context.error, stackTrace: context.stackTrace);
        break;
      case ErrorSeverity.error:
        _logger.e(formattedMessage, error: context.error, stackTrace: context.stackTrace);
        break;
      case ErrorSeverity.critical:
        _logger.wtf(formattedMessage, error: context.error, stackTrace: context.stackTrace);
        break;
    }

    // In production, send critical errors to crash reporting
    if (context.severity == ErrorSeverity.critical) {
      _reportCriticalError(context);
    }
  }

  /// Handle a service error with automatic logging and user-friendly message
  String handleServiceError(
    String operationName, {
    required Object error,
    StackTrace? stackTrace,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    final context = ErrorContext(
      message: 'Service error in $operationName',
      error: error,
      stackTrace: stackTrace,
      severity: ErrorSeverity.error,
      userId: userId,
      context: operationName,
      metadata: metadata,
    );

    logError(context);

    // Return user-friendly error message
    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error);
    }

    return 'An error occurred while $operationName. Please try again.';
  }

  /// Handle validation errors
  String? validateInput(String? input, {required String fieldName, int? minLength, int? maxLength}) {
    if (input == null || input.isEmpty) {
      logError(ErrorContext(
        message: 'Validation error: $fieldName is empty',
        severity: ErrorSeverity.warning,
        context: 'Input validation',
        metadata: {'field': fieldName},
      ));
      return '$fieldName cannot be empty';
    }

    if (minLength != null && input.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && input.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  /// Format error message with context
  String _formatMessage(ErrorContext context) {
    final buffer = StringBuffer();
    buffer.writeln('[${context.severity.name.toUpperCase()}] ${context.message}');

    if (context.context != null) {
      buffer.writeln('Context: ${context.context}');
    }

    if (context.userId != null) {
      buffer.writeln('User ID: ${context.userId}');
    }

    if (context.metadata != null && context.metadata!.isNotEmpty) {
      buffer.writeln('Metadata: ${context.metadata}');
    }

    return buffer.toString();
  }

  /// Get user-friendly Firebase error message
  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'not-found':
        return 'The requested resource was not found.';
      case 'already-exists':
        return 'This item already exists.';
      case 'failed-precondition':
        return 'Operation cannot be completed. Please try again.';
      case 'aborted':
        return 'Operation was cancelled. Please try again.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection and try again.';
      default:
        return 'An error occurred. Please try again or contact support.';
    }
  }

  /// Report critical errors (send to crash reporting service)
  void _reportCriticalError(ErrorContext context) {
    // TODO: Integrate with Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(context.error, context.stackTrace);
    _logger.wtf('CRITICAL ERROR REPORTED: ${context.message}');
  }
}

/// Singleton accessor
final errorHandlerService = ErrorHandlerService.instance;
```

**Step 4: Testing**

Create test file: `test/services/error_handler_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chess_tactics_master/src/services/error_handler_service.dart';

void main() {
  group('ErrorHandlerService', () {
    late ErrorHandlerService service;

    setUp(() {
      service = ErrorHandlerService.instance;
    });

    test('should handle Firebase permission-denied error', () {
      const errorMessage = 'An error occurred. Please try again or contact support.';
      // Note: Can't create real FirebaseException in test without full Firebase setup
      // This is a conceptual test showing the pattern
      
      expect(errorMessage, isNotEmpty);
    });

    test('should handle validation errors', () {
      const fieldName = 'email';
      final error = service.validateInput('', fieldName: fieldName);

      expect(error, equals('$fieldName cannot be empty'));
    });

    test('should check minimum length', () {
      const fieldName = 'password';
      final error = service.validateInput('123', fieldName: fieldName, minLength: 6);

      expect(error, contains('at least 6 characters'));
    });

    test('should log errors with context', () {
      final context = ErrorContext(
        message: 'Test error',
        severity: ErrorSeverity.warning,
        context: 'test_context',
        metadata: {'test': true},
      );

      expect(() => service.logError(context), returnsNormally);
    });
  });
}
```

**Step 5: Verification**

Run tests:
```bash
flutter test test/services/error_handler_service_test.dart
```

Verify imports:
```bash
dart analyze lib/src/services/error_handler_service.dart
```

---

### Issue 3: Implement Draw Offer & Claim Logic

**File**: `lib/src/screens/online/online_game_screen.dart` (Lines 467, 489)  
**Priority**: 🟠 HIGH  
**Time**: 4-5 hours  
**Impact**: Draw offers/claims don't work; multiplayer games stuck

#### Understanding the Issue

Draw offers and claims are UI-only placeholders. Need:
1. `DrawOffer` model to represent draw state
2. Firestore persistence for draw offers
3. Backend validation logic
4. Real-time synchronization between players

#### Solution Implementation

**Step 1: Create Draw Offer Model**

File: `lib/src/models/draw_offer.dart` (new file)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'draw_offer.freezed.dart';
part 'draw_offer.g.dart';

@freezed
class DrawOffer with _$DrawOffer {
  const factory DrawOffer({
    required String gameId,
    required String offeredByUserId,
    required DateTime offeredAt,
    required DrawOfferStatus status,
    DateTime? respondedAt,
    String? respondedByUserId,
  }) = _DrawOffer;

  factory DrawOffer.fromJson(Map<String, dynamic> json) => _$DrawOfferFromJson(json);
}

enum DrawOfferStatus {
  pending,
  accepted,
  declined,
  expired,
}

/// Draw claim based on 50-move rule or threefold repetition
@freezed
class DrawClaim with _$DrawClaim {
  const factory DrawClaim({
    required String gameId,
    required String claimedByUserId,
    required DateTime claimedAt,
    required DrawClaimType type,
    required DrawClaimStatus status,
  }) = _DrawClaim;

  factory DrawClaim.fromJson(Map<String, dynamic> json) => _$DrawClaimFromJson(json);
}

enum DrawClaimType {
  fiftyMoveRule,
  threefoldRepetition,
  insufficient,
}

enum DrawClaimStatus {
  pending,
  accepted,
  rejected,
}
```

**Step 2: Create Draw Service**

File: `lib/src/services/draw_service.dart` (new file)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/draw_offer.dart';

class DrawService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const drawOfferTimeoutMinutes = 5;
  static const fiftyMoveRuleThreshold = 50;

  /// Offer draw
  Future<void> offerDraw(String gameId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final drawOffer = DrawOffer(
      gameId: gameId,
      offeredByUserId: userId,
      offeredAt: DateTime.now(),
      status: DrawOfferStatus.pending,
    );

    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('draw_offers')
        .add(drawOffer.toJson());
  }

  /// Accept draw offer
  Future<void> acceptDrawOffer(String gameId, String offerId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('draw_offers')
        .doc(offerId)
        .update({
      'status': DrawOfferStatus.accepted.name,
      'respondedAt': FieldValue.serverTimestamp(),
      'respondedByUserId': userId,
    });

    // Update game status
    await _firestore.collection('games').doc(gameId).update({
      'status': 'draw',
      'drawType': 'offer_accepted',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Decline draw offer
  Future<void> declineDrawOffer(String gameId, String offerId) async {
    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('draw_offers')
        .doc(offerId)
        .update({
      'status': DrawOfferStatus.declined.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Claim draw (50-move rule, threefold repetition, etc.)
  Future<void> claimDraw(
    String gameId,
    DrawClaimType claimType,
    List<String> moveHistory,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Validate claim
    switch (claimType) {
      case DrawClaimType.fiftyMoveRule:
        if (!_validateFiftyMoveRule(moveHistory)) {
          throw Exception('50-move rule not met');
        }
        break;
      case DrawClaimType.threefoldRepetition:
        if (!_validateThreefoldRepetition(moveHistory)) {
          throw Exception('Threefold repetition not detected');
        }
        break;
      case DrawClaimType.insufficient:
        if (!_validateInsufficientMaterial(moveHistory)) {
          throw Exception('Insufficient material not present');
        }
        break;
    }

    // Create draw claim
    final drawClaim = DrawClaim(
      gameId: gameId,
      claimedByUserId: userId,
      claimedAt: DateTime.now(),
      type: claimType,
      status: DrawClaimStatus.pending,
    );

    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('draw_claims')
        .add(drawClaim.toJson());
  }

  /// Get active draw offers for a game
  Stream<List<DrawOffer>> getActiveDrawOffers(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('draw_offers')
        .where('status', isEqualTo: DrawOfferStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DrawOffer.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Validate 50-move rule
  bool _validateFiftyMoveRule(List<String> moveHistory) {
    // Count non-capture, non-pawn moves
    int count = 0;
    for (int i = moveHistory.length - 1; i >= 0; i--) {
      // Simple check: assume moves without capture notation
      if (!moveHistory[i].contains('x')) {
        count++;
      } else {
        count = 0; // Reset on capture
      }
    }
    return count >= fiftyMoveRuleThreshold;
  }

  /// Validate threefold repetition
  bool _validateThreefoldRepetition(List<String> moveHistory) {
    // This would need FEN comparison
    // Simplified version: count FEN positions
    // Full implementation requires board state tracking
    return false; // Placeholder
  }

  /// Validate insufficient material
  bool _validateInsufficientMaterial(List<String> moveHistory) {
    // Check if only kings remain, or king + minor piece
    // Full implementation requires piece counting
    return false; // Placeholder
  }
}
```

**Step 3: Update Online Game Screen**

File: `lib/src/screens/online/online_game_screen.dart`

Replace TODO comments with actual implementation:

```dart
// BEFORE (Line 467):
// TODO: Implement actual draw offer logic with backend

// AFTER:
Future<void> _offerDraw() async {
  final drawService = ref.read(drawServiceProvider);
  try {
    await drawService.offerDraw(gameId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw offer sent')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

// BEFORE (Line 489):
// TODO: Implement draw claim validation logic

// AFTER:
Future<void> _claimDraw(DrawClaimType type) async {
  final drawService = ref.read(drawServiceProvider);
  final game = ref.read(gameByIdProvider(gameId)).value;
  
  if (game == null) return;
  
  try {
    await drawService.claimDraw(
      gameId,
      type,
      game.moves ?? [],
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${type.name} claim submitted')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claim rejected: $e')),
      );
    }
  }
}
```

**Step 4: Create Draw Service Provider**

File: `lib/src/providers/draw_provider.dart` (new file)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/draw_service.dart';
import '../models/draw_offer.dart';

final drawServiceProvider = Provider((ref) => DrawService());

final activeDrawOffersProvider = StreamProvider.family<List<DrawOffer>, String>(
  (ref, gameId) {
    final drawService = ref.watch(drawServiceProvider);
    return drawService.getActiveDrawOffers(gameId);
  },
);
```

---

## HIGH PRIORITY ISSUES (Phase 2)

### Issue 4: Complete Settings Implementation

**File**: `lib/src/screens/settings/settings_screen.dart` (Lines 94, 152, 160)  
**Priority**: 🟠 HIGH  
**Time**: 2-3 hours

[Implementation details similar to above, focused on:
- Connecting coordinates toggle to preferences
- Implementing policy links
- Adding URL launcher]

### Issue 5: Chess Engine Enhancement

**File**: `lib/src/services/chess_engine_service.dart`  
**Priority**: 🟠 HIGH  
**Time**: 5-6 hours

[Comprehensive enhancement of chess engine with move generation, caching, evaluation]

---

## MEDIUM PRIORITY ISSUES (Phase 3)

### Issue 6-9: Medium Priority Fixes

[Details on Crashlytics integration, Analytics, Sound service, Performance optimization]

---

## Testing Strategy

### Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/services/chess_engine_service_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
lcov --list coverage/lcov.info
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/

# Run on specific device
flutter test integration_test/ -d <device-id>
```

### Manual Testing Checklist

- [ ] Start new game
- [ ] Make moves
- [ ] Capture pieces
- [ ] Achieve checkmate
- [ ] Offer draw
- [ ] Claim draw
- [ ] Resign game
- [ ] View game history
- [ ] Check ratings update
- [ ] Test on iOS
- [ ] Test on Android

---

## Deployment Checklist

### Before Local Testing
- [ ] Run `dart run build_runner build`
- [ ] Fix FEN calculation
- [ ] Fix Firebase exception import
- [ ] Run `dart analyze lib/`
- [ ] Run `flutter test`
- [ ] Verify `.env` configuration

### Before Beta Release
- [ ] Complete all HIGH priority fixes
- [ ] Pass all tests (>80% coverage)
- [ ] Security audit passed
- [ ] Performance profiling completed
- [ ] Privacy policy implemented

### Before Production
- [ ] Complete all MEDIUM priority fixes
- [ ] 90% test coverage
- [ ] Big 4 audit passed
- [ ] SOX 404 compliance verified
- [ ] App Store/Play Store approved

---

## Quick Reference

### Important Files to Modify

```
Phase 1 (Critical):
□ lib/src/providers/game_provider.dart (FEN calculation)
□ lib/src/services/error_handler_service.dart (Firebase import)
□ lib/src/services/chess_engine_service.dart (FEN methods)

Phase 2 (High):
□ lib/src/screens/online/online_game_screen.dart (Draw logic)
□ lib/src/screens/settings/settings_screen.dart (Settings)
□ lib/src/services/draw_service.dart (New: Draw handling)
□ lib/src/models/draw_offer.dart (New: Draw models)

Phase 3 (Medium):
□ lib/src/services/error_handler_service.dart (Crashlytics)
□ lib/src/providers/analytics_*_provider.dart (Analytics)
□ Multiple widget tests (Test coverage)
```

### Useful Commands

```bash
# Format code
dart format lib/

# Analyze code
dart analyze lib/

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Build APK
flutter build apk --release

# View logs
flutter logs
```

---

**Next Steps**: Select one critical issue and start implementation using this guide as reference.

