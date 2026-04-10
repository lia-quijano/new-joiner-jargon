# New Joiner Jargon

A macOS menu bar app that helps you capture and learn workplace jargon, acronyms, and technical terms as you encounter them.

## What it does

Starting a new job means drowning in unfamiliar terms. NJJ sits in your menu bar and lets you build a personal glossary on the fly:

1. **Highlight any word** in any app (Slack, Notion, your browser, anywhere)
2. **Press `Ctrl + Option + J`** to capture it
3. **Get an instant definition** pulled from a built-in glossary of 350+ terms, Wikipedia, or the Free Dictionary API
4. **Save it** to your personal glossary with the source context (which app, what page, the surrounding sentence)

The app remembers where you found each term and preserves formatting like acronyms (ARPU stays ARPU, not "Arpu").

## Features

- **Instant capture** -- global hotkey (`Ctrl + Option + J`) works in any app
- **Smart source detection** -- knows if you captured from Slack (#channel-name), Notion (page title), Figma (file name), or a browser (website + URL)
- **Built-in glossary** -- 350+ pre-loaded terms covering business, engineering, product, payments, finance, regulatory, and people/culture categories
- **Multiple definitions** -- shows alternatives from different sources so you can pick the most relevant one
- **Search with Google** -- one-click Google search for any term you look up
- **Categories** -- organise terms into Business, Engineering, Product, Payments, Finance, Regulatory, People & Culture, and more
- **Full glossary window** -- browse, search, filter, and edit all your saved terms
- **Editable everything** -- change definitions, add notes, update categories, add source links

## How it's built

- **Swift 6** + **SwiftUI** -- native macOS app
- **SwiftData** -- local persistent storage for the glossary (no server, no account needed)
- **Accessibility APIs** -- reads selected text from any app using macOS accessibility services
- **AppleScript** -- detects browser URLs from Chrome, Safari, Arc, Dia, Brave, and Edge
- **XcodeGen** -- project structure defined in `project.yml`
- **Free APIs** -- Wikipedia REST API and Free Dictionary API for definitions (no API keys required)
- **Optional Claude API** -- can be configured in settings for AI-powered definitions as a fallback

## Project structure

```
NewJoinerJargon/
  Models/
    GlossaryTerm.swift      -- SwiftData model for saved terms
    GlossaryStore.swift     -- Data layer (save, lookup, search)
    TermCategory.swift      -- Category enum with icons and colors
    NavigationState.swift   -- Cross-window navigation
  Services/
    AccessibilityService.swift  -- Text capture, browser URL detection
    HotkeyService.swift         -- Global hotkey + source label building
    DictionaryService.swift     -- Built-in glossary + Wikipedia + dictionary lookups
    ClaudeService.swift         -- Optional AI-powered definitions
  Views/
    PopoverView.swift       -- Menu bar popover (capture + save flow)
    GlossaryListView.swift  -- Full glossary window (browse + edit)
    SettingsView.swift      -- App settings
  AppDelegate.swift         -- App lifecycle, hotkey registration
  NewJoinerJargonApp.swift  -- SwiftUI app entry point
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

The app needs **Accessibility access** to read selected text from other apps. You'll be prompted to grant this in System Settings on first use.
