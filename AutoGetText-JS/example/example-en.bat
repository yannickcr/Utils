@echo off
"../bin/autogettext-js.exe" -o en.js -d .\scripts\ -l .\locales\en_US\LC_MESSAGES\messages.po -debug -c en-US
pause;