# Chess Tactics Master - Architecture Guide

## Project Structure

```
lib/
├── main.dart                           # Entry point
├── firebase_options.dart               # Firebase configuration
└── src/
    ├── app.dart                        # Main app widget & routing
    ├── screens/                        # UI Screens
    │   ├── auth/                       # Authentication screens
    │   ├── home/                       # Home & main menu
    │   ├── game/                       # Game play screens
    │   ├── puzzle/                     # Puzzle screens
    │   └── settings/                   # Settings & preferences
    ├── services/                       # Business logic layer
    │   ├── auth_service.dart           # Firebase auth
    │   ├── firebase_service.dart       # Firestore operations
    │   ├── chess_engine_service.dart   # Chess logic
    │   ├── fen_calculator_service.dart # FEN calculations
    │   ├── draw_detection_service.dart # Draw detection
    │   ├── move_validation_service.dart# Move validation
    │   ├── error_handler_service.dart  # Error handling
    │   ├── crash_reporting_service.dart# Crash reporting
    │   ├── analytics_service.dart      # Analytics tracking
    │   └── ...
    ├── models/                         # Data structures
    │   ├── game.dart
    │   ├── user.dart
    │   ├── puzzle.dart
    │   └── ...
    ├── providers/                      # Riverpod state management
    │   ├── auth_provider.dart
    │   ├── game_provider.dart
    │   ├── user_preferences_provider.dart
    │   └── ...
    ├── widgets/                        # Reusable UI components
    │   ├── chess_board.dart
    │   ├── game_card.dart
    │   └── ...
    └── utils/                          # Utility functions
        ├── constants.dart
        └── validators.dart

integration_test/
├── helpers/
│   └── test_helpers.dart              # Test utilities
├── game_flow_test.dart
├── performance_test.dart
└── ...
```

---

## Architecture Patterns

### 1. Service Layer Architecture

All business logic is encapsulated in services that are independent of UI:

```
UI Layer (Screens)
    ↓
Riverpod Providers (State Management)
    ↓
Services (Business Logic)
    ↓
Firebase/External APIs
```

**Benefits**:
- Clean separation of concerns
- Easy to test
- Reusable business logic
- Framework agnostic services

---

### 2. State Management with Riverpod

Riverpod provides reactive, dependency-injection-based state management:

```dart
// Define a service provider
final gameServiceProvider = Provider((ref) {
  return GameService(FirebaseFirestore.instance);
});

// Use in widgets
class GameScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameService = ref.watch(gameServiceProvider);
    final activeGames = ref.watch(activeGamesProvider);
    
    return activeGames.when(
      data: (games) => GameList(games: games),
      loading: () => LoadingIndicator(),
      error: (err, st) => ErrorWidget(error: err),
    );
  }
}
```

**Provider Types**:
- `Provider` - Synchronous value (services, constants)
- `StateProvider` - Mutable state
- `FutureProvider` - Async single-value (one-time fetch)
- `StreamProvider` - Async stream (real-time updates)

---

### 3. Error Handling Strategy

Multi-layer error handling ensures robust error management:

**Layer 1: Service Level**
```dart
class GameService {
  Future<void> makeMove(...) async {
    try {
      // Validation
      // Business logic
      // Firebase call
    } catch (e, st) {
      ErrorHandlerService.instance.logError(ErrorContext(
        message: 'Move execution failed',
        error: e,
        stackTrace: st,
        context: 'GameService.makeMove',
      ));
      rethrow;
    }
  }
}
```

**Layer 2: Provider Level**
```dart
final makeGameMoveProvider = FutureProvider.family<void, (String, String)>((ref, move) async {
  try {
    final gameService = ref.watch(gameServiceProvider);
    await gameService.makeMove(move.$1, move.$2);
  } catch (e) {
    ErrorHandlerService.instance.handleServiceError('Move failed', error: e);
  }
});
```

**Layer 3: Widget Level**
```dart
class GameBoard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(makeGameMoveProvider('e2', 'e4')).when(
      data: (_) => GameUpdated(),
      error: (err, st) => showErrorSnackBar(err.toString()),
      loading: () => LoadingIndicator(),
    );
  }
}
```

---

### 4. Firebase Integration Pattern

All Firebase operations go through services for consistency:

```dart
class GameService {
  final FirebaseFirestore _firestore;
  
  Future<GameModel> createGame(...) async {
    try {
      final gameData = {...};
      final gameRef = await _firestore.collection('games').add(gameData);
      return GameModel.fromJson({...gameData, 'gameId': gameRef.id});
    } on FirebaseException catch (e) {
      await CrashReportingService.instance.recordFirebaseError(
        operation: 'createGame',
        error: e,
      );
      rethrow;
    }
  }
}
```

**Best Practices**:
- Use strongly-typed models
- Handle Firebase exceptions specifically
- Log all significant operations
- Never expose Firebase directly to UI

---

### 5. Testing Architecture

**Unit Tests** - Test individual services:
```dart
test('ChessEngineService.isLegalMove', () {
  final chess = ChessEngineService();
  chess.initGame();
  expect(chess.isLegalMove('e2', 'e4'), true);
  expect(chess.isLegalMove('e2', 'e5'), false);
});
```

**Widget Tests** - Test individual widgets:
```dart
testWidgets('GameBoard renders correctly', (tester) async {
  await tester.pumpWidget(GameBoard(fen: 'starting position'));
  expect(find.byType(CustomPaint), findsOneWidget);
});
```

**Integration Tests** - Test complete flows:
```dart
testWidgets('Complete game flow', (tester) async {
  await TestHelpers.initializeFirebaseForTesting();
  // Test: sign-in, create game, make move, complete game
});
```

---

## Design Patterns Used

### 1. Singleton Pattern
```dart
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._();
  static ErrorHandlerService get instance => _instance;
  ErrorHandlerService._();
}

// Usage
ErrorHandlerService.instance.logError(...);
```

### 2. Provider Pattern (Dependency Injection)
```dart
final databaseProvider = Provider((ref) => FirebaseFirestore.instance);
final gameServiceProvider = Provider((ref) {
  return GameService(ref.watch(databaseProvider));
});
```

### 3. Builder Pattern
```dart
class GameModel {
  final String gameId;
  // ... fields
  
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      gameId: json['gameId'],
      // ... construct from JSON
    );
  }
  
  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    // ... fields to JSON
  };
}
```

### 4. Observer Pattern (Streams)
```dart
// Service exposes stream
Stream<GameModel> watchGame(String gameId) {
  return _firestore.collection('games')
      .doc(gameId)
      .snapshots()
      .map((doc) => GameModel.fromJson(doc.data()!));
}

// Provider wraps stream
final gameStreamProvider = StreamProvider.family<GameModel?, String>((ref, gameId) {
  return GameService.instance.watchGame(gameId);
});
```

---

## Data Flow Architecture

### Game Lifecycle

```
User Action (Tap to Make Move)
         ↓
Widget Event Handler
         ↓
Call gameServiceProvider.makeMove()
         ↓
GameService validates move & saves to Firebase
         ↓
Firebase updates game document
         ↓
StreamProvider gets update
         ↓
Widget rebuilds with new state
         ↓
UI reflects move
```

### Real-time Synchronization

Games use Firestore snapshots for real-time updates:

```dart
Stream<GameModel> _watchGame(String gameId) {
  return firestore
      .collection('games')
      .doc(gameId)
      .snapshots()
      .map((snapshot) => GameModel.fromJson(snapshot.data()!));
}

// Provider ensures real-time updates
final gameProvider = StreamProvider.family<GameModel?, String>((ref, gameId) {
  return _watchGame(gameId);
});
```

---

## Performance Optimization Strategies

### 1. Provider Caching
```dart
// This provider caches its result
final expensiveComputation = FutureProvider((ref) async {
  return await computeExpensiveResult();
});

// Refresh when needed
ref.refresh(expensiveComputation);
```

### 2. Selective Rebuilding
```dart
// Only rebuilds when activeGames changes
final activeGames = ref.watch(activeGamesProvider);

// Doesn't rebuild the GameCard for other changes
class GameCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watches what it needs
    final game = ref.watch(gameByIdProvider(gameId));
  }
}
```

### 3. Lazy Loading
```dart
// Stream only fetches 50 games initially
final gameHistoryProvider = StreamProvider<List<GameModel>>((ref) async* {
  final query = firestore
      .collection('games')
      .where('userId', isEqualTo: userId)
      .limit(50);
  // Implement pagination for more
});
```

---

## Security Architecture

### 1. Authentication
- Firebase Authentication (Email, Google, Apple)
- User UID used for all data associations
- Secure token refresh handled by Firebase

### 2. Firestore Security Rules
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Games can be read by players, written by service
    match /games/{gameId} {
      allow read: if request.auth.uid in resource.data.playerIds;
      allow write: if request.auth.uid != null;
    }
  }
}
```

### 3. Sensitive Data Handling
- Never log sensitive data (passwords, PII)
- Use Firebase Functions for critical operations
- Validate all user input server-side

---

## Monitoring and Analytics

### Event Tracking
```dart
// Track significant events
await AnalyticsService.instance.logGameCompleted(
  gameId: gameId,
  result: 'win',
  duration: elapsedTime,
);
```

### Error Tracking
```dart
// Critical errors go to Crashlytics
await CrashReportingService.instance.recordFatalException(
  exception: error,
  context: 'CriticalGameError',
);
```

### Performance Monitoring
Integration tests track:
- App startup time (target: <3s)
- Screen navigation (target: <500ms)
- Move execution (target: <100ms)

---

## Development Workflow

### Adding a New Feature

1. **Design Data Model**
   - Create model in `models/`
   - Implement `fromJson`/`toJson`

2. **Implement Service**
   - Create service in `services/`
   - Add error handling
   - Write unit tests

3. **Create Providers**
   - Add to `providers/`
   - Define appropriate provider type
   - Add caching strategy if needed

4. **Build UI**
   - Create screen in `screens/`
   - Use providers with `ConsumerWidget`
   - Add error handling UI

5. **Integration Testing**
   - Add integration test
   - Test complete flow
   - Verify performance

---

## Dependencies

### Core
- `flutter_riverpod` - State management
- `firebase_core` - Firebase initialization
- `cloud_firestore` - Database
- `firebase_auth` - Authentication
- `firebase_analytics` - Analytics
- `firebase_crashlytics` - Error tracking
- `chess` - Chess logic engine

### UI
- `google_fonts` - Typography
- `lottie` - Animations

### Development
- `flutter_test` - Testing
- `integration_test` - Integration testing
- `build_runner` - Code generation

---

**Last Updated**: September 11, 2026  
**Phase**: D - Device Testing  
**Status**: Complete
