/**
 * Seeds the `achievements/definitions/all` Firestore collection that
 * lib/src/services/achievement_service.dart's AchievementService reads
 * from. Without this, getAllAchievements() always returns an empty list,
 * even once a user has actually met a milestone (unlockAchievement()
 * still writes the user's own unlocked-achievement doc; it's the
 * definitions -- name/description/icon/tier/points -- that need seeding).
 *
 * Requires Application Default Credentials for the target Firebase project,
 * e.g.:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node scripts/seedAchievements.js
 * or run after `gcloud auth application-default login` /
 * `firebase login` with the project selected via `firebase use <project>`.
 *
 * Usage: node scripts/seedAchievements.js [--project <firebaseProjectId>]
 */
const admin = require("firebase-admin");

const projectFlagIndex = process.argv.indexOf("--project");
const projectId =
  projectFlagIndex !== -1 ? process.argv[projectFlagIndex + 1] : undefined;

admin.initializeApp(projectId ? { projectId } : undefined);
const db = admin.firestore();

// These three ids are the only ones AchievementService._calculateCurrentProgress
// (and AchievementService.checkAndUnlockMilestones) know how to evaluate --
// keep this list in sync with that switch statement.
const achievements = [
  {
    achievementId: "first_win",
    name: "First Victory",
    description: "Win your first game",
    icon: "emoji_events",
    tier: "Bronze",
    condition: { type: "wins", targetValue: 1 },
    points: 10,
    isHidden: false,
  },
  {
    achievementId: "five_wins",
    name: "On a Roll",
    description: "Win 5 games",
    icon: "emoji_events",
    tier: "Silver",
    condition: { type: "wins", targetValue: 5 },
    points: 25,
    isHidden: false,
  },
  {
    achievementId: "puzzle_master",
    name: "Puzzle Master",
    description: "Solve 50 puzzles",
    icon: "extension",
    tier: "Gold",
    condition: { type: "puzzlesSolved", targetValue: 50 },
    points: 50,
    isHidden: false,
  },
];

async function seedAchievements() {
  const batch = db.batch();

  for (const achievement of achievements) {
    const ref = db
      .collection("achievements")
      .doc("definitions")
      .collection("all")
      .doc(achievement.achievementId);
    batch.set(ref, achievement);
  }

  await batch.commit();
  console.log(`Seeded ${achievements.length} achievement definitions.`);
}

seedAchievements()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Failed to seed achievements:", error);
    process.exit(1);
  });
