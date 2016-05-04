#!/bin/bash

function process() {
    cd git
    LAST_COMMIT="$(lastSVNConvert)"
    cd ..
    convertSection "$(($LAST_COMMIT+1))" "$(($LAST_COMMIT+1000001))"
}

cd "$(dirname "$0")"
source common.sh
setupWorkspace "$(prompt "SVN Repo URL")" "$(prompt "SVN Username [optional]")" "$(prompt "SVN Password [optional]")" "$(prompt "GIT Repo URL")" "$(prompt "GIT Branch")" process
