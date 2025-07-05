Complete MVP Structures:
1. Launcher/Cover Page

Fighter Logo and App Name
Tagline:"Worship Strength Only."
"Sign Up" button (primary)
"Log In" button (secondary)
"Continue as Guest" option (for trying the app)

2. Authentication

Sign Up: Email, Password, Confirm Password, Name
Log In: Email, Password, "Forgot Password" link
Google Sign In option

3. Tasks Page
Today's date at top
List of tasks with checkboxes
Add new task button (+)
Task Size selector (Small/Medium/large)
Task size display: Coloured number indicators in squares on right side of task cards
-Green square with "1" for a small tasks (1 point) 
-yellow square with "3" for medium tasks (3 points) 
-red square with "5" for large task (5 points) 
Progress widget at top showing daily completion 
-full widget card design with rounded progress bar 
-Shows current points / target points (e.g. "5 / 9 points") 
-Progress bar changes colour: grey -> light orange -> yellow -> green (0-25-50-75-100%)
-additional motivational text or streak information 
-smooth fill animation when task completed 
-card-style background with padding and shadows

4. Calender View

Monthly calendar grideach day shows colour based on completion percentage same colours as progress bargrey light orange yellow greentap day to see that day's task optional for mvpnavigation arrows for previous and next month current day highlighted


5. Settings Page

task size point values (small=1,medium=3,large=5) 
Daily target points settings 
colour theme options (keep it simple May be 2 to 3 themes)
clear all data option
App Version info:

Floating Dock Navigation:

Modern iOS-style floating dock positioned at the bottom with:
-translucent background with blur effect 
-rounded corners (24px radius)
-subtle shadow and border 
-floating 20px from the bottom edge 
-centred horizontally with padding from sides 
-tasks tab: checkmark circle icon (svg) 
-calendar tab calendar grid icon (svg)
-settings tab settings sun icon (svg) 
-active state: purple accent colour with background highlight 
-inactive state: grey colour
-smooth hover and tap animations
-glass morphism effect with backdrop blur

Navigation Flow:
Lauch -> Auth -> Tasks Page (With floating dock for Calender/Settings)

