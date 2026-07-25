// Activity and acquisition rules on the 9.7.0 baseline.
// Port of artifact-related surface from `src/data/rules/activityRules.ts`.

// Artifacts 2.0 perks are disabled in these activities (9.7.0).
const List<String> artifactDisabledActivities = [
  'Trials of Osiris',
  'Competitive Crucible',
];

bool isArtifactAllowed(String activity) {
  final normalized = activity.trim().toLowerCase();
  for (final blocked in artifactDisabledActivities) {
    if (normalized.contains(blocked.toLowerCase())) return false;
  }
  return true;
}

// Ops difficulty → fixed reward gear tier.
const Map<String, int> difficultyRewardTiers = {
  'Expert': 3,
  'Master': 4,
  'Grandmaster': 5,
  'Ultimate': 5,
};
