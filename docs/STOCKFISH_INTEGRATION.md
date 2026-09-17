# Stockfish Engine Integration

**Status:** Implemented  
**Date:** 2026-09-17

## Why

The CPU opponent previously ran a hand-rolled minimax/alpha-beta engine
(`AIOpponentEngine`) synchronously on the UI thread inside
`CpuGameNotifier.makeAIMove()`. It searched only 2-4 ply deep and could
briefly block the UI during "hard" difficulty thinking.

Stockfish is a free, open-source, world-class chess engine. The
[`stockfish`](https://pub.dev/packages/stockfish) Flutter plugin bundles
native Stockfish binaries for Android/iOS/macOS/Windows/Linux and drives
them over UCI (Universal Chess Interface) via FFI/process, off the Dart UI
isolate.

## What changed

- **`pubspec.yaml`**: added `stockfish: ^1.7.0`.
- **`lib/src/services/stockfish_engine_service.dart`** (new): singleton
  wrapper exposing `initialize()`, `configureDifficulty()`, and
  `getBestMove(fen, {moveTimeMs, depth})`, all `async` and non-blocking.
- **`lib/src/providers/cpu_game_provider.dart`**: `CpuGameNotifier.makeAIMove()`
  now tries Stockfish first; if it throws (unsupported platform, e.g. Web,
  or plugin/init failure) it falls back permanently to the existing
  `AIOpponentEngine` for the rest of that session.

## How difficulty maps to strength

Instead of just capping search depth (which produces obviously weak,
inconsistent play), Stockfish's own strength limiter is used:

| Difficulty | UCI_Elo | Move time budget |
|-----------|---------|-------------------|
| Easy      | 800     | 300ms             |
| Medium    | 1500    | 800ms             |
| Hard      | 2200    | 2000ms            |

`UCI_LimitStrength=true` + `UCI_Elo=<n>` makes Stockfish deliberately play
at roughly that rating rather than always finding the objectively best
move, which feels more human than a depth-limited engine.

## Notes / follow-ups

- The `stockfish` plugin does not support Flutter Web; the fallback engine
  keeps web builds working.
- The engine process is a process-wide singleton (`StockfishEngineService.instance`)
  and is intentionally **not** disposed between games, avoiding the ~100-300ms
  cost of re-spawning the native process each game. It is only torn down if
  `dispose()` is called explicitly (e.g. app shutdown hook, not currently wired).
- Search time (`movetime`) is used instead of a fixed `depth` for Easy/Medium/Hard,
  so "hard" thinks longer/deeper without needing manual depth tuning.
- This environment has no Flutter SDK installed, so `flutter pub get` /
  `dart analyze` could not be run here — verify locally before release.
