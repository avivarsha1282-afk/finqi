# FinIQ — Stitch Prompts V3
### Inspired by Neuro · Remini · Lerna reference apps
### Core insight: Pure black + one electric accent + borderless inputs + breathing space

---

## 🔑 THE NEW DESIGN DNA (paste at top of EVERY Stitch prompt)

```
DESIGN SYSTEM — FOLLOW EXACTLY, NO DEVIATION:

Background (base):    #0A0A0A  ← pure near-black, NOT navy, NOT charcoal
Surface (cards):      #1A1A1A  ← one step lighter, no border needed
Surface elevated:     #242424  ← for input fields, chips
Primary text:         #FFFFFF  ← pure white
Secondary text:       #888888  ← mid-gray muted
Hint/caption:         #555555  ← very muted
Accent (ONE place only): #00D09C ← electric teal-green — ONLY on primary CTA button
Danger:               #FF4B4B
Warning:              #F5A623
Success:              #00D09C (same as accent)
Money/₹ amounts:      #FFFFFF bold, IBM Plex Mono font

TYPOGRAPHY:
Display headlines:    SF Pro Display Bold (or Plus Jakarta Sans ExtraBold) — 36–48sp
Section titles:       SF Pro Display Semibold — 22–28sp
Body:                 SF Pro Text Regular — 14–16sp
Financial numbers:    IBM Plex Mono Bold — always, no exception
Labels/captions:      SF Pro Text Regular — 12sp, #888888

BUTTONS:
Primary CTA:   #00D09C background, #0A0A0A text, 56px height, borderRadius 14px, FULL WIDTH
               NO border-radius 99px (pill) — use 14px radius, it looks more premium
Secondary:     #1A1A1A background, NO border, same radius
Destructive:   #FF4B4B background

INPUT FIELDS:
Background:    #1A1A1A (same as card surface — fields "sit in" the form)
Border:        NONE in default state
Focus border:  1px solid #00D09C (teal glow when active)
Height:        56px
Border-radius: 14px
Text:          #FFFFFF 15sp
Placeholder:   #555555
Padding-left:  16px + optional icon space

CARDS:
Background:    #1A1A1A
Border:        NONE — no borders on cards
Border-radius: 16px
Padding:       20px
Depth comes from background contrast ONLY (#1A1A1A on #0A0A0A) — no shadows, no borders

SPACING RULES:
Screen padding (horizontal): 20px on each side
Between major sections: 32px minimum
Between related items: 16px
Inside cards: 20px

THE GOLDEN RULE: Less is more. If you can remove it, remove it.
Every extra border, badge, tagline, or color you add makes it look more generic.
The references that Avi loves use 80% empty space and 20% content.
```

---

## SCREEN 1 — SPLASH (Login Entry)

Inspired by: Neuro App (Ref 1) — logo alone, negative space, buttons at bottom

```
Design a mobile splash screen for FinIQ — India's AI financial mentor.
Follow the exact design system above.

This screen is inspired by the Neuro app's splash: enormous negative space, 
logo in the center alone, sign-in options at the bottom. Minimal. Confident.

FULL SCREEN: #0A0A0A background.

TOP AREA (nothing here — pure empty black space takes up the top 35% of screen)

CENTER COMPOSITION (vertically centered in upper-middle area):
  A minimal custom logomark — a simple geometric shape:
  Small circle (24px) with a thin arc crossing through it, like an abstract 
  brain or compass — drawn in #FFFFFF, 1.5px stroke only. This is the icon.
  
  To the right of the icon (inline): "FinIQ" — 36sp Plus Jakarta Sans ExtraBold
  "Fin" in #FFFFFF, "IQ" in #00D09C (teal — this is the ONLY color)
  
  The icon + wordmark sit together like a proper logo lockup.
  Center-aligned horizontally on screen.
  
  Below the wordmark: 24px gap, then "YOUR FINANCIAL MENTOR" — 11sp, 
  letter-spacing 3px, #555555, all caps. Just this, nothing more.

LARGE EMPTY SPACE: 40% of the screen height between the logo and the buttons.
This negative space IS the design. Do not fill it.

BOTTOM SECTION (pinned to bottom with 40px bottom padding):
  Stack of two buttons, 12px gap between them, 20px horizontal screen margins:
  
  Button 1 — "Continue with Google" 
  Background: #FFFFFF (white — maximum contrast on black)
  Height: 56px, borderRadius: 14px, full width
  Left: Google G icon (colored, 20px), centered
  Text: "Continue with Google" — 15sp #0A0A0A (dark text on white button)
  
  Button 2 — "Sign up with Email"
  Background: #1A1A1A (dark — secondary option)
  Height: 56px, borderRadius: 14px, full width
  Text: "Sign up with Email" — 15sp #FFFFFF
  
  Below buttons (20px gap):
  "Already have an account? Log in" — 13sp
  "Already have an account?" in #555555, "Log in" in #00D09C, inline
  
  Very bottom: "RBI · SEBI · IRDAI aligned" — 10sp #333333 centered (barely visible — it's trust signal, not decoration)

IMPORTANT: No FinIQ tagline near the logo. No hero illustration. No card wrapping anything.
The logo floats alone in a sea of black. The white Google button is the only bright spot 
until the teal CTA. That contrast IS the visual hierarchy.
```

---

## SCREEN 2 — LOGIN (Email + Password)

Inspired by: Lerna (Ref 4) + Remini (Ref 3) — big left-aligned headline, 
borderless dark inputs, electric accent CTA, clean stacking

```
Design the email login screen for FinIQ. Follow exact design system above.

Background: #0A0A0A full screen.

TOP: Back arrow ← top-left, 24sp, #888888. 
FinIQ small logo lockup top-center (icon + "FinIQ" in 20sp) — very small, just for context.

HEADLINE SECTION (36px from top after status bar):
Left-aligned, 20px left margin:
"Welcome back" — 36sp Plus Jakarta Sans ExtraBold, #FFFFFF, line-height 1.1
"Continue your financial journey" — 15sp #888888, 8px below headline
This text sits directly on the black background — NO card wrapper.

FORM SECTION (32px below headline):
All form elements have 20px horizontal margin.

EMAIL GROUP:
"Email" label — 12sp #888888, 0px bottom margin (label sits right on top of field)
Input field: background #1A1A1A, NO border, borderRadius 14px, height 56px
             Left icon: envelope SVG 16px #555555, 16px padding
             Placeholder: "Enter your email" #555555 15sp
             8px gap between label and field

PASSWORD GROUP (16px below email group):
"Password" label left + "Forgot Password?" right (same row) — 12sp #888888 and #00D09C
Input field: same as email field
             Left icon: lock SVG 16px #555555
             Right icon: eye toggle #555555
             

SIGN IN BUTTON (24px below password field):
Full width, 56px height, borderRadius 14px
Background: #00D09C (electric teal — the FIRST time this color appears on screen)
Text: "Sign In" — 16sp Plus Jakarta Sans Bold, #0A0A0A (black text on teal)
This button should feel like the payoff of the entire screen.

OR DIVIDER (20px below button):
Thin horizontal line #2A2A2A with "or continue with" centered, 12sp #555555

SOCIAL BUTTONS ROW (16px below divider):
Two equal buttons side by side, 12px gap:
Left: Google button — #1A1A1A bg, NO border, borderRadius 14px, height 52px
      Google G icon (colored 20px) + "Google" 14sp #FFFFFF
Right: identical structure — could be a third option or just Google for now

BOTTOM (below social, or pinned near bottom):
"Don't have an account? Sign up" — 13sp centered
"Don't have an account?" #555555, "Sign up" #00D09C

Very bottom: "Financial education only. Not SEBI-registered advice." — 10sp #333333

CRITICAL RULES:
- NO card around the form — form sits directly on black screen
- NO border on any input field in default state  
- Teal (#00D09C) appears ONLY on the CTA button and "Sign up" + "Forgot Password?" links
- NO floating labels — static labels above each field
- NO FinIQ branding repeated — one small logo at top is enough
- The headline "Welcome back" should feel as large and confident as in the Lerna reference
```

---

## SCREEN 3 — ONBOARDING CHAT (Artha)

Inspired by: Remini's clean dark inputs + Neuro's restraint

```
Design the AI onboarding chat screen for FinIQ.

Background: #0A0A0A

APP BAR (no card, directly on background, bottom border: 1px solid #1A1A1A):
  Left: Circle avatar 40px — #1A1A1A background, "A" in 16sp IBM Plex Mono Bold #00D09C
        (teal initial — minimal, not a filled blue circle)
  Title: "Artha" — 16sp Plus Jakarta Sans SemiBold #FFFFFF
  Subtitle: "Your Financial Mentor" — 12sp #888888
  Right: ⓘ icon #555555

PROGRESS BAR (immediately below app bar):
  Full width, height 2px (ultra thin — not a thick bar)
  Track: #1A1A1A, Fill: #00D09C
  Below: "4 of 15" — 11sp #555555, right-aligned, 4px below bar

CHAT AREA (background #0A0A0A, scrollable, 20px horizontal padding):

  ARTHA BUBBLE (left-aligned):
  Background: #1A1A1A — NO border, NO colored border
  BorderRadius: 4px 16px 16px 16px
  Padding: 14px 16px, max-width 82%
  Text: 15sp #FFFFFF, line-height 1.6
  "👋 Hi! I'm Artha, your personal finance mentor. To build your financial strategy, 
  I need to understand your situation. What's your monthly take-home salary?"
  Below bubble: "2:14 PM" — 10sp #555555

  USER BUBBLE (right-aligned):
  Background: #1E1E1E — slightly different dark to differentiate
  BorderRadius: 16px 4px 16px 16px
  Padding: 12px 16px, max-width 75%
  Text: "₹4,16,000 per month" — 15sp IBM Plex Mono #FFFFFF
  Below: "2:15 PM ✓✓" — 10sp #555555 right

  ARTHA FOLLOW-UP (same style as first bubble):
  "Understood. That places you at ₹50 LPA — a strong position to build wealth. 
  ₹50 LPA" — the "₹50 LPA" inline text is #00D09C (teal highlight — sparse use)
  "How would you describe your investment knowledge?"

  LIVE STATS MINI CARDS (appear after income confirmed — this is the unique differentiator):
  Two small cards side by side, 8px gap
  Each: background #1A1A1A, borderRadius 12px, padding 12px 14px, NO border
  
  Card 1: "PROJECTED FIRE" 10sp #888888 | "12.5 YEARS" — "12.5" 24sp IBM Plex Mono Bold #F5A623 + "YEARS" 10sp #888888
  Card 2: "TAX EFFICIENCY" 10sp #888888 | "64%" 24sp IBM Plex Mono Bold #00D09C

QUICK REPLY CHIPS (pinned above input):
  Horizontal scroll row, 20px left padding
  Chip style: background #1A1A1A, NO border default, borderRadius 99px, 
              height 36px, padding 0 16px, 13sp #FFFFFF
  Selected chip: background #00D09C, text #0A0A0A (inverted — teal fills)
  Chips: "Beginner" | "Intermediate" | "Advanced"

BOTTOM INPUT BAR (#0A0A0A bg, top border 1px #1A1A1A):
  Left: microphone icon — 44px circle, #1A1A1A bg, #888888 icon, NO outer border
  Center: Input — #1A1A1A bg, borderRadius 99px (pill shape for input only), 
          NO border, 44px height, "Type your answer..." #555555
          Right inside field: paperclip #555555
  Right: Send button — 44px circle, #00D09C bg, #0A0A0A arrow icon

KEY DIFFERENCES FROM PREVIOUS:
- Artha bubbles are #1A1A1A with ZERO border (previous had blue borders)
- Live stats mini cards appear inline in chat — novel, informative, engaging
- Quick reply chips: teal FILL when selected, not teal border
- Ultra thin 2px progress bar (not a thick bar)
- Input and send button are cleaner — no heavy container
```

---

## SCREEN 4 — MONEY HEALTH SCORE

```
Design the Money Health Score screen for FinIQ. The "44" score is the hero.

Background: #0A0A0A. 20px horizontal screen padding throughout.

HEADER (directly on background, no card):
  Back arrow left + "FinIQ" small center + bell icon right
  Below: "Money Health" — 28sp Plus Jakarta Sans ExtraBold #FFFFFF
         "Score" — 28sp Plus Jakarta Sans ExtraBold #00D09C (one word in teal)
  Both on same line or "Score" on second line — visual choice.

GAUGE CARD (#1A1A1A, borderRadius 20px, NO border, padding 24px):
  Semicircular arc gauge:
  - Arc: 240 degrees spread, 200px diameter, 16px stroke, rounded caps
  - Track: #2A2A2A
  - Fill: #FF4B4B (red — grade D), animates 0 → 44%
  
  INSIDE ARC CENTER:
  - "44" — 80sp IBM Plex Mono Black, #FFFFFF (the most important number in the app)
  - "/100" — 18sp IBM Plex Mono Regular, #888888 directly below
  - "Grade D" badge: borderRadius 99px, background #2A0A0A, border 1px #FF4B4B,
    color #FF4B4B, 12sp IBM Plex Mono Bold, padding 4px 14px
  
  Below badge (16px gap): "Money Health Score" — 14sp #888888
  Below: "Across 6 financial dimensions" — 12sp #555555

ARTHA INSIGHT (#1A1A1A card, borderRadius 16px, NO border, left accent: 
              3px solid #00D09C, borderRadius 0 16px 16px 0, padding 16px 20px):
  "A" avatar (same as chat — 32px circle, #242424 bg, "A" #00D09C IBM Plex Mono) + 
  "Artha says" 11sp #00D09C + "2 min" 10sp #555555 right — top row
  
  Message: "Avinash, your score of 44 reflects real gaps — but every dimension is fixable. 
  Two quick wins in Tax and Insurance could push you to 65+ within 60 days."
  14sp #FFFFFF, line-height 1.6, italic

SECTION LABEL: "FIX THESE FIRST" — 10sp #555555 letter-spacing 2px uppercase. 
Red dot (6px circle #FF4B4B) inline before text.

2 PRIORITY CARDS (before dimension breakdown — most urgent):
Each: #1A1A1A, borderRadius 16px, NO border outer, 
      but left border: 3px solid [urgency color], borderRadius 0 16px 16px 0 for that border
      padding 16px 18px, height 64px

Card 1 (RED): Icon circle 36px (#2A0A0A bg, shield icon #FF4B4B) | 
              "Critical: Insurance Gap" 14sp Bold #FFFFFF | "Zero coverage detected" 12sp #888888
              Arrow → right, #888888

Card 2 (AMBER): same style, pig icon #F5A623 bg circle | 
                "Emergency Fund" | "Only 2 months of runway"

SECTION LABEL: "DIMENSIONS BREAKDOWN" — same section label style

6 DIMENSION ROWS (NOT cards — just clean rows inside a single #1A1A1A container):
Single container card, borderRadius 16px, NO border, padding 0
Each row: 16px 20px padding, border-bottom 0.5px #242424 (except last row)

Row layout: [Icon 32px] [Name 14sp #FFFFFF] [Badge] [Score right: "12/20" IBM Plex Mono 13sp #888888]
Badges use same system as before but SMALLER and cleaner:
- CRITICAL: #2A0A0A bg, #FF4B4B text (no border — background contrast is enough)
- NEEDS WORK: #2A1A00 bg, #F5A623 text
- DECENT: #0A1A10 bg, #00D09C text

NOTE: Group all 6 rows in ONE container card — this looks much cleaner than 6 separate cards.
It reads like a table, which is appropriate for data like this.

BOTTOM NAV (#0A0A0A, top border 1px #1A1A1A, height 56px):
5 tabs. Active tab: icon #00D09C + label #00D09C + 4px dot below.
Inactive: icon #555555 + label #555555.
```

---

## SCREEN 5 — DASHBOARD

```
Design the FinIQ main dashboard. Information-dense but never cluttered.

Background: #0A0A0A

TOP (no card, directly on bg, 20px horizontal padding):
  Left: "Good morning" 13sp #888888, "Avinash" 28sp Plus Jakarta Sans ExtraBold #FFFFFF on next line, 
        date "Wednesday · 25 Mar 2026" 12sp #555555 below
  Right: bell icon (with red 6px dot) + user avatar circle 38px (#242424 bg, "AV" 12sp #FFFFFF)

HEALTH SCORE ROW (#1A1A1A, borderRadius 16px, NO border, padding 16px 20px, 
                  horizontal layout, left accent: 3px solid #FF4B4B):
  Left: Mini gauge 80×60px — #2A2A2A track, #FF4B4B fill, "44" 22sp IBM Plex Mono Bold #FFFFFF centered
  Middle (flex 1): 
    "MONEY HEALTH SCORE" 10sp #888888 letter-spacing 1px
    "Grade D — Needs Attention" 13sp #FF4B4B
    Thin progress bar: 4px height, borderRadius 99px, #FF4B4B fill 44%, #242424 track
    "4 urgent actions" 11sp #555555
  Right: "Details" 12sp #00D09C + "→"

4 STAT CARDS (2×2 grid, 10px gap, each: #1A1A1A borderRadius 14px NO border padding 16px):
Layout inside each card:
  - Label: 10sp #555555 uppercase letter-spacing 1px
  - Value: 26sp IBM Plex Mono Bold (colored)
  - Sub: 11sp #888888

Card 1: "TAX SAVING" | "₹70,200" #00D09C | "Available FY 25–26"
Card 2: "MONTHLY SIP" | "₹0" #FF4B4B | "Target: ₹1.19L/mo"
Card 3: "EMERGENCY FUND" | "₹2.00L" #F5A623 | "Gap: ₹1.92L"
Card 4: "NET WORTH" | "₹2.00L" #FFFFFF | "Only savings"

FIRE GOAL (#1A1A1A, borderRadius 16px, NO border, padding 18px 20px):
  Row: "🏠 Luxury Home Goal" 14sp Bold #FFFFFF | "7 Years" pill (#242424 bg, #00D09C text 11sp, borderRadius 99px, padding 3px 12px) right
  Amount: "₹1,50,00,000" 22sp IBM Plex Mono Bold #FFFFFF
  Progress: 10px bar, borderRadius 99px, #1E1E1E track, #00D09C fill 5%
  Below: "₹10,500 of ₹1.5Cr" #888888 | "5%" #888888 right
  CTA text link: "→ Start ₹1.19L/mo SIP" 13sp #00D09C

ARTHA TIP (#1A1A1A, borderRadius 16px, left border 3px #00D09C, padding 16px 20px):
  "ARTHA TIP" 10sp #00D09C letter-spacing 1.5px
  "Starting ₹5,000/mo in a Nifty 50 index fund costs less than most weekend dinners 
   — and grows to ₹82,000 in 10 years." 13sp #FFFFFF italic line-height 1.6

BOTTOM NAV: same as Health Score screen. Home tab active.

THE ONE RULE: Every card has #1A1A1A background and NO border. 
Depth comes from #1A1A1A on #0A0A0A contrast ONLY. 
No gradients. No borders. No shadows.
The teal (#00D09C) appears ONLY on: active nav tab, Tax Saving number, FIRE CTA, Artha tip border.
```

---

## SCREEN 6 — TAX WIZARD

```
Design the Tax Optimizer screen. The ₹70,200 must be unmissable.

Background: #0A0A0A

HEADER (on bg, no card):
  "Tax Optimizer" 28sp Plus Jakarta Sans ExtraBold #FFFFFF
  "FY 2025–26 · Old vs New Regime" 13sp #888888

INCOME INPUT (#1A1A1A, borderRadius 16px, NO border, padding 20px):
  "ANNUAL TAXABLE INCOME" 10sp #555555 uppercase
  Large input row: 
    "₹" 28sp IBM Plex Mono Bold #00D09C (teal rupee symbol — the only color here)
    "50,00,000" 28sp IBM Plex Mono Bold #FFFFFF
    Pencil icon ✏ right, #555555
  Input is styled as display text, not a traditional form field.
  "Calculate My Tax" button: #00D09C bg, #0A0A0A text, 56px, borderRadius 14px, full width

THE HERO — SAVINGS CARD (#1A1A1A borderRadius 20px NO border padding 24px):
  THIS IS THE MOST IMPORTANT ELEMENT ON SCREEN.
  
  "TOTAL POTENTIAL SAVINGS" 11sp #888888 uppercase letter-spacing 2px, centered
  
  "₹70,200" — centered, 72sp IBM Plex Mono Black, #00D09C
  This number should take up most of the card height.
  
  "vs. filing without deductions" — 12sp #888888 italic centered
  
  The card has a very subtle teal glow: box-shadow: 0 0 40px rgba(0, 208, 156, 0.08)
  This is the ONE place a glow is allowed — the hero number deserves it.

REGIME COMPARISON (two cards side by side, 10px gap):
  Both: #1A1A1A, borderRadius 14px, NO outer border, padding 16px
  
  OLD: "OLD REGIME" 11sp #888888 | "Slabs: 5–30%" 11sp #555555 | "₹9,36,000" 24sp IBM Plex Mono Bold #FF4B4B
  
  NEW (RECOMMENDED): Same card size but with 1.5px top border #00D09C ONLY (top border, not full border)
    + "✓ RECOMMENDED" badge: 10sp #00D09C, #0A1A10 bg, borderRadius 4px, padding 3px 8px, top of card
    "NEW REGIME" 11sp #FFFFFF | "Slabs: 5–25%" 11sp #888888 | "₹8,65,800" 24sp IBM Plex Mono Bold #00D09C

OPTIMIZATION CHANNELS (single #1A1A1A container, borderRadius 16px, NO border):
  Section label "OPTIMIZATION CHANNELS" uppercase muted inside container top
  3 rows separated by 0.5px #242424 lines:
  
  Each row (padding 16px 20px):
  [Icon circle 36px #242424] [Name 14sp #FFFFFF + sub 12sp #888888] [Amount IBM Plex Mono #00D09C right + status label below]
  
  80C: Bank icon | "Section 80C" · "ELSS, LIC, PPF, EPF" | "₹46,800" + "MAXIMIZED" 10sp #555555
  80D: Shield icon | "Section 80D" · "Health Insurance Premium" | "₹15,600" + "STANDARD"
  NPS: Piggybank | "NPS (80CCD)" · "Tier 1 Contributions" | "₹7,800" + "RECOMMENDED"

DISCLAIMER (on bg, centered):
  "Calculations based on FY 2025–26 tax laws. Financial education only. Consult a CA." 
  10sp #333333 italic — barely visible at bottom of screen.

BOTTOM NAV: Tax tab active.
```

---

## SCREEN 7 — FIRE PLANNER

```
Design the FIRE Path Planner screen.

Background: #0A0A0A

HEADER: "FIRE Planner" 28sp ExtraBold #FFFFFF + "Financial Independence · Retire Early" 12sp #888888

ARTHA ASSESSMENT CARD (#1A1A1A, borderRadius 16px, left border 3px #F5A623, NO other border):
  "✦ ARTHA ASSESSMENT" 10sp #F5A623 letter-spacing 1.5px
  "Your current trajectory requires ₹1.8L/mo SIP to hit your 7-year goal. 
  We recommend shifting 15% from Debt to Mid-Caps to optimize for the timeline."
  13sp #FFFFFF line-height 1.6

SIMULATION PARAMETERS (#1A1A1A, borderRadius 16px, padding 20px):
  "SIMULATION PARAMETERS" section label
  
  Target Amount input: 
    Label "Target Amount" 11sp #888888
    Value row: "₹" #00D09C 20sp IBM Plex Mono + "1,50,00,000" 20sp IBM Plex Mono Bold #FFFFFF + pencil icon
    Background for this row: #242424, borderRadius 12px, padding 14px 16px
  
  Two inputs side by side (Timeline + Current Savings):
    Same style, #242424 bg, borderRadius 12px
    "7 Years" | "₹2,00,000"
  
  "Calculate My Path →" button: #00D09C bg, #0A0A0A text, 56px, borderRadius 14px, full width

GROWTH PROJECTION (#1A1A1A, borderRadius 16px, padding 20px):
  Header row: "GROWTH PROJECTION" 11sp #888888 | "₹1.52Cr" 20sp IBM Plex Mono Bold #FFFFFF | "+14.2% YoY" 12sp #00D09C
  
  Chart area (#242424 bg, borderRadius 12px, padding 16px):
    Dark background for chart panel
    Smooth curve: #00D09C 2px stroke, area fill rgba(0,208,156,0.08)
    Goal dashed line: #F5A623 dashed
    Grid lines: #2A2A2A 0.5px
    Labels: IBM Plex Mono 10sp #555555

ASSET ALLOCATION:
  "ASSET ALLOCATION STRATEGY" label
  Horizontal bar (not a donut) — 6px height, borderRadius 99px, full width:
    40% #00D09C | 30% #534AB7 (purple) | 20% #F5A623 | 10% #E3B341 (gold)
  Legend below: colored dots + "Large Cap 40%" etc, 12sp IBM Plex Mono #888888

ALTERNATIVE PATHS (TWO CARDS side by side):
  Both #1A1A1A, borderRadius 16px, NO outer border, padding 16px

  3 YRS card: "HIGH RISK" badge (#2A0A0A bg #FF4B4B text borderRadius 4px 10sp)
              "3 Years" 36sp IBM Plex Mono Bold #FFFFFF
              "SIP: ₹4.2L/mo" 14sp IBM Plex Mono #FF4B4B

  7 YRS card (RECOMMENDED — make this taller or accented):
              Top border ONLY: 2px solid #00D09C
              "★ RECOMMENDED" badge (#0A1A10 bg #00D09C text)
              "7 Years" 36sp IBM Plex Mono Bold #FFFFFF
              "SIP: ₹1.8L/mo" 14sp IBM Plex Mono #00D09C

BOTTOM NAV: FIRE tab active.
```

---

## 🎯 THE SINGLE MOST IMPORTANT RULE TO TELL STITCH

End every prompt with this:

```
FINAL CHECK — before generating, verify:
1. Background is #0A0A0A (not navy, not #111827, not #0A0F1E)
2. Input fields have NO border in default state — just dark fill
3. Teal #00D09C appears ONLY on: primary CTA button, key financial numbers, active nav, 
   and occasional text links. Nowhere else.
4. ALL financial numbers (₹ amounts, scores, percentages) are in IBM Plex Mono
5. Cards have NO borders — depth comes from #1A1A1A on #0A0A0A contrast only
6. No drop shadows anywhere
7. Typography feels large and confident — headlines 28sp+
8. The screen has MORE empty space than content
If any of these are violated, regenerate.
```

---
*FinIQ V3 — Built from DNA of Neuro, Remini, Lerna, and Finance App references*
*The philosophy: Pure black. One teal accent. Monospaced money. Breathing space.*
