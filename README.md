# New Joiner Jargon

A macOS menu bar app that helps you capture and learn workplace jargon, acronyms, and technical terms as you encounter them.

## What it does

Starting a new job means drowning in unfamiliar terms. NJJ sits in your menu bar and helps you hit the ground running:

**On first launch**, a short onboarding wizard personalises the app for your role:

1. **Pick your industry** — fintech, healthcare, consulting, gaming, media, and more
2. **Pick your teams** — engineering, product, design, sales, legal, and more
3. **Grant accessibility access** — so the hotkey can read highlighted text from any app

Your glossary is then pre-loaded with the acronyms, terms, and definitions most relevant to your new role.

**Day-to-day**, you build your glossary as you go:

1. **Highlight any word** in any app (Slack, Notion, your browser, anywhere)
2. **Press `Ctrl + Option + J`** to capture it
3. **Get an instant definition** pulled from a built-in glossary, Wikipedia, or the Free Dictionary API
4. **Save it** to your personal glossary with source context — which app, what page, the surrounding sentence

The app remembers where you found each term and preserves formatting like acronyms (ARPU stays ARPU, not "Arpu").

## Features

### Onboarding
- **2-step industry wizard** — choose your sector and the teams you'll work with before you start
- **20 pre-loaded packs** — 9 industry sectors and 11 function teams, each with 30+ curated terms
- **Acronym-first previews** — each pack card shows sample terms in `ACRONYM — meaning` format so you know exactly what you're getting
- **Custom 3D icons** — each pack has a distinct illustrated icon

### Capture
- **Instant capture** — global hotkey (`Ctrl + Option + J`) works in any app
- **Smart source detection** — knows if you captured from Slack (#channel-name), Notion (page title), Figma (file name), or a browser (website + URL)
- **Multiple definitions** — shows alternatives from different sources so you can pick the most relevant one
- **Search with Google** — one-click Google search for any term you look up

### Glossary
- **Full glossary window** — browse, search, filter, and edit all your saved terms
- **Categories** — organise terms into Business, Engineering, Product, Payments, Finance, Regulatory, People & Culture, and more
- **Editable everything** — change definitions, add notes, update categories, add source links
- **Sort and filter** — alphabetical, by date added, by source app, by category
- **Bulk actions** — multi-select to delete or re-categorise terms at once
- **Undo delete** — 5-second window to recover accidentally deleted terms

### Built-in glossary
600+ pre-loaded terms across 20 packs:

| Sectors | Function teams |
|---------|---------------|
| Payments & Fintech | Engineering |
| Media & Ad Tech | Finance |
| Healthcare & MedTech | Marketing |
| Consulting | Product |
| Startups & VC | People & HR |
| Cybersecurity | Legal & Compliance |
| Ecommerce & Retail | Design |
| Climate & ESG | Sales |
| Gaming | Data & Analytics |
| | Customer Success |
| | Operations |

## How it's built

- **Swift 6** + **SwiftUI** — native macOS app
- **SwiftData** — local persistent storage for the glossary (no server, no account needed)
- **Accessibility APIs** — reads selected text from any app using macOS accessibility services
- **AppleScript** — detects browser URLs from Chrome, Safari, Arc, Dia, Brave, and Edge
- **XcodeGen** — project structure defined in `project.yml`
- **Free APIs** — Wikipedia REST API and Free Dictionary API for definitions (no API keys required)
- **Optional Claude API** — can be configured in settings for AI-powered definitions as a fallback

## Project structure

```
NewJoinerJargon/
  Models/
    GlossaryTerm.swift        -- SwiftData model for saved terms
    GlossaryStore.swift       -- Data layer (save, lookup, search, seed)
    IndustryPack.swift        -- Pack definitions: all 20 sectors and function teams
    TermCategory.swift        -- Category enum with icons and colors
    NavigationState.swift     -- Cross-window navigation
  Services/
    AccessibilityService.swift    -- Text capture, browser URL detection
    HotkeyService.swift           -- Global hotkey + source label building
    DictionaryService.swift       -- Built-in glossary + Wikipedia + dictionary lookups
    ClaudeService.swift           -- Optional AI-powered definitions
  Views/
    OnboardingView.swift      -- 3-step wizard: industry → teams → accessibility
    PopoverView.swift         -- Menu bar popover (capture + save flow)
    GlossaryListView.swift    -- Full glossary window (browse + edit)
    SettingsView.swift        -- App settings
  Assets.xcassets/            -- App icon + 20 pack icon imagesets
  AppDelegate.swift           -- App lifecycle, window management, hotkey registration
  NewJoinerJargonApp.swift    -- SwiftUI app entry point
```

## Getting started

Requires Xcode and macOS 14+.

```bash
brew install xcodegen
cd new-joiner-jargon
xcodegen
open NewJoinerJargon.xcodeproj
```

Build and run with `Cmd + R`. The app appears in your menu bar.

To install as a standalone app, switch the build configuration to Release (`Product > Scheme > Edit Scheme > Run > Release`), build, then drag the `.app` from the build folder into `/Applications`.

## Permissions

The app needs **Accessibility access** to read selected text from other apps. You'll be prompted to grant this at the end of the onboarding wizard, or you can grant it later in System Settings → Privacy & Security → Accessibility.
