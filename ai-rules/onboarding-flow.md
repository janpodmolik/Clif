# Uuumi Onboarding Flow — v5

## Overview

11 story screens + 2 post-onboarding sheets. Every permission request is framed within the narrative. No screen feels like a form. The user meets their pet, learns the mechanics by doing, and places the pet on the island before seeing any paywall or auth prompt.

**Core principles:**
- Bond before rules — Uuumi is introduced well before any settings/limits
- Mechanics taught by doing — slider + lock are "feel it in your body" demos
- No early paywall/auth — placing the pet first is the emotional priority
- Every permission has a story reason
- Every data collection moment feels like a choice, not a form
- Respect Reduce Motion, provide tap fallbacks for drag interactions

**Progress indicator:** Subtle dot indicator (11 dots) visible on all onboarding screens to reduce "am I watching an ad?" anxiety.

---

## ACT 1: THE STORY (Screens 1-2)

*Pure emotion. No interaction beyond "next" (except tap on screen 2). Under 20 seconds total.*

### Screen 1 — "The Island"

**Visual:** An empty floating island in the sky. Calm, serene. Soft ambient light. Clouds drifting slowly. Uses the existing `IslandBase` component (rock + grass) but with no pet, no wind, no UI elements. Just the island floating in space.

**Text:**
> "Somewhere, a tiny island floats in the sky..."
> "A peaceful place, untouched by the chaos below. But it's empty."

**Interaction:** Tap anywhere or swipe to continue.

**Reuses:** `IslandBase` component.

---

### Screen 2 — "Meet Uuumi"

**Visual:** The blob appears on the island with the idle breathing animation (existing `scaleEffect` oscillation). Small, curious, looking around. The island feels less empty now.

**Text:**
> "Meet Uuumi."
> "A tiny creature looking for somewhere to grow. Somewhere to evolve into something extraordinary."

**Interaction:** Small pulsing "Tap" hint near the blob (fades after first tap or auto-reaction at 3s). User can tap the blob — it does a wiggle/jiggle reaction with haptic feedback. First moment of physical connection.

**Reuses:** `IslandBase`, `PetAnimationEffect` (idle breathing), `PetReactionType` animations + haptics.

---

## ACT 2: THE DEMO (Screens 3-7)

*Hands-on. The user experiences the mechanics. This is what no other screen time app does.*

### Screen 3 — "The Wind" (Wind Mechanic + Screen Time Permission)

**Visual:** The island with the blob from screen 2. As text progresses, wind lines gradually appear and intensify. The blob begins to sway, transitions to scared face, and gets pushed toward the edge of the island. Wind stays at medium intensity after the animation settles.

**Text (typewriter, 3 phases synced with wind animation):**
> "The wind comes from your screen time."
> "The more you scroll, the stronger it gets."
> "Let's see what Uuumi is up against."

**Tone note:** Use "blown away", never "gone" or "gone forever." Keep stakes clear but not punishing.

**Privacy line near CTA:** "Your data stays on your device. Always."

**CTA button:** "Show my screen time" → Triggers `FamilyControls` / Screen Time authorization prompt from iOS.

**IMPORTANT — Permission is mandatory.** Without Screen Time access, the app's core feature doesn't work. If the user denies:
- Show prominent card with warning icon: "Screen Time access is required" + "Without it, there's no wind, no protection, no evolution."
- "Try again" button (re-prompts or directs to Settings if iOS won't re-prompt)
- No way to proceed until permission is granted

**After permission granted:** Continue button appears. Data reveal happens on the next screen.

**Reuses:** `IslandBase`, `WindLinesView`, `PetAnimationEffect` (wind shader), scared face asset swap.

---

### Screen 4 — "Screen Time Data" (Data Reveal)

**Visual:** Same island scene with wind at gentle intensity (carried over from screen 3). The screen time data animates in from the bottom.

**Text:**
> "This is what Uuumi is up against."

**Data display:** Horizontal scrolling carousel via embedded `DeviceActivityReport` with `.onboardingOverview` context:
- Daily average screen time at top ("Daily average" label + large bold time)
- Horizontal scroll of app icons (60×60 via scaleEffect) with duration below each — no app names
- Semi-transparent material background card

**Technical approach:** Uses `OnboardingActivityReport` scene in the DeviceActivityReport extension. The carousel view is `OnboardingActivityView` with horizontal `ScrollView`.

**Reuses:** `IslandBase`, `WindLinesView`, `DeviceActivityReport` extension pattern.

---

### Screen 5 — "Feel The Wind" (The Slider)

**Visual:** Full island scene — island, blob on top, wind lines. A slider at the bottom of the screen. Everything uses real existing components with real `WindConfig` interpolation driving all parameters.

**As the user drags the slider from left to right:**
- **0-5% (WindLevel.none):** No wind. Blob happy, idle breathing. Text: "A calm day."
- **5-50% (WindLevel.low):** Light wind lines appear, gentle sway. Blob still happy. Text: "A little breezy..."
- **50-80% (WindLevel.medium):** Wind intensifies, blob mood changes to neutral, sway increases. Text: "Uuumi is struggling."
- **80-100% (WindLevel.high):** Strong wind, blob switches to sad then scared face, maximum sway, blob pushed toward island edge. Text: "Too much. Uuumi can't hold on."

**No blow-away animation.** The scared face at the edge is enough. Blow away stays reserved for real gameplay.

**Text at top:**
> "This is what happens when you scroll."

**Reuses:** `IslandView`, `WindLinesView`, `PetAnimationEffect` (Metal shader), `WindConfig` interpolation, scared face asset swap.

---

### Screen 6 — "The Lock" (Core Mechanic)

**Visual:** Same island scene from screen 5, but now wind is at medium intensity (blob swaying, looking worried). A floating lock button appears at the bottom — styled like the existing `HomeFloatingLockButton`.

**Text:**
> "But you have the power to stop it."
> "Tap the lock."

**Interaction:** User taps the lock button → Wind lines fade out, blob sway decreases to zero, blob mood returns to happy. Subtle glow or particle effect around the lock to show it "activated."

**After tapping:**
> "The wind stops. Uuumi is safe."
> "This isn't about willpower. It's about protecting something you care about."
> "When the wind rises, you can lock in and calm it."

**Note:** Wording uses "you can" (choice/empowerment), not imperative "tap the lock whenever" (instruction/obligation).

**Reuses:** `HomeFloatingLockButton` style, `IslandView`, `WindLinesView`, `PetAnimationEffect`.

---

### Screen 7 — "Uuumi Can Call For You" (Notification Permission)

**Visual:** The island, blob looking slightly worried. A mock notification slides down from the top of the screen (custom-styled UI element, not a real iOS notification):

> **Uuumi**
> The wind is getting stronger... Come help me!

Maybe a second mock notification fades in:
> **Uuumi**
> I'm scared. The wind won't stop...

The blob's speech bubble shows a worried emoji, synced with the notification.

**Text:**
> "You can't always be here. But Uuumi can reach you."
> "Let it call for help when the wind rises."

**CTA button:** "Let Uuumi reach me" → Triggers iOS notification permission prompt.

**If denied:** Show brief line "You can always enable this later in Settings." Then continue. Not mandatory — app works without notifications.

**Reuses:** `IslandView`, speech bubble system.

**New UI needed:** Mock notification component styled to look like an iOS notification.

---

## ACT 3: SETUP (Screens 8-11)

*Configuration that feels like commitment, not a form. Each step has narrative framing.*

### Screen 8 — "Evolution" (Aspiration + Premium Seed)

**Visual:** The blob in the center. The plant evolution path is fully visible — showing phases 1 -> 2 -> 3 -> 4, getting progressively more elaborate and beautiful. Other essences (crystal, flame, water) are shown as beautiful but clearly marked as premium — visible designs, not hidden behind silhouettes. The user can see what they could unlock.

**Text:**
> "Keep Uuumi safe, and it evolves."
> "Every day you protect it, it grows into something new."

**For the plant path (free):**
> "Your first path: the Plant Essence."

**For locked paths:**
> "Unlock new essences with Premium."

**Interaction:** User can tap/swipe through the evolution paths to preview them. Tapping a locked essence shows a brief "Unlock with Premium" indicator.

**Design note:** Be honest about the paywall. Don't pretend locked essences are "undiscovered" or "rare" — users feel tricked when they realize later. Show beautiful content and be clear it's premium. Desire is planted here, conversion happens on screen 13.

**Reuses:** Evolution phase assets (plant), essence assets.

**New assets needed:** Preview assets/silhouettes for crystal, flame, water evolution paths (even if simplified).

---

### Screen 9 — "How Tough Are You?" (Wind Preset)

**Visual:** Three cards/options, each showing the blob at different wind intensities.

**Option 1 — Gentle:**
Visual: Light breeze, blob smiling.
> "20 minutes of scrolling before the wind maxes out. For those just starting out."

**Option 2 — Balanced (recommended, highlighted):**
Visual: Moderate wind, blob slightly concerned.
> "12 minutes. A fair fight. Most players start here."

**Option 3 — Intense:**
Visual: Strong wind, blob scared.
> "8 minutes. Full power. Only for the brave."

**Text at top:**
> "How tough should the wind be?"

**Note:** Minute values match actual `WindPreset` config (gentle=20min, balanced=12min, intense=8min).

---

### Screen 10 — "Name Your Pet" (Ownership)

**Visual:** The blob in the center, looking up at the user expectantly. Idle breathing. Warm, intimate — no wind, just the user and the blob.

**Text:**
> "Every creature needs a name."

**Input:** Text field for pet name (required). Simple, clean, centered.

**Optional:** Purpose field below — "What is [name] protecting you from?" with placeholder like "Social Media" or "Doomscrolling." Not required.

**When the user types a name:** The blob does a happy reaction (wiggle/bounce) as if it recognized its name.

**Reuses:** `PetReactionType` animations.

---

### Screen 11 — "Place On The Island" (The Drop)

**Visual:** The existing `PetDropStep` from the `CreatePetMultiStep` flow. Island visible in the background with `PetDropZone` glowing softly. Summary card at the bottom shows pet name, selected apps, and preset. Blob sits on the card, ready to be dragged.

**Text:**
> "Give [name] a home."

**Hint text:** "Hold & drag to the island" — visible from the start for discoverability.

**Interaction:** User drags the blob from the summary card onto the island:
- `BlobDragPreview` follows the finger with spring animation
- Haptic intensity increases as blob approaches drop zone
- Drop zone highlights when blob is near
- On successful drop -> landing glow, success haptic, pet is alive on the island
- On miss -> blob springs back with error haptic, try again

**Accessibility fallback:** After 2-3 failed drag attempts, show a "Tap to place" button below the island. Important for motor accessibility and App Store review.

**This is the emotional climax of the entire onboarding.** The pet lands. It's home. It breathes.

**Transition:** Fade to the real home screen with the pet on the island.

**Reuses:** `PetDropStep`, `BlobDragPreview`, `DragPortalSheet`, `PetDropZone`, `IslandView`.

---

## POST-ONBOARDING (Screens 12-13)

*These appear after the home screen loads. Sheets/modals, not full-screen onboarding pages.*

### Screen 12 — "Keep [Name] Safe" (Authentication)

**Appears:** ~1.5 seconds after home screen loads. Slides up as a sheet.

**Visual:** The island with the pet visible behind the sheet (sheet doesn't cover the full screen). Subtle cloud/shield icon.

**Text:**
> "[Name] is home. Keep it that way."
> "If you switch phones or reinstall, you could lose your progress. Save [name]."

**Options:**
- **[Sign in with Apple]** <- primary, one tap + Face ID
- **[Sign in with Google]**
- "I'll risk it" <- small text link at bottom. Honest, not guilt-tripping.

**If signed in:** Brief confirmation ("Saved!"), sheet dismisses.
**If skipped:** Sheet dismisses. Re-prompt later from settings or after meaningful events (first evolution, day 3, etc.).

**Technical note:** Authentication is NOT required for any features. Without auth, all data is local-only. With auth, data syncs to Supabase (cross-device, recovery). Premium works without auth (StoreKit handles purchases via Apple ID).

---

### Screen 13 — "Give [Name] The Best Start" (Premium / 7-Day Trial)

**Appears:** After auth sheet dismisses (or after skip). Slides up as a sheet.

**Visual:** Warm, aspirational. Pet on island visible behind the sheet.

**Lead with emotion (primary block):**
> "Discover every evolution path."

Show all essences (plant unlocked, crystal/flame/water as premium) with glimpses of their phase 4 evolved forms. This is about the long-term journey across multiple pets — each pet gets one essence, but across many pets the user discovers all paths.

**Supporting features (secondary, smaller):**
- **Committed Breaks** — "Lock in. Stay disciplined. Earn coins." (Lock icon + timer + coins)
- **Island Customization** — "Make your world unique." (Island variant previews)

**Timeline:**
> Today -> Get all Premium features free
> Day 5 -> Reminder before trial ends
> Day 7 -> Paid membership starts. Cancel anytime before.

**Pricing:** [X] Kc/year ([X] Kc/month)

**CTA:** "Start free trial" <- primary button
**Below:** "Maybe later" <- clear, no guilt. "No charge today. Cancel anytime."

**If subscribed:** Confirmation animation, sheet dismisses.
**If skipped:** Sheet dismisses. Premium re-offered contextually: when user encounters locked essence, from settings, etc.

---

## New Assets Needed

1. **Evolution path previews** — Visual representations of crystal, flame, water evolution paths (at least silhouettes or phase 4 forms). For screens 8 and 13.
2. **Mock notification UI** — Custom component styled to look like an iOS notification. For screen 7.
3. No new assets needed for Screen 4 (data reveal) — uses existing `DeviceActivityReport` extension.

## Existing Components Reused

- `IslandBase` / `IslandView` (screens 1, 2, 3, 4, 5, 6, 7, 11)
- `PetAnimationEffect` + Metal shader (screens 2, 3, 4, 5, 6)
- `WindLinesView` (screens 3, 4, 5, 6)
- `PetReactionType` animations + haptics (screens 2, 10)
- Scared face asset swap (screens 3, 5)
- `WindConfig` interpolation (screen 5)
- `HomeFloatingLockButton` style (screen 6)
- `BlobDragPreview` + drag system (screen 11)
- `DeviceActivityReport` extension / `OnboardingActivityReport` (screen 4)
- Evolution/essence assets (screen 8)
- `PetDropStep` / `DragPortalSheet` / `PetDropZone` (screen 11)
- Speech bubble system (screen 7)

## Accessibility Considerations

- **Reduce Motion:** All animation-heavy screens (3, 5, 6) must respect `UIAccessibility.isReduceMotionEnabled`. Simpler transitions, less sway.
- **Tap fallback:** Screen 11 drag-and-drop must have tap alternative after failed attempts.
- **Haptic toggle:** Respect system haptic settings.

## Premium Model Summary

| Feature | Free | Premium |
|---------|------|---------|
| Wind system + free breaks | Yes | Yes |
| Evolution (plant essence) | Yes | Yes |
| Committed breaks + coins | No | Yes |
| Additional essences (crystal, flame, water) | No | Yes |
| Island customization | No | Yes |

Authentication is independent of premium. Unauthenticated users can purchase premium (StoreKit/Apple ID handles it). Auth enables cloud sync/backup via Supabase.
