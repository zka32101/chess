# Phase U: Seasonal Rewards & Battle Pass System

## Overview

Phase U adds seasonal gameplay mechanics and battle pass progression to Chess Tactics Master. This phase introduces time-limited seasons with exclusive rewards, tiered battle pass systems (free and premium), event-based challenges, and seasonal leaderboards to drive recurring engagement and monetization.

## Architecture

### Core Services

#### 1. SeasonManagementService
Manages seasonal lifecycle, configuration, and progression.

**Key Methods:**
- `createSeason()` - Create new season with configuration
- `getCurrentSeason()` - Get active season details
- `getSeasonById()` - Retrieve specific season
- `completeSeason()` - Mark season as finished
- `getSeasonRewards()` - Get all rewards for season
- `getPlayerSeasonProgress()` - Get player's season data

**Performance Characteristics:**
- Season creation: <100ms (single write)
- Get current season: <50ms (cached query)
- Season completion: <500ms (batch updates)
- Player season progress: <200ms (indexed query)

**Data Classes:**
- `Season` - Season details, dates, configuration, status
- `SeasonConfig` - Season settings and reward structure
- `PlayerSeasonProgress` - Player's progress for current season

#### 2. BattlePassService
Manages battle pass progression and rewards.

**Key Methods:**
- `createBattlePass()` - Initialize battle pass for season
- `getBattlePass()` - Get battle pass details
- `getPlayerBattlePassProgress()` - Player's pass progress
- `claimBattlePassReward()` - Claim battle pass milestone reward
- `getBattlePassTiers()` - Get all tiers with rewards
- `upgradeToPremiumPass()` - Unlock premium rewards

**Performance Characteristics:**
- Get battle pass: <100ms (single document)
- Get player progress: <150ms (indexed query)
- Claim reward: <200ms (update + notification)
- Battle pass upgrade: <150ms (single write)

**Data Classes:**
- `BattlePass` - Battle pass configuration with tiers
- `BattlePassTier` - Individual tier with rewards
- `PlayerBattlePassProgress` - Player's progression state
- `BattlePassReward` - Reward definition and claim status

#### 3. SeasonChallengeService
Manages seasonal challenges and event-based objectives.

**Key Methods:**
- `getChallenges()` - Get all active challenges
- `getPlayerChallengeProgress()` - Player's challenge progress
- `completeChallenge()` - Mark challenge as completed
- `getChallengeTiers()` - Challenges by difficulty
- `getChallengeRewards()` - Rewards for completion
- `getEventChallenges()` - Time-limited event challenges

**Performance Characteristics:**
- Get challenges: <150ms (cached query)
- Get player progress: <200ms (aggregation)
- Complete challenge: <150ms (update + progress)
- Event challenges: <100ms (filtered query)

**Data Classes:**
- `Challenge` - Challenge definition with objectives
- `PlayerChallengeProgress` - Progress tracking
- `ChallengeReward` - Reward item and amount
- `EventChallenge` - Time-limited challenge

#### 4. SeasonalRewardService
Handles reward distribution and item management.

**Key Methods:**
- `getRewardsByType()` - Rewards filtered by category
- `distributeSeasonReward()` - Award season completion rewards
- `trackRewardClaim()` - Record reward claiming
- `getPlayerRewardHistory()` - Claimed rewards history
- `calculateSeasonEndRewards()` - Final rewards at season end
- `redeemRewardCode()` - Redeem promotional codes

**Performance Characteristics:**
- Get rewards: <100ms (cached)
- Distribute reward: <200ms (write + notification)
- Track claim: <150ms (log write)
- Redeem code: <200ms (validation + update)

**Data Classes:**
- `Reward` - Reward definition and metadata
- `RewardItem` - Individual item in reward
- `PlayerRewardHistory` - Record of claimed rewards
- `RewardCode` - Promotional code data

#### 5. SeasonalEventService
Manages time-limited events and special modes.

**Key Methods:**
- `getActiveEvents()` - Currently running events
- `getEventDetails()` - Event configuration and details
- `getPlayerEventProgress()` - Player's participation
- `participateInEvent()` - Join event
- `getEventLeaderboard()` - Event-specific rankings
- `getEventRewards()` - Event completion rewards

**Performance Characteristics:**
- Get active events: <100ms (cached)
- Get event details: <100ms (single read)
- Get player progress: <150ms (indexed)
- Get leaderboard: <300ms (sorted query)

**Data Classes:**
- `SeasonalEvent` - Event configuration and timeframe
- `EventParticipation` - Player's event engagement
- `EventLeaderboardEntry` - Player ranking in event

### Riverpod Providers

**Service Providers:**
- `seasonManagementServiceProvider` - Singleton service
- `battlePassServiceProvider` - Singleton service
- `seasonChallengeServiceProvider` - Singleton service
- `seasonalRewardServiceProvider` - Singleton service
- `seasonalEventServiceProvider` - Singleton service

**Season Providers:**
- `currentSeasonProvider()` - Active season details
- `seasonByIdProvider(seasonId)` - Specific season
- `playerSeasonProgressProvider(playerId)` - Player season data
- `allRewardsForSeasonProvider(seasonId)` - Season rewards

**Battle Pass Providers:**
- `battlePassProvider(seasonId)` - Battle pass config
- `playerBattlePassProvider(playerId, seasonId)` - Player progress
- `battlePassTiersProvider(seasonId)` - All tiers
- `claimedRewardsProvider(playerId, seasonId)` - Claimed items

**Challenge Providers:**
- `activeChallengesProvider()` - Current challenges
- `playerChallengeProgressProvider(playerId)` - Challenge tracking
- `challengeRewardsProvider(challengeId)` - Challenge rewards
- `eventChallengesProvider()` - Event-specific challenges

**Reward Providers:**
- `rewardsProvider(type)` - Rewards by category
- `playerRewardHistoryProvider(playerId)` - Claim history
- `seasonEndRewardsProvider(seasonId)` - Final rewards

**Event Providers:**
- `activeEventsProvider()` - Running events
- `eventDetailsProvider(eventId)` - Event info
- `playerEventProgressProvider(playerId, eventId)` - Participation
- `eventLeaderboardProvider(eventId)` - Rankings

**State Providers:**
- `battlePassClaimNotifierProvider` - Reward claiming state
- `challengeCompleteNotifierProvider` - Challenge completion
- `eventParticipationNotifierProvider` - Event joining

## Integration Points

### Phase T (Social & Community)
- Seasonal leaderboards override normal leaderboards
- Season end triggers reward distribution
- Event participation visible in activity feeds
- Achievement integration with season-specific badges

### Phase S (Tournaments)
- Seasonal tournaments with exclusive rewards
- Tournament results count toward season ranking
- Limited-time competitive events
- Season-exclusive tournament formats

### Phase R (Predictive Matchmaking)
- Matchmaking considers seasonal rating changes
- Event-specific difficulty adjustments
- Challenge-based opponent recommendations

### Phase Q (Specialized Analytics)
- Season statistics and trends
- Challenge completion analytics
- Battle pass engagement metrics
- Event performance data

### Phase P (Real-time Multiplayer)
- Season pass progression from game results
- Challenge completion from ranked matches
- Event-based game modes
- Seasonal rating reset mechanics

## Data Models

### Season
```dart
class Season {
  final String seasonId;
  final String name;
  final String description;
  final int seasonNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String status;              // upcoming, active, completed
  final String theme;               // seasonal theme
  final int maxLevel;               // max battle pass level
  final SeasonConfig config;
  final DateTime createdAt;
}
```

### BattlePassTier
```dart
class BattlePassTier {
  final int level;
  final String name;
  final String icon;
  final int experienceRequired;
  final List<BattlePassReward> freeRewards;
  final List<BattlePassReward> premiumRewards;
  final bool isLocked;
}
```

### PlayerBattlePassProgress
```dart
class PlayerBattlePassProgress {
  final String playerId;
  final String seasonId;
  final int currentLevel;
  final int currentExperience;
  final bool hasPremiumPass;
  final List<int> claimedFreeRewards;
  final List<int> claimedPremiumRewards;
  final DateTime purchasedAt;
}
```

### Challenge
```dart
class Challenge {
  final String challengeId;
  final String name;
  final String description;
  final String type;                // daily, weekly, seasonal, event
  final String objective;           // e.g., "Win 5 games"
  final int target;
  final String difficulty;          // easy, medium, hard
  final List<ChallengeReward> rewards;
  final DateTime startDate;
  final DateTime endDate;
}
```

### SeasonalEvent
```dart
class SeasonalEvent {
  final String eventId;
  final String name;
  final String description;
  final String type;                // tournament, challenge_rush, rating_boost
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final List<EventLeaderboardEntry> leaderboard;
  final List<SeasonalReward> rewards;
  final bool isActive;
}
```

## Firebase Collections

**Firestore Structure:**
```
seasons/{seasonId}
├── name: string
├── description: string
├── seasonNumber: int
├── startDate: timestamp
├── endDate: timestamp
├── status: string
├── theme: string
├── maxLevel: int
├── createdAt: timestamp
│
├── battle_pass/
│   ├── tiers/ (subcollection)
│   │   └── {level}
│   │       ├── name: string
│   │       ├── experienceRequired: int
│   │       ├── freeRewards: array
│   │       └── premiumRewards: array
│   │
│   └── player_progress/ (subcollection)
│       └── {playerId}
│           ├── currentLevel: int
│           ├── currentExperience: int
│           ├── hasPremiumPass: bool
│           ├── claimedRewards: array
│           └── purchasedAt: timestamp
│
├── challenges/ (subcollection)
│   └── {challengeId}
│       ├── name: string
│       ├── type: string
│       ├── objective: string
│       ├── target: int
│       ├── difficulty: string
│       ├── rewards: array
│       ├── startDate: timestamp
│       └── endDate: timestamp
│
└── events/ (subcollection)
    └── {eventId}
        ├── name: string
        ├── type: string
        ├── startDate: timestamp
        ├── endDate: timestamp
        ├── maxParticipants: int
        ├── leaderboard: array
        └── rewards: array

player_seasons/{playerId}
└── {seasonId}
    ├── currentLevel: int
    ├── totalExperience: int
    ├── seasonRating: int
    ├── challengesCompleted: array
    ├── eventsParticipated: array
    └── rewardsClaimed: array

reward_codes/
└── {codeId}
    ├── code: string
    ├── reward: map
    ├── maxRedemptions: int
    ├── currentRedemptions: int
    ├── expiresAt: timestamp
    └── isActive: bool
```

## Usage Examples

### Get Current Season
```dart
final season = await seasonService.getCurrentSeason();
print('Current season: ${season.name}');
print('Ends: ${season.endDate}');
```

### Get Battle Pass Progress
```dart
final progress = await battlePassService.getPlayerBattlePassProgress(
  playerId,
  seasonId,
);
print('Level: ${progress.currentLevel}');
print('Premium: ${progress.hasPremiumPass}');
```

### Complete Challenge
```dart
await challengeService.completeChallenge(playerId, challengeId);
final rewards = await challengeService.getChallengeRewards(challengeId);
```

### Join Event
```dart
await eventService.participateInEvent(playerId, eventId);
final leaderboard = await eventService.getEventLeaderboard(eventId);
```

## Performance Characteristics

| Operation | Time | Notes |
|-----------|------|-------|
| Get current season | <50ms | Cached |
| Get battle pass | <100ms | Single read |
| Get player BP progress | <150ms | Indexed |
| Complete challenge | <150ms | Single update |
| Claim reward | <200ms | Update + notification |
| Get active events | <100ms | Cached |
| Event leaderboard | <300ms | Sorted query |
| Distribute reward | <200ms | Batch update |

## Success Metrics

- **Season Retention**: 70%+ return rate for new seasons
- **Battle Pass Penetration**: 40%+ players upgrade to premium
- **Challenge Completion**: 60%+ daily active challenges completed
- **Event Participation**: 50%+ players join seasonal events
- **Reward Satisfaction**: 75%+ players find rewards valuable
- **Monetization**: 25%+ revenue from battle pass sales
- **Engagement Increase**: 30%+ higher engagement during events

## Next Steps

### Immediate
- Deploy season and battle pass services
- Create first season with sample data
- Test battle pass progression mechanics
- Monitor reward claim rates

### Future Enhancements
- **Dynamic Seasonal Events** - AI-generated event recommendations
- **Cosmetics & Skins** - Season-exclusive cosmetics
- **Season Pass Refinement** - Seasonal pass ability tuning
- **Trading Post** - Seasonal item marketplace
- **Prestige System** - Post-season progression
- **Legacy Challenges** - Recurring challenge rotations

---

**Phase U Status**: Ready for Implementation  
**Estimated Lines**: 1,800+ (services, providers, models, widgets)  
**Integration**: Phases P, Q, R, S, T

