# t - Eisenhower method task management

a Swift cli tool using the mac Reminders db as a backend for Eisenhower method task management

```usage: t [<command> <options>]```

List or modify reminders on the default calendar
Reminders are displayed in a four quadrant Eisenhower (urgent/important) matrix[^1]

Run the tool with no arguments to list the current reminders.
Each reminder shows up with a 3 hex-digit hash that is used to reference it.
For example:

 <img width="663" alt="image" src="https://user-images.githubusercontent.com/979694/163906245-8c8ca78e-f981-4be9-a267-a7553098b382.png">

Examples:  ($ is the shell prompt)
  $ t ui Change Netflix password     # adds an urgent, important reminder to change your password

You can use other commands (c, d, and m) to mark reminder as Completed, or Delete it or Move it (i.e. change the priority), respectively.

```$> t c 9d2        # marks the reminder with hash 9d2 as completed```
  
```$> t d 9d2        # deletes the reminder with hash 9d2```
  
```$> t m uni a28    # moves the reminder with hash a28 to priority uni```


The 'ui' string is a priority for the reminder, which determines which quadrant it appears in,
and the sorting in the quadrant, like this:

     uih (1)   |    nuih (4)
     ui  (2)   |    nui  (5)
     uil (3)   |    nuil (6)
     -----------------------
     uih (7)   |
     ui  (8)   |    nuni (0)
     uil (9)   |

Available priorities are:
| Name | Priority | Description                     | Appropriate Action        |
|:----:|:--------:|:--------------------------------|:--------------------------|
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

Note:  you can use the priority name or number on the command line, e.g.
  
```$ t 1 Change Netflix password     # adds an urgent, important reminder to change your password```
  
[^1]: see [https://en.wikipedia.org/wiki/Time_management#The_Eisenhower_Method]

