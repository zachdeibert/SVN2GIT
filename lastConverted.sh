#!/bin/bash

function process() {
    cd git
    log $LOG_COLOR_GREEN "Last Commit from SVN was Commit #$(lastSVNConvert)"
    cd ..
}

cd "$(dirname "$0")"
source common.sh
setupWorkspace "$(prompt "GIT Repo URL")" "$(prompt "GIT Branch")" process
