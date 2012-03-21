Colordigm
========

Description
-----------

One of the biggest advantages of the various free software platforms is choice.
Don't like GTK or QT?  Use the other.  Don't like gooey?  Use a TUI or CLI.

A downside of all of these choices is that they often use differing
configuration files.  There is no one place to go to to set your colorscheme
system-wide across all of your various programs.  Colordigm is a
(quick-and-dirty) solution to this problem.  By creating a configuration file
for it describing the configuration files of all of the other programs, you can
have it go through and set the colorscheme throughout.

I tried to have colordigm run a santiy check before it does anything but this
was a rather rushed project and will probably explode at an in opportune time.
No warrentee or guarntees what so ever. 

Usage
-----

Just run "colordigm /path/to/configuration/file" and it will do its thing.

Configuration File
------------------

The configuration file is a bunch of lines which start with one character
followed by a tab and the rest of the arguments for that item.  Has to be a
tab, not spaces, because I was lazy when writing this.

You can define a color like so:
    D	name	string

Where "D" tells colordigm you are defining a color, "name" is what you want to
call this color in the rest of the configuration file, and "string" is the
string that colordigm will place in the various other programs' configuration
files for that color.  If you attempt to define a color name more than once or
attempt to use a color name without defining it, colordigm will abort with an
error message.

    F	/path/to/file

This sets what file the following lines correspond to.  This will be used until
it is overwritten by another such line starting with F.

    C	name

This sets what color (defined with a D above) will be used for the next
setting.  This will be used until it is overwritten by another such line
starting with C.

    P	pattern

When colordigm sees a line like the one above starting with "P", it will
attempt to replace part of a line in a file defined by a F-line with the color
in the last C-line (as defined by the last D-line).

The format of the pattern is like so:

    \\(stuff before the color)\\(the color\\)\\(stuff after the color\\)

using regular expressions.  The key line of code is this:

    sed -i "s/$PATTERN/\\1$COLOR\\3/g" $FILE

Where \1 and \3 are the \\(stuff before the color\\) and \\(stuff after the color\\).

    M	message

Lines like this will simple print a message to stdout.  This could be used, for
example, to remind a user how to tell a program to re-parse the config to
change its colors.

    R	command

Lines like this are used to run system commands.  For example, if you can
automate having a program re-parse its config via a system command, you can
have colordigm do it with one of these lines.  It will prompt the user before
running the command just in case.  This is probably a huge security
vulnerability and a Bad Idea.

See the example file if this isn't clear.
