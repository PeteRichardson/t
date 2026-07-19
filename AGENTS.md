# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`t` is a macOS command-line tool that uses the Mac Reminders database (via EventKit) as the
storage backend for Eisenhower-method (urgent/important) task management. Reminders are printed
to the terminal as a four-quadrant box-drawing matrix, each tagged with a short hex key used to
reference it in subsequent commands.

## Build, run, test

This is an Xcode project (`t.xcodeproj`); there is no Swift Package Manager manifest. The scheme
is `t`. Build/run/test from the command line with:

- Build:  `xcodebuild -project t.xcodeproj -scheme t -configuration Debug build`
- Run:    launch the built `t` binary, or run from Xcode. The tool needs Reminders access
          (entitlement `com.apple.security.personal-information.calendars`); first run triggers a
          macOS permission prompt.
- Tests:  `xcodebuild test -project t.xcodeproj -scheme t -destination 'platform=macOS'`
          NOTE: the shared scheme's `<Testables>` section is currently empty, so `xcodebuild test`
          will not run the `t_tests` bundle until the test target is added to the scheme in Xcode
          (Product > Scheme > Edit Scheme > Test). The test files live in `t_tests/`.

Because the tool reads and writes the user's *real* Reminders database on the default reminders
list, be careful running `c`/`d`/`m` commands during development — they complete, delete, and move
real reminders.

## CLI grammar (see `t/main.swift`)

Invoked as `t [<command> <options>]`. With no args it just lists current reminders.
- `t <priority> <title...>` — add a reminder. `<priority>` is a name (`uih`, `ui`, `uil`, `nuih`,
  `nui`, `nuil`, `unih`, `uni`, `unil`, `nuni`) or the equivalent digit `0`–`9`. Unknown first
  word ⇒ the whole thing becomes a title at priority 0.
- `t c <hash...>` — mark reminders complete
- `t d <hash...>` — delete reminders
- `t m <priority> <hash...>` — move reminders to a new priority
- `t h` — usage

## Architecture

Four source files under `t/`:

- `main.swift` — entry point. Builds a `ReminderCache` (async), parses `CommandLine.arguments`,
  dispatches to cache mutators, then renders with `EisenhowerConsoleView`. Errors surface as
  `#`-prefixed comment lines.
- `ReminderCache.swift` — owns the `EKEventStore` and an in-memory `ReminderDict`
  (`[String: EKReminder]` keyed by the 3-char hash). Loads *incomplete* reminders plus reminders
  *completed today* using two separate `NSPredicate`s (`predicateForIncompleteReminders` +
  `predicateForCompletedReminders`), each fetched through an async continuation wrapper around
  EventKit's completion-handler API. Also defines `ReminderDict` quadrant accessors
  (`uiItems`/`nuiItems`/`uniItems`/`nuniItems`) that filter by the priority→quadrant grouping.
- `EisenhowerConsoleView.swift` — pure rendering. Holds `priority_map` (name/digit → 0–9), computes
  column widths from terminal size (`ioctl`/`TIOCGWINSZ`, fallback 80) and longest titles, sorts
  each quadrant by completion-then-priority, and draws the matrix with Unicode box-drawing chars
  and ANSI 256-color escape codes.
- `extensions.swift` — `EKReminder` helpers: `key` (3-char prefix of `calendarItemIdentifier`,
  the user-facing hash) and `completedToday`; plus `NSDate` `==`/`<` operators.

### Priority ⇒ quadrant mapping (the core domain model)

Priorities 0–9 encode both *which quadrant* a reminder lands in and *its sort order within* the
quadrant. This mapping is duplicated in three places — keep them in sync when changing it:
`ReminderCache.swift` quadrant accessors, `EisenhowerConsoleView.priority_map`, and the tables in
`main.swift`'s `usage()` and `README.md`.

- 1,2,3 → top-left    (urgent & important — "DO")
- 4,5,6 → top-right   (not urgent & important — "PLAN")
- 7,8,9 → bottom-left (urgent & not important — "DELEGATE")
- 0     → bottom-right (not urgent & not important — "ELIMINATE")

### Key/hash caveat

The user-facing hash is the first 3 chars of the reminder's `calendarItemIdentifier`. It is not
guaranteed unique across many reminders; collisions would make two reminders share a dict key.

## Gotchas

- The `main.swift` startup `assert` requires every cached reminder to be either not-completed or
  completed-today; violating the two-predicate load invariant will trap in Debug.
- Rendering uses hard-coded "magic number" width offsets (`+13`, `width-6`, etc.) in
  `EisenhowerConsoleView` — there's an open TODO to clean these up. Adjust layout carefully.
