# Achievements & Badges System (Contract)

## Purpose
This document defines the official **Achievements / Badges** system for L Pro.
It is a **design-time contract only** — no UI or logic must be implemented
outside the rules defined here.

The goal is to:
- Lock league behavior (Stars / Pros / Free Play)
- Prevent random badge logic across UI layers
- Ensure long-term stability and predictability

---

## Source of Truth
**ONLY** the Quiz / Game Repository layer is allowed to:
- Evaluate achievement conditions
- Grant or revoke badges
- Update achievement-related fields in `user_stats`

UI and Screens are **read-only**.

---

## Badge Categories

### 1. League Badges
Earned through league-specific progress.

| League | Examples |
|------|---------|
| Stars | First Win, 10 Rounds, Accuracy ≥ 80% |
| Pros  | Pro Debut, 5 Win Streak, Top 10 Entry |
| Free Play | Training Starter, Consistency Badge |

---

### 2. Performance Badges
Based on measurable skill.

- Accuracy milestones (70% / 80% / 90%)
- Best streak thresholds
- Zero-wrong-answer rounds

---

### 3. Commitment Badges
Behavioral & time-based.

- Daily play (7 / 14 / 30 days)
- Weekly consistency
- Comeback after inactivity

---

## Award Rules
Badges must:
- Be **monotonic** (once earned, never removed)
- Be **idempotent** (same condition won’t re-award)
- Be evaluated **after** successful quiz persistence
- Never depend on UI state or client timers

---

## Data Contract (Firestore)

All achievements are stored under:

user_stats/{uid}/achievements

### Example Structure
```json
{
  "achievements": {
    "stars_first_win": {
      "earnedAt": "timestamp"
    },
    "pros_accuracy_80": {
      "earnedAt": "timestamp"
    }
  }
}


Rules:

Key = stable string identifier
Value = metadata object (minimum: earnedAt)
No counters, no booleans
Non-Goals (Strictly Forbidden)
❌ Awarding badges from UI
❌ Using Cloud Functions for achievements
❌ Removing or downgrading earned badges
❌ Storing achievements in users collection
Change Policy
Any change to this system requires:
Updating this document
Creating a new git tag
Explicit review before code changes
Status
LOCKED — DESIGN CONTRACT ONLY