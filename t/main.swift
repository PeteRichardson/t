import EventKit

func usage() {
	print("# usage: t [<command> <options>]")
	print("#")
	print("# List or modify reminders on the default calendar")
	print("# Reminders are displayed in a four quadrant Eisenhower (urgent/important) matrix")
	print("# see: https://en.wikipedia.org/wiki/Time_management#The_Eisenhower_Method")
	print("#")
	print("# Run the tool with no arguments to list the current reminders.")
	print("# Each reminder shows up with a 3 hex-digit hash that is used to reference it.")
	print("# For example:")
	print("# ╭───────────────────────────┬─────────────────────────────────────╮")
	print("# │    9D2 1 ride bike        │                                     │")
	print("# │    CA8 2 Plan dinner date │                                     │")
	print("# ├───────────────────────────┼─────────────────────────────────────┤")
	print("# │                           │    C08 0 Download new IDA Pro       │")
	print("# │                           │    AA0 0 Change Netflix password    │")
	print("# │                           │    C8A 0 Reschedule eye exam        │")
	print("# │                           │    E48 0 Fix outdoor light timers   │")
	print("# │                           │ ✔  D33 0 cancel slack pro account   │")
	print("# ╰───────────────────────────┴─────────────────────────────────────╯")
	print("#")
	print("# Examples:  ($ is the shell prompt)")
	print("#   $ t ui Change Netflix password     # adds an urgent, important reminder to change your password")
	print("#")
	print("# The 'ui' string is a priority for the reminder, which determines which quadrant it appears in,")
	print("# and the sorting in the quadrant, like this:")
	print("#      uih (1)   |    nuih (4) ")
	print("#      ui  (2)   |    nui  (5) ")
	print("#      uil (3)   |    nuil (6) ")
	print("#      ----------------------- ")
 	print("#      uih (7)   |             ")
 	print("#      ui  (8)   |    nuni (0) ")
	print("#      uil (9)   |             ") 
	print("#")
	print("# Available priorities are: ")
	print("#    uih   - priority 1: urgent & important (high)       [DO these tasks!]")
	print("#    ui    - priority 2: urgent & important (normal)     [DO these tasks]")
	print("#    uil   - priority 3: urgent & important (low)        [DO these tasks]")
	print("#    nuih  - priority 4: not urgent & important (high)   [PLAN these tasks]")
	print("#    nui   - priority 5: not urgent & important (normal) [PLAN these tasks]")
	print("#    nuil  - priority 6: not urgent & important (low)    [PLAN these tasks]")
	print("#    unih  - priority 7: urgent & not important (high)   [DELEGATE these tasks]")
	print("#    uni   - priority 8: urgent & not important (normal) [DELEGATE these tasks]")
	print("#    unil  - priority 9: urgent &  not important (low)   [DELEGATE these tasks]")
	print("#    nuni  - priority 0: not urgent & not important.     [ELIMINATE these tasks]")
	print("#")
	print("#   Note:  you can also use the number priorities on the command line, e.g.")
	print("#   $ t 1 Change Netflix password     # adds an urgent, important reminder to change your password")
	print("#")
	print("# $> t c 9d2        # marks the reminder with hash 9d2 as completed")
	print("# $> t d 9d2        # deletes the reminder with hash 9d2")
	print("# $> t m uni a28    # moves the reminder with hash a28 to priority uni")
}

do {
    let remCache = await ReminderCache()    // load the reminders from the calendar
    assert( remCache.reminders.values.filter { $0.isCompleted && !$0.completedToday }.count == 0,
            "in \(#function), all reminders should be not completed or completed today!")
    

    var args = CommandLine.arguments
    args.remove(at:0)
    if args.count > 0 {
    	let words = Array(args.dropFirst())
        let command = args.first?.lowercased() ?? "unknown"
        switch command {
			case "h":
				usage()
				exit(EXIT_SUCCESS)
	        case "c":
                try remCache.completeReminders(hashes: words.map { $0.uppercased() })
	        case "d":
                try remCache.deleteReminders(  hashes: words.map { $0.uppercased() })
	        case "m":
				let priority = EisenhowerConsoleView.priority_map[words[0]]!
                try remCache.moveReminders(    hashes: words.dropFirst().map { $0.uppercased() }, priority: priority)
	        case "uih", "ui", "uil", "nuih", "nui", "nuil", "unih", "uni", "unil", "nuni",
	        	 "1",   "2",  "3",   "4",    "5",   "6",    "7",    "8",   "9",    "0":		// Can pass text or number
                let title = words.joined(separator: " ")
	            try remCache.addReminder (title: title,  priority: EisenhowerConsoleView.priority_map[command]!)
	        default:
                let title = words.joined(separator: " ")
	            try remCache.addReminder (title: title, priority: 0)
        }
    }
    
	let view = EisenhowerConsoleView(reminders: remCache)
	view.display()

} catch ReminderCache.Error.EmptyTitleError {
    print("# Error: can't add reminder with empty title.")
} catch {
    print("Something is wrong, \(error)")
}
