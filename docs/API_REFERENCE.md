# Chess Tactics Master - API Reference

## Services Architecture

### Core Services

#### 1. ChessEngineService
Chess game logic and move validation engine.

**Location**: `lib/src/services/chess_engine_service.dart`

**Key Methods**:
- `initGame({String? fen})` - Initialize a new game with optional FEN
- `makeMove(String from, String to, {String? promotion})` - Execute a move
- `getLegalMoves()` - Get all legal moves in current position
- `validateMoveDetailed(String from, String to, {String? promotion})` - Validate move with error details
- `analyzePosition()` - Analyze current position for tactics and material
- `getCurrentFen()` - Get current position as FEN string
- `isGameOver()` - Check if game has ended
- `getGameResult()` - Get result (white_win, black_win, draw)

**Example**:
```dart
final chess = ChessEngineService();
chess.initGame(); // Start new game
final isLegal = chess.isLegalMove('e2', 'e4');
if (isLegal) {
  chess.makeMove('e2', 'e4');
  final fen = chess.getCurrentFen();
  print('New position: $fen');
}
```

---

#### 2. FenCalculatorService
FEN (Forsyth-Edwards Notation) calculation and management.

**Location**: `lib/src/services/fen_calculator_service.dart`

**Key Methods**:
- `calculateNewFen(String currentFen, String from, String to, {String? promotion})` - Calculate FEN after move
- `calculateFenFromMoves(List<Map<String, dynamic>> moves, {String startingFen})` - Reconstruct position from moves
- `isValidFen(String fen)` - Validate FEN string
- `getPiecePlacement(String fen)` - Extract piece placement from FEN
- `getActiveColor(String fen)` - Get whose turn (w/b)
- `getHalfmoveClock(String fen)` - Get halfmove clock (for 50-move rule)

**Example**:
```dart
final newFen = FenCalculatorService.calculateNewFen(
  'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  'e2',
  'e4',
);
// Returns: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'
```

---

#### 3. DrawDetectionService
Comprehensive draw condition detection (stalemate, insufficient material, 50-move rule, threefold repetition).

**Location**: `lib/src/services/draw_detection_service.dart`

**Key Methods**:
- `isStalemate(Chess chess)` - Check for stalemate
- `isInsufficientMaterial(Chess chess)` - Check for insufficient material
- `isFiftyMoveRuleDraw(String fen)` - Check 50-move rule (100 halfmoves)
- `isThreefoldRepetition(List<Map> moves, String fen)` - Check threefold repetition
- `getDrawReasons(Chess chess, String fen, List<Map> moves)` - Get all applicable draw reasons
- `canClaimDraw(Chess chess, String fen, List<Map> moves)` - Check if draw can be claimed

**Example**:
```dart
if (DrawDetectionService.canClaimDraw(chess, currentFen, moveHistory)) {
  print('Draw can be claimed');
  final reasons = DrawDetectionService.getDrawReasons(chess, currentFen, moveHistory);
  print('Reasons: $reasons'); // e.g., ['stalemate', '50-move-rule']
}
```

---

#### 4. MoveValidationService
Detailed move validation with error reporting and position analysis.

**Location**: `lib/src/services/move_validation_service.dart`

**Key Methods**:
- `validateMove(Chess chess, String from, String to, {String? promotion})` → `MoveValidationResult`
- `getLegalMovesFromSquareDetailed(Chess chess, String square)` → `List<LegalMove>`
- `analyzePosition(Chess chess)` → `PositionAnalysis`

**Classes**:
```dart
class MoveValidationResult {
  final bool isValid;
  final String? error;  // e.g., "Pawn promotion required"
}

class LegalMove {
  final String from, to;
  final String? promotion;
  final bool isCheck, isCheckmate, isCapture;
}

class PositionAnalysis {
  final int legalMovesCount;
  final bool checkMovesAvailable, captureMovesAvailable;
  final bool isCheck, isStalemate, isCheckmate;
  final int whiteMaterial, blackMaterial;
  int get materialAdvantage => whiteMaterial - blackMaterial;
}
```

**Example**:
```dart
final result = MoveValidationService.validateMove(chess, 'e2', 'e4');
if (result.isValid) {
  print('Move is legal');
} else {
  print('Error: ${result.error}');
}

final position = MoveValidationService.analyzePosition(chess);
print('Material: White ${position.whiteMaterial} vs Black ${position.blackMaterial}');
```

---

#### 5. ErrorHandlerService
Centralized error handling and logging with Crashlytics integration.

**Location**: `lib/src/services/error_handler_service.dart`

**Key Methods**:
- `logError(ErrorContext context)` - Log an error with context
- `handleServiceError(String operationName, {error, stackTrace, userId})` → `String` (user-friendly message)
- `validateInput(String? input, {fieldName, minLength, maxLength})` → `String?` (error message or null)

**ErrorContext Class**:
```dart
class ErrorContext {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;  // info, warning, error, critical
  final String? userId;
  final String? context;
  final Map<String, dynamic>? metadata;
}
```

**Example**:
```dart
try {
  await someService.performAction();
} catch (e, st) {
  final userMessage = ErrorHandlerService.instance.handleServiceError(
    'User action failed',
    error: e,
    stackTrace: st,
    userId: userId,
  );
  showSnackBar(userMessage);
}
```

---

#### 6. CrashReportingService
Firebase Crashlytics integration for crash reporting.

**Location**: `lib/src/services/crash_reporting_service.dart`

**Key Methods**:
- `initialize({enableInDevMode = false})` - Initialize Crashlytics
- `recordException({error, stackTrace, context, metadata})` - Record handled exception
- `recordFatalException(...)` - Record fatal error
- `recordGameError({gameId, errorType, error, gameState})` - Record game-specific error
- `recordNetworkError({endpoint, statusCode, error})` - Record network error
- `setUserInfo({userId, email, name})` - Set user identification

**Example**:
```dart
await CrashReportingService.instance.recordGameError(
  gameId: 'game_123',
  errorType: 'MoveValidationFailed',
  error: exception,
  gameState: {'move': 'e2e4', 'fen': currentFen},
);
```

---

#### 7. AnalyticsService
Firebase Analytics event tracking.

**Location**: `lib/src/services/analytics_service.dart`

**Key Methods**:
- `logEvent(String eventName, {Map<String, Object>? parameters})`
- `logGameCompleted({gameId, gameType, duration, won, moveCount, ratingBefore, ratingAfter})`
- `logPuzzleSolved({puzzleId, difficulty, timeSpent})`
- `logMatchmakingStarted({timeControl, colorPreference})`
- `logMatchFound({gameId, waitTime})`
- `logScreenView({screenName, screenClass})`
- `setUserProperty({name, value})`
- `setUserId(String userId)`

**Example**:
```dart
await AnalyticsService.instance.logGameCompleted(
  gameId: 'game_123',
  gameType: 'online',
  duration: 600000, // milliseconds
  won: true,
  moveCount: 45,
  ratingBefore: 1600,
  ratingAfter: 1620,
);
```

---

### Provider Pattern (Riverpod)

#### Game Providers
```dart
// Get current game by ID
final gameByIdProvider = StreamProvider.family<GameModel?, String>((ref, gameId) async* {
  // Returns GameModel or null
});

// Get active games for current user
final activeGamesProvider = StreamProvider<List<GameModel>>((ref) async* {
  // Returns list of active games
});

// Get game history
final gameHistoryProvider = StreamProvider<List<GameModel>>((ref) async* {
  // Returns completed games
});
```

#### User Providers
```dart
// Get current user preferences
final userPreferencesProvider = FutureProvider<UserPreferences>((ref) async {
  // Returns user's settings
});

// Track theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  // Returns current theme
});
```

---

## Data Models

### GameModel
```dart
class GameModel {
  final String gameId;
  final String type;  // 'online', 'cpu', 'puzzle'
  final String status;  // 'active', 'completed'
  final String whitePlayerId;
  final String blackPlayerId;
  final int whiteRating, blackRating;
  final String currentFen;
  final List<Map<String, dynamic>> moves;
  final String? result;  // 'white_win', 'black_win', 'draw'
  final String? resultReason;
  final DateTime createdAt, startedAt;
  final DateTime? endedAt;
}
```

### UserPreferences
```dart
class UserPreferences {
  final String userId;
  final ThemeMode themeMode;  // light, dark, system
  final String language;  // 'en', 'ja'
  final bool soundEnabled;
  final bool notificationsEnabled;
  final int boardSize;  // 300-600px
  final bool showCoordinates;
  final String pieceStyle;  // 'default', 'wooden', 'classic'
  final String boardStyle;  // 'default', 'wooden', 'marble'
}
```

---

## Testing

### Integration Testing
Use `integration_test/helpers/test_helpers.dart` for integration tests:

```dart
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await TestHelpers.initializeFirebaseForTesting();
  });

  testWidgets('Test example', (WidgetTester tester) async {
    final user = await TestHelpers.createTestUser();
    await TestHelpers.signInTestUser(
      email: user.email,
      password: user.password,
    );
    
    // Your test code here
    
    await TestHelpers.signOutCurrentUser();
  });
}
```

### Performance Testing
See `integration_test/performance_test.dart` for performance benchmarks.

---

## Error Handling Best Practices

1. **Use ErrorHandlerService for consistent logging**:
```dart
ErrorHandlerService.instance.logError(ErrorContext(
  message: 'Operation failed',
  error: exception,
  stackTrace: stackTrace,
  severity: ErrorSeverity.error,
  context: 'GameService',
));
```

2. **Report critical errors to Crashlytics**:
```dart
await CrashReportingService.instance.recordFatalException(
  exception: error,
  context: 'Critical system error',
);
```

3. **Track analytics for user insights**:
```dart
await AnalyticsService.instance.logError(
  errorCode: 'GAME_LOAD_FAILED',
  errorMessage: 'Failed to load game $gameId',
);
```

---

## Firebase Collections

- **games** - Active and completed games
- **users** - User profiles and stats
- **user_preferences** - User settings
- **user_lesson_progress** - Lesson completion tracking
- **chess_lessons** - Lesson content
- **opening_explanations** - Opening library
- **tactics_patterns** - Tactical pattern library
- **strategy_guides** - Strategy content

---

## Performance Targets

- App startup: < 3 seconds
- Settings screen navigation: < 500ms
- Move execution: < 100ms
- Network request timeout: 10 seconds
- Firebase operation: < 2 seconds

---

**Last Updated**: September 11, 2026  
**Version**: 1.0.0
