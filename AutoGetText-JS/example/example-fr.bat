@echo off
"../bin/autogettext-js.exe" -o fr.js -d .\scripts\ -l .\locales\fr_FR\LC_MESSAGES\messages.po -debug -c fr-FR
pause;