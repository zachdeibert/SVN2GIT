#!/bin/bash

function convert() {
    convertSection "$(prompt "SVN First Commit")" "$(prompt "SVN Last Commit")"
}

cd "$(dirname "$0")"
source common.sh
setupWorkspace "$(prompt "SVN Repo URL")" "$(prompt "SVN Username [optional]")" "$(prompt "SVN Password [optional]")" "$(prompt "GIT Repo URL")" "$(prompt "GIT Branch")" convert
