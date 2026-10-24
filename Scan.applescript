-- Scan.app — scan a page on the Canon MF4010 and open it in Preview.
--
-- Requires the `scan` command installed by install.sh. Built with:
--   osacompile -o Scan.app Scan.applescript
--
-- Spotlight/Finder launches GUI apps with a minimal PATH, so the command is
-- invoked with the usual Homebrew and user bin directories prepended.

on run
	set logPath to "/tmp/scan-app.log"
	set scanCmd to "PATH=/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin scan"
	try
		with timeout of 900 seconds
			do shell script scanCmd & " > " & quoted form of logPath & " 2>&1"
		end timeout
	on error
		set errText to "The scanner did not complete the scan. Check that the printer is on and connected."
		try
			set errText to do shell script "tail -n 6 " & quoted form of logPath
		end try
		display dialog errText buttons {"OK"} default button "OK" with title "Scan failed" with icon caution
	end try
end run
