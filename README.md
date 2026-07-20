# t — Eisenhower method task management

> _Reminders.app, sorted into what matters._

`t` is a macOS command-line tool that turns your Mac Reminders into an Eisenhower
(urgent/important) task matrix, right in the terminal. It reads and writes the
same reminders your Reminders.app already shows — there's no separate database
or sync step — and prints them as a four-quadrant box-drawing grid so you can
see at a glance what to *do*, *plan*, *delegate*, or *eliminate*. Every reminder
gets a short hex key so you can complete, delete, or re-prioritize it with a
couple of keystrokes. It's a single-user, single-machine tool built for one
person's workflow, not a task-management platform — no sharing, no sync
targets beyond Reminders itself, no mobile app.

<!-- 🖊 TODO: Pick a status line and delete the others:
> **Status:** Active development — CLI flags and rendering may change without notice.
> **Status:** Stable — breaking changes only on major versions.
> **Status:** Maintenance mode — no new features; bug fixes only.
-->

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Examples](#examples)
- [Known Limitations](#known-limitations)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Uses Reminders.app as the backend** — no separate database; reminders you add with `t` show up in Reminders.app and vice versa
- **Four-quadrant Eisenhower matrix** rendered with Unicode box-drawing characters and ANSI 256-color, sized to your terminal width
- **Short hex keys** (3 characters, e.g. `9d2`) to reference any reminder without retyping its title
- **Priority names or digits** — use `ui` or `2` interchangeably on the command line
- **Fast mutations** — complete, delete, or move (re-prioritize) one or more reminders in a single command

---

## Prerequisites

- **macOS 13 (Ventura) or later** — the app targets `.macOS(.v13)` and uses EventKit, which is macOS-only
- **Swift 5.9 toolchain or later** (only needed to build from source; ships with recent Xcode / Xcode Command Line Tools)
- **Reminders access** — macOS will prompt for permission (`com.apple.security.personal-information.calendars` entitlement) the first time `t` runs; you must grant it for `t` to see or modify anything

---

## Installation

There's no packaged distribution yet — build from source with [Swift Package Manager](https://www.swift.org/package-manager/).

### From source

```sh
git clone git@github.com:PeteRichardson/t.git
cd t
make build
```

`make build` runs `swift build` and then ad-hoc code-signs the resulting binary
with the Reminders entitlement (`t.entitlements`). This step matters: plain
`swift build`/`swift run` produce a binary with **no** entitlements, so
Reminders access won't work reliably from it. Use `make build` (or `make
release` for an optimized binary) whenever you need a binary that can actually
talk to Reminders.

The signed binary lands at `.build/arm64-apple-macosx/debug/t` (or
`.build/release/t` after `make release`). Put it on your `PATH`, e.g.:

```sh
ln -s "$(swift build --show-bin-path)/t" /usr/local/bin/t
```

### Verify

```sh
t h
```

should print the usage/help text (there's no `--version` flag).

---

## Quick Start

```sh
$ t ui Change Netflix password     # adds an urgent, important reminder
$ t
```

Each reminder shows up with a 3-character hex key that you use to reference it
in later commands:

<img width="663" alt="t rendering a four-quadrant Eisenhower matrix of reminders" src="https://user-images.githubusercontent.com/979694/163906245-8c8ca78e-f981-4be9-a267-a7553098b382.png">

<!-- 🖊 TODO: The screenshot above predates the Swift Package conversion but the
     rendering itself is unchanged. Consider replacing with an updated terminal
     capture/GIF (with ANSI colors) if you want a fresher demo. -->

---

## Usage

```
t [<command> <options>]
```

With no arguments, `t` just lists current reminders.

| Command | Description |
|---------|-------------|
| `t <priority> <title...>` | Add a reminder. `<priority>` is a name (see table below) or its digit `0`–`9`; an unrecognized first word is treated as part of the title at priority `0`. |
| `t c <hash...>` | Mark one or more reminders complete |
| `t d <hash...>` | Delete one or more reminders |
| `t m <priority> <hash...>` | Move one or more reminders to a new priority |
| `t h` | Print usage |

`<hash>` is the 3-character hex key shown next to each reminder.

---

## Examples

### Add a reminder
```sh
t ui Change Netflix password     # urgent & important
t 1 Change Netflix password      # same thing, using the digit form
```

### Complete, delete, or move reminders
```sh
t c 9d2           # mark 9d2 complete
t d 9d2           # delete 9d2
t m uni a28       # move a28 to priority uni (urgent, not important, normal)
```

### Priority reference

The priority you pass determines both which quadrant a reminder lands in and
its sort order within that quadrant:

```
     uih (1)   |    nuih (4)
     ui  (2)   |    nui  (5)
     uil (3)   |    nuil (6)
     -----------------------
     unih (7)  |
     uni  (8)  |    nuni (0)
     unil (9)  |
```

| Name | Priority | Description                     | Appropriate Action        |
|:----:|:--------:|:---------------------------------|:---------------------------|
| uih  | 1        | urgent & important (high)       | *DO* these tasks!         |
| ui   | 2        | urgent & important (normal)     | *DO* these tasks!         |
| uil  | 3        | urgent & important (low)        | *DO* these tasks!         |
| nuih | 4        | not urgent & important (high)   | *PLAN* these tasks!       |
| nui  | 5        | not urgent & important (normal) | *PLAN* these tasks!       |
| nuil | 6        | not urgent & important (low)    | *PLAN* these tasks!       |
| unih | 7        | urgent & not important (high)   | *DELEGATE* these tasks!   |
| uni  | 8        | urgent & not important (normal) | *DELEGATE* these tasks!   |
| unil | 9        | urgent & not important (low)    | *DELEGATE* these tasks!   |
| nuni | 0        | not urgent & not important      | *ELIMINATE* these tasks!  |

See [the Eisenhower Method](https://en.wikipedia.org/wiki/Time_management#The_Eisenhower_Method).

---

## Known Limitations

- **macOS only** — built on EventKit, which doesn't exist outside Apple platforms
- **Hash collisions are possible** — a reminder's key is just the first 3 characters of its EventKit `calendarItemIdentifier`; with enough reminders, two could collide and share a key
- **Only the default reminders list** — `t` reads/writes `eventStore.defaultCalendarForNewReminders()`; there's no way to point it at a different Reminders list
- **No configuration** — priority names, colors, and layout are fixed in the source; there's no config file or flags to customize them
- **Rendering has known rough edges** — `EisenhowerConsoleView` uses hard-coded width offsets for layout; there's an open TODO to clean these up, so terminal-width edge cases may render oddly
- **Debug builds can trap on startup** — an `assert` requires every cached reminder to be either incomplete or completed *today*; this should always hold via the fetch predicates, but violating it traps in Debug builds
- **Plain `swift build`/`swift run` won't get Reminders access** — see [Installation](#installation); you need `make build`/`make release` for a working binary

<!-- 🖊 TODO: Review this list against any open GitHub issues for completeness. -->

---

## Contributing

No `CONTRIBUTING.md` yet. In the meantime:

```sh
git clone git@github.com:PeteRichardson/t.git
cd t
swift build
swift test
```

This project reads and writes your **real** Reminders data — be careful
running `c`/`d`/`m` while developing, since they complete, delete, and move
actual reminders. Open an issue before starting significant work.

---

## License

<!-- 🖊 TODO: No LICENSE file exists in this repo yet. Add one and update this section
     (e.g. `## License\n\nLicensed under the **MIT License** — see [LICENSE](LICENSE) for details.`) -->

No license file is currently present in this repository.
