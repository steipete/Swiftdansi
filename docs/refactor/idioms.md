# Idiomatic Swift refactors (Nov 26, 2025)

- Replaced ad-hoc `NSRegularExpression` calls with Swift 6 `Regex` literals for safer parsing (table/link detection, token wrap). No more force-tries in hot paths.
- Added `HyperlinkSupport` value type to encapsulate env/TTY detection (ported from supports-hyperlinks) with injectable env/isTTY for testing.
- Ordered-list continuation indent now uses marker width (handles multi-digit numbers) instead of fixed indent.
- Table padding now respects `tablePadding` when emitting cell strings.
- Lowered platform mins to macOS 14 / iOS 17 / tvOS 17 / watchOS 10 / visionOS 1.
- Kept lint/format configs aligned (SwiftLint/SwiftFormat) and ensured tests cover these behaviors (39 cases).
- Future opportunities: extract table/list/code renderers into smaller types, add theme snapshots per style, and consider lazy rendering to trim allocations.
