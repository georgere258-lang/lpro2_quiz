# Streak Engine – Official Contract (L Pro)

## Purpose
This document defines the official and sole source of truth for how
Streaks (currentStreak / bestStreak) are calculated and stored in L Pro.

The goal is to keep the logic centralized, predictable, and safe.

---

## Source of Truth
- QuizRepositoryImpl is the ONLY place allowed to calculate or update streaks.
- UI layers (StatsScreen, cards, widgets) are read-only.
- Firestore Rules must NOT contain any streak business logic.

---

## Definitions

### currentStreak
Number of consecutive successful rounds for a given league.

### bestStreak
The maximum value ever reached by currentStreak for that league.

Both values are stored per league inside:


user_stats/{uid}/{leagueKey}

---

## Update Rules (Per Round)

### Successful Round
A round is considered successful when:
- correctAnswers == totalQuestions (perfect round)

On success:
- currentStreak += 1
- bestStreak = max(bestStreak, currentStreak)

---

### Failed Round
If the round is not successful:

On failure:
- currentStreak = 0
- bestStreak remains unchanged

---

## Data Contract (user_stats)

Each league map may contain:

- roundsPlayed
- totalQuestions
- correctAnswers
- wrongAnswers
- totalPoints
- currentStreak
- bestStreak

Missing fields must always be treated as 0.

---

## Forbidden (Non-Goals)
The following are NOT allowed:
- Calculating streaks in UI
- Resetting streaks from UI
- Implementing streak logic in Firestore Rules
- Writing streaks from any place other than the Repository

---

## Backward Compatibility
- Existing users may already have streak values.
- Repository logic must be null-safe.
- Absence of streak fields is valid.

---

## Change Policy
Any change to streak rules must:
1. Update this document
2. Be reviewed before merging
3. Preserve existing user data

---

Status: Active & Approved  
Applies from: safe-schema-clean-v1