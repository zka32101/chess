# Phase K: コミュニティ機能 & ソーシャル機能

## 概要

Phase K はプレイヤーランキング、ゲーム共有、アチーブメントシステム、ソーシャルチャレンジを実装し、Chess Tactics Masterを社会的学習プラットフォームに変革します。

---

## 1. プレイヤーランキングシステム

### RankingService
```dart
class RankingService {
  // グローバルランキング取得
  Future<List<PlayerRanking>> getGlobalRankings(int limit) {
    // Firestore から上位プレイヤーを取得
    // キャッシング機構: 5分ごとに更新
  }
  
  // 地域別ランキング取得
  Future<List<PlayerRanking>> getRegionalRankings(String region, int limit) {
    // 地域フィルター付きランキング
  }
  
  // フレンドランキング取得
  Future<List<PlayerRanking>> getFriendRankings(String userId) {
    // フレンドのみのランキング
  }
  
  // ユーザーランク位置取得
  Future<int> getUserRankPosition(String userId) {
    // ユーザーの現在の順位
  }
  
  // ランキング更新
  Future<void> updatePlayerRanking(String userId, GameResult result) {
    // ゲーム結果に基づいてランキング更新
  }
}
```

### データモデル
```dart
class PlayerRanking {
  final String userId;
  final String username;
  final int rating;
  final int rank;
  final int wins;
  final int losses;
  final double winRate;
  final String region;
  final DateTime updatedAt;
}

class RankingStatistics {
  final int totalPlayers;
  final double averageRating;
  final int topPlayerRating;
  final List<RatingDistribution> distribution;
}

class RatingDistribution {
  final String tier; // Bronze, Silver, Gold, Platinum, Diamond
  final int playerCount;
  final double percentage;
}
```

---

## 2. ゲーム共有システム

### GameSharingService
```dart
class GameSharingService {
  // ゲームを共有リンク生成
  Future<SharedGameLink> createShareableLink(String gameId) {
    // PGN + 分析結果をエンコード
    // 共有可能なリンク生成
  }
  
  // ゲーム共有をフレンドに送信
  Future<void> shareGameWithFriends(String gameId, List<String> friendIds) {
    // フレンドに通知を送信
  }
  
  // 公開ゲーム一覧取得
  Future<List<SharedGame>> getPublicGames(int limit) {
    // コミュニティで共有されたゲーム
  }
  
  // ゲーム埋め込みコード生成
  Future<String> generateEmbedCode(String gameId) {
    // ブログ等に埋め込み可能なHTML
  }
  
  // ゲームビューアー取得
  Future<GameViewerData> getGameViewerData(String gameId) {
    // PGN + 分析結果 + コメント
  }
}
```

### データモデル
```dart
class SharedGame {
  final String gameId;
  final String sharedBy;
  final String title;
  final String pgn;
  final List<MoveAnalysis>? analysis;
  final List<String> tags;
  final int viewCount;
  final DateTime sharedAt;
}

class SharedGameLink {
  final String gameId;
  final String shortCode;
  final String fullUrl;
  final DateTime expiresAt;
  final bool isPublic;
}

class GameComment {
  final String commentId;
  final String userId;
  final String username;
  final String content;
  final int moveNumber;
  final DateTime createdAt;
  final List<String> likes;
}
```

---

## 3. アチーブメントシステム

### AchievementService
```dart
class AchievementService {
  // ユーザーアチーブメント取得
  Future<List<UserAchievement>> getUserAchievements(String userId) {
    // ユーザーが獲得したすべてのバッジ
  }
  
  // アチーブメント定義一覧取得
  Future<List<AchievementDefinition>> getAllAchievements() {
    // 利用可能なすべてのアチーブメント
  }
  
  // アチーブメント進捗取得
  Future<AchievementProgress> getAchievementProgress(String userId, String achievementId) {
    // 特定アチーブメントの進捗
  }
  
  // アチーブメント未ロック確認
  Future<List<NearbyAchievement>> getNearbyAchievements(String userId) {
    // もうすぐ獲得できるアチーブメント
  }
  
  // アチーブメントアンロック（内部）
  Future<void> unlockAchievement(String userId, String achievementId) {
    // ユーザーがアチーブメント達成時に呼出
  }
}
```

### データモデル
```dart
class AchievementDefinition {
  final String achievementId;
  final String name;
  final String description;
  final String icon;
  final String tier; // Bronze, Silver, Gold, Platinum, Diamond
  final AchievementCondition condition;
  final int points;
  final bool isHidden; // 非表示アチーブメント
}

class UserAchievement {
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final int progressPercentage;
}

class AchievementCondition {
  final String type; // wins, rating, lessons_completed, etc
  final int targetValue;
  final String? category;
}

class NearbyAchievement {
  final AchievementDefinition achievement;
  final int currentValue;
  final int targetValue;
  final double progressPercentage;
}
```

### アチーブメント定義（60+種類）
- **初心者バッジ**: 最初の勝利、5勝達成
- **戦術マスター**: 100個のタクティクスパズル完了
- **開始理論家**: 50個のオープニングレッスン完了
- **レーティングマイルストーン**: 1000, 1200, 1400, 1600 ELO達成
- **連勝**: 5勝、10勝連続
- **ソーシャルバッジ**: フレンド追加、ゲーム共有
- **イベント限定**: 特別トーナメント勝利

---

## 4. ソーシャルチャレンジシステム

### ChallengeService
```dart
class ChallengeService {
  // チャレンジ作成
  Future<Challenge> createChallenge({
    required String creatorId,
    required String type, // puzzle, game, tournament
    required int targetCount,
    required Duration duration,
  }) {
    // チャレンジ生成・共有コード作成
  }
  
  // チャレンジ参加
  Future<void> joinChallenge(String userId, String challengeCode) {
    // ユーザーがチャレンジに参加
  }
  
  // チャレンジ進捗更新
  Future<void> updateChallengeProgress(String userId, String challengeId) {
    // ゲーム/パズル完了時に進捗更新
  }
  
  // チャレンジリーダーボード
  Future<List<ChallengeLeaderboard>> getChallengeLeaderboard(String challengeId) {
    // チャレンジの参加者ランキング
  }
  
  // チャレンジ報酬配布
  Future<void> distributeChallengeRewards(String challengeId) {
    // チャレンジ終了時に報酬配布
  }
}
```

### データモデル
```dart
class Challenge {
  final String challengeId;
  final String creatorId;
  final String type; // puzzle, game, tournament
  final String title;
  final String description;
  final int targetCount;
  final Duration duration;
  final DateTime createdAt;
  final DateTime endsAt;
  final String shareCode;
  final List<String> participantIds;
  final ChallengeStatus status;
}

class ChallengeParticipant {
  final String userId;
  final String username;
  final int progress;
  final int targetCount;
  final DateTime joinedAt;
}

class ChallengeLeaderboard {
  final int rank;
  final String userId;
  final String username;
  final int score;
  final int progress;
  final double completionPercentage;
}

class ChallengeReward {
  final String rewardId;
  final int points;
  final List<String> badges;
  final String? premiumBonus;
}

enum ChallengeStatus { active, completed, cancelled }
```

---

## 5. フレンド & ソーシャルネットワーク

### SocialNetworkService
```dart
class SocialNetworkService {
  // フレンド追加
  Future<void> addFriend(String userId, String friendId) {
    // フレンド要求を送信
  }
  
  // フレンド要求承認
  Future<void> acceptFriendRequest(String userId, String requesterId) {
    // フレンド要求承認
  }
  
  // フレンド一覧取得
  Future<List<Friend>> getFriends(String userId) {
    // ユーザーのフレンド一覧
  }
  
  // ソーシャルフィード取得
  Future<List<FeedItem>> getSocialFeed(String userId, int limit) {
    // フレンドのアクティビティ
  }
  
  // ユーザープロフィール表示
  Future<UserProfile> getUserProfile(String userId) {
    // 公開プロフィール情報
  }
}
```

### データモデル
```dart
class Friend {
  final String userId;
  final String username;
  final String photoUrl;
  final int rating;
  final bool isOnline;
  final DateTime lastSeen;
}

class FeedItem {
  final String feedId;
  final String userId;
  final String actionType; // game_played, achievement_unlocked, lesson_completed
  final String actionData;
  final DateTime createdAt;
}

class UserProfile {
  final String userId;
  final String username;
  final String bio;
  final String photoUrl;
  final int totalGames;
  final int wins;
  final double winRate;
  final int rating;
  final List<UserAchievement> achievements;
  final DateTime joinedAt;
}
```

---

## 6. Riverpodプロバイダー（35+）

### ランキングプロバイダー
```dart
final rankingServiceProvider = Provider((ref) => RankingService());

final globalRankingsProvider = FutureProvider.family<List<PlayerRanking>, int>(
  (ref, limit) => ref.watch(rankingServiceProvider).getGlobalRankings(limit),
);

final regionalRankingsProvider = FutureProvider.family<List<PlayerRanking>, (String, int)>(
  (ref, params) {
    final (region, limit) = params;
    return ref.watch(rankingServiceProvider).getRegionalRankings(region, limit);
  },
);

final userRankPositionProvider = FutureProvider.family<int, String>(
  (ref, userId) => ref.watch(rankingServiceProvider).getUserRankPosition(userId),
);

final friendRankingsProvider = FutureProvider.family<List<PlayerRanking>, String>(
  (ref, userId) => ref.watch(rankingServiceProvider).getFriendRankings(userId),
);
```

### アチーブメントプロバイダー
```dart
final achievementServiceProvider = Provider((ref) => AchievementService());

final userAchievementsProvider = FutureProvider.family<List<UserAchievement>, String>(
  (ref, userId) => ref.watch(achievementServiceProvider).getUserAchievements(userId),
);

final allAchievementsProvider = FutureProvider(
  (ref) => ref.watch(achievementServiceProvider).getAllAchievements(),
);

final nearbyAchievementsProvider = FutureProvider.family<List<NearbyAchievement>, String>(
  (ref, userId) => ref.watch(achievementServiceProvider).getNearbyAchievements(userId),
);

final achievementProgressProvider = FutureProvider.family<AchievementProgress, (String, String)>(
  (ref, params) {
    final (userId, achievementId) = params;
    return ref.watch(achievementServiceProvider).getAchievementProgress(userId, achievementId);
  },
);
```

### ゲーム共有プロバイダー
```dart
final gameSharingServiceProvider = Provider((ref) => GameSharingService());

final publicGamesProvider = FutureProvider.family<List<SharedGame>, int>(
  (ref, limit) => ref.watch(gameSharingServiceProvider).getPublicGames(limit),
);

final gameViewerDataProvider = FutureProvider.family<GameViewerData, String>(
  (ref, gameId) => ref.watch(gameSharingServiceProvider).getGameViewerData(gameId),
);
```

### ソーシャルネットワークプロバイダー
```dart
final socialNetworkServiceProvider = Provider((ref) => SocialNetworkService());

final friendsProvider = FutureProvider.family<List<Friend>, String>(
  (ref, userId) => ref.watch(socialNetworkServiceProvider).getFriends(userId),
);

final socialFeedProvider = FutureProvider.family<List<FeedItem>, (String, int)>(
  (ref, params) {
    final (userId, limit) = params;
    return ref.watch(socialNetworkServiceProvider).getSocialFeed(userId, limit);
  },
);

final userProfileProvider = FutureProvider.family<UserProfile, String>(
  (ref, userId) => ref.watch(socialNetworkServiceProvider).getUserProfile(userId),
);
```

### チャレンジプロバイダー
```dart
final challengeServiceProvider = Provider((ref) => ChallengeService());

final activeChallengesProvider = FutureProvider.family<List<Challenge>, String>(
  (ref, userId) => ref.watch(challengeServiceProvider).getUserActiveChallenges(userId),
);

final challengeLeaderboardProvider = FutureProvider.family<List<ChallengeLeaderboard>, String>(
  (ref, challengeId) => ref.watch(challengeServiceProvider).getChallengeLeaderboard(challengeId),
);
```

---

## 7. UIコンポーネント（Phase K用ウィジェット）

### ランキング表示
```dart
class RankingCard extends StatelessWidget {
  // プレイヤーランキングカード表示
  // アバター、ユーザー名、レーティング、順位
}

class RankingListView extends StatelessWidget {
  // ランキング一覧スクロール表示
  // フィルター機能（グローバル/地域/フレンド）
}
```

### アチーブメント表示
```dart
class AchievementBadge extends StatelessWidget {
  // アチーブメントバッジ表示
  // 取得済み/未取得の視覚的区別
}

class AchievementGrid extends StatelessWidget {
  // アチーブメントグリッド表示
  // 60+バッジのグリッド
  // 進捗インジケーター
}

class AchievementProgressCard extends StatelessWidget {
  // アチーブメント進捗カード
  // プログレスバー、達成条件表示
}
```

### ゲーム共有
```dart
class GameShareDialog extends StatelessWidget {
  // ゲーム共有ダイアログ
  // 共有リンク生成・コピー
}

class GameViewerWidget extends StatelessWidget {
  // ゲーム閲覧ウィジェット
  // PGN表示、コメント、分析結果
}
```

### ソーシャル
```dart
class FriendListCard extends StatelessWidget {
  // フレンド一覧カード
  // オンライン状態表示
}

class SocialFeedWidget extends StatelessWidget {
  // ソーシャルフィード表示
  // アクティビティタイムライン
}
```

### チャレンジ
```dart
class ChallengeCard extends StatelessWidget {
  // チャレンジカード表示
  // 参加者数、進捗、報酬
}

class ChallengeLeaderboardWidget extends StatelessWidget {
  // チャレンジランキング表示
  // リアルタイムスコア更新
}
```

---

## 8. Firebase統合

### Firestore コレクション
```
firestore/
├── rankings/
│   ├── global/ → {rating, wins, losses, region}
│   ├── regional/ → {region, players}
│   └── updates_log/ → {timestamp, changes}
│
├── achievements/
│   ├── definitions/ → {id, name, condition}
│   └── user_achievements/ → {userId, unlockedAt}
│
├── shared_games/
│   ├── games/ → {gameId, pgn, sharedBy, views}
│   └── comments/ → {gameId, comments[]}
│
├── challenges/
│   ├── active/ → {challengeId, status, participants}
│   └── leaderboards/ → {challengeId, scores[]}
│
├── social/
│   ├── friends/ → {userId, friendIds, requests}
│   ├── feed/ → {userId, feedItems[]}
│   └── user_profiles/ → {userId, publicData}
└── user_social_stats/
    └── {userId} → {totalFriends, challengesWon, etc}
```

---

## 9. Realtime Database (オプション)

```json
{
  "online_users": {
    "userId": {
      "lastSeen": "timestamp",
      "isOnline": true
    }
  },
  "challenge_progress": {
    "challengeId": {
      "userId": {
        "progress": 10,
        "lastUpdate": "timestamp"
      }
    }
  }
}
```

---

## 10. CloudFunctions

### ランキング更新関数
```javascript
// updatePlayerRanking()
// ゲーム結果に基づいてELOを計算・更新
```

### アチーブメント確認関数
```javascript
// checkAchievements()
// ユーザーアクティビティをチェック
// 条件達成時にアチーブメント付与
```

### チャレンジ終了関数
```javascript
// endChallenge()
// チャレンジ終了時に報酬配布
// ランキング更新
```

---

## 11. 成功メトリクス

### 採用率
- **ランキング表示**: DAU の 60%+
- **フレンド機能**: アクティブユーザーの 50%+
- **アチーブメント**: 70%+ 取得率（初心者向け）
- **ゲーム共有**: 30%+ ゲーム共有率

### エンゲージメント
- **フレンド追加**: ユーザーあたり平均 5+ フレンド
- **チャレンジ参加**: アクティブユーザーの 40%+
- **ソーシャルフィード**: DAU の 55%+

### ビジネスインパクト
- **リテンション向上**: D7 +15%、D30 +20%
- **セッション増加**: 平均 +2 セッション/日
- **ユーザー成長**: MoM +25% (オーガニック紹介経由)

---

## 12. 実装順序

### 週1: インフラストラクチャ
- RankingService (160 行)
- AchievementService (180 行)
- GameSharingService (140 行)
- Firestore スキーマ

### 週2: サービス & プロバイダー
- SocialNetworkService (150 行)
- ChallengeService (170 行)
- すべてのプロバイダー (400+ 行)

### 週3: UI & 統合
- ウィジェット実装 (500+ 行)
- Firebase 統合
- テスト & 検証

---

**Phase K Status**: Ready for Implementation  
**Estimated Duration**: 3-4 weeks  
**Priority**: High - Drives retention and social growth  
**Dependencies**: Phases A-J completion

