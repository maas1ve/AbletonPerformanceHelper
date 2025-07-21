#!/bin/zsh
osascript -e 'quit app "Safari"'
osascript -e 'quit app "News"'
osascript -e 'quit app "Calendar"'

sudo mdutil -a -i off
killall photoanalysisd cloudphotod mds mds_stores mdsync 2>/dev/null
killall "AdobeIPCBroker" "CCXProcess" "Adobe Acrobat Updater" "Microsoft AutoUpdate" 2>/dev/null

open -a "Ableton Live"
