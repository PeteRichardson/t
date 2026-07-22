import EventKit

func usage() -> String {
    return [
        "# usage: t [<command> <options>]",
        "#",
        "# List or modify reminders on the default calendar",
        "# Reminders are displayed in a four quadrant Eisenhower (urgent/important) matrix",
        "# see: https://en.wikipedia.org/wiki/Time_management#The_Eisenhower_Method",
        "#",
        "# Run the tool with no arguments to list the current reminders.",
        "# Each reminder shows up with a 3 hex-digit hash that is used to reference it.",
        "# For example:",
        "# ╭───────────────────────────┬─────────────────────────────────────╮",
        "# │    9D2 1 ride bike        │                                     │",
        "# │    CA8 2 Plan dinner date │                                     │",
        "# ├───────────────────────────┼─────────────────────────────────────┤",
        "# │                           │    C08 0 Download new IDA Pro       │",
        "# │                           │    AA0 0 Change Netflix password    │",
        "# │                           │    C8A 0 Reschedule eye exam        │",
        "# │                           │    E48 0 Fix outdoor light timers   │",
        "# │                           │ ✔  D33 0 cancel slack pro account   │",
        "# ╰───────────────────────────┴─────────────────────────────────────╯",
        "#",
        "# Examples:  ($ is the shell prompt)",
        "#   $ t ui Change Netflix password     # adds an urgent, important reminder to change your password",
        "#",
        "# The 'ui' string is a priority for the reminder, which determines which quadrant it appears in,",
        "# and the sorting in the quadrant, like this:",
        "#      uih (1)   |    nuih (4) ",
        "#      ui  (2)   |    nui  (5) ",
        "#      uil (3)   |    nuil (6) ",
        "#      ----------------------- ",
        "#      uih (7)   |             ",
        "#      ui  (8)   |    nuni (0) ",
        "#      uil (9)   |             ",
        "#",
        "# Available priorities are: ",
        "#    uih   - priority 1: urgent & important (high)       [DO these tasks!]",
        "#    ui    - priority 2: urgent & important (normal)     [DO these tasks]",
        "#    uil   - priority 3: urgent & important (low)        [DO these tasks]",
        "#    nuih  - priority 4: not urgent & important (high)   [PLAN these tasks]",
        "#    nui   - priority 5: not urgent & important (normal) [PLAN these tasks]",
        "#    nuil  - priority 6: not urgent & important (low)    [PLAN these tasks]",
        "#    unih  - priority 7: urgent & not important (high)   [DELEGATE these tasks]",
        "#    uni   - priority 8: urgent & not important (normal) [DELEGATE these tasks]",
        "#    unil  - priority 9: urgent &  not important (low)   [DELEGATE these tasks]",
        "#    nuni  - priority 0: not urgent & not important.     [ELIMINATE these tasks]",
        "#",
        "#   Note:  you can also use the number priorities on the command line, e.g.",
        "#   $ t 1 Change Netflix password     # adds an urgent, important reminder to change your password",
        "#",
        "# $> t c 9d2        # marks the reminder with hash 9d2 as completed",
        "# $> t d 9d2        # deletes the reminder with hash 9d2",
        "# $> t m uni a28    # moves the reminder with hash a28 to priority uni",
    ].joined(separator: "\n")
}

/// What `runCommand(args:cache:)` decided the top-level driver should do next. Distinct from a
/// thrown `RunError` since showing usage is a successful outcome, not a failure.
enum RunAction: Equatable {
    case showUsage
    case render
}

/// Argument-validation failures from `runCommand(args:cache:)`. Thrown rather than
/// printed-and-exited directly so the dispatch logic stays callable (and testable) without
/// terminating the process.
enum RunError: Error, Equatable {
    case invalidArguments(String)
}

/// Parses `args` (program name already stripped) and dispatches to the matching `cache` mutator.
/// This is the command-dispatch switch that used to live inline in this file's top-level code,
/// where it couldn't be unit tested at all.
func runCommand(args: [String], cache: ReminderCache) throws -> RunAction {
    guard !args.isEmpty else {
        return .render
    }

    let words = Array(args.dropFirst())
    let command = args.first?.lowercased() ?? "unknown"

    switch command {
    case "h", "-h", "--help":
        return .showUsage
    case "c":
        guard !words.isEmpty else {
            throw RunError.invalidArguments("'c' requires at least one hash, e.g. t c a28")
        }
        try cache.completeReminders(hashes: words.map { $0.uppercased() })
    case "d":
        guard !words.isEmpty else {
            throw RunError.invalidArguments("'d' requires at least one hash, e.g. t d a28")
        }
        try cache.deleteReminders(hashes: words.map { $0.uppercased() })
    case "m":
        guard let priorityArg = words.first,
              let priority = Priority(name: priorityArg) else {
            throw RunError.invalidArguments("'m' requires a valid priority and at least one hash, e.g. t m ui a28")
        }
        try cache.moveReminders(hashes: words.dropFirst().map { $0.uppercased() }, priority: priority.rawValue)
    default:   // Can pass a priority name or number, e.g. "ui" or "2"; anything else defaults to priority 0
        let title = words.joined(separator: " ")
        try cache.addReminder(title: title, priority: Priority(name: command)?.rawValue ?? 0)
    }
    return .render
}

do {
    let remCache = await ReminderCache()    // load the reminders from the calendar

    // Every loaded reminder should be either not completed, or completed today (see the
    // two-predicate fetch in ReminderCache.fetchReminders()). This is checked here rather
    // than trusted, because unlike `assert`, this check also runs in release builds.
    let (validReminders, invalidReminders) = remCache.reminders.partitionedByLoadInvariant()
    if !invalidReminders.isEmpty {
        print("# Warning: excluded \(invalidReminders.count) reminder(s) completed before today: \(invalidReminders.keys.sorted().joined(separator: ", "))")
        remCache.reminders = validReminders
    }

    // Reminders with a priority outside 0-9 (e.g. set by another app/import) don't map to any
    // quadrant and would otherwise render nowhere with no indication anything was hidden.
    let (recognizedReminders, unrecognizedReminders) = remCache.reminders.partitionedByRecognizedPriority()
    if !unrecognizedReminders.isEmpty {
        print("# Warning: excluded \(unrecognizedReminders.count) reminder(s) with unrecognized priority not shown: \(unrecognizedReminders.keys.sorted().joined(separator: ", "))")
        remCache.reminders = recognizedReminders
    }

    let action = try runCommand(args: Array(CommandLine.arguments.dropFirst()), cache: remCache)

    switch action {
    case .showUsage:
        print(usage())
        exit(EXIT_SUCCESS)
    case .render:
        let view = EisenhowerConsoleView(reminders: remCache)
        view.display()
    }

} catch ReminderCache.Error.EmptyTitleError {
    print("# Error: can't add reminder with empty title.")
} catch RunError.invalidArguments(let message) {
    print("# Error: \(message)")
    exit(EXIT_FAILURE)
} catch {
    print("# Something is wrong, \(error)")
}
