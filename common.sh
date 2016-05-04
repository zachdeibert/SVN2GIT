LOG_COLOR_RESET="0"
LOG_COLOR_RED="31"
LOG_COLOR_GREEN="32"
LOG_COLOR_BLUE="34"
SVN_USER=""
SVN_PASS=""

# setColor [color]
#   STDOUT: The color change sequence
function setColor() {
    printf "\033[1;%dm" "$1"
}

# log {-n} [color] [message]
#   STDOUT: The formatted message
function log() {
    if [ "a$1" == "a-n" ]; then
        printf "$(setColor "$2")%s$(setColor $LOG_COLOR_RESET)" "$3"
    else
        printf "$(setColor "$1")%s$(setColor $LOG_COLOR_RESET)\n" "$2"
    fi
}

# prompt [message]
#    STDIN: The prompt answer (Do no redirect!)
#   STDOUT: The answer to the prompt (You should redirect!)
#   STDERR: The prompt (Do not redirect!)
# 
# Example:
#   $ source common.sh
#   $ echo "You said $(prompt "Enter something")!"
#   Enter something: Hi
#   You said Hi!
function prompt() {
    log -n $LOG_COLOR_BLUE "$(printf "% 30s: " "$1")" 1>&2
    read ans
    echo $ans
}

# svnExec [command] [args]
#    STDIN: Piped to svn process
#   STDOUT: Piped from svn process
#   STDERR: Piped from svn process
function svnExec() {
    if [ "a$SVN_USER" == "a" ]; then
        if [ "a$SVN_PASS" == "a" ]; then
            svn $1 $2
        else
            svn $1 --password "$SVN_PASS" --no-auth-cache $2
        fi
    else
        if [ "a$SVN_PASS" == "a" ]; then
            svn $1 --username "$SVN_USER" --no-auth-cache $2
        else
            svn $1 --username "$SVN_USER" --password "$SVN_PASS" --no-auth-cache $2
        fi
    fi
}

# destoryWorkspace [workspacePath] [gitBranch] [oldDir] [tmpDir]
function destoryWorkspace() {
    cd "$1/git"
    ln -s ../_git .git
    if [ "a$2" != "a" ]; then
        git push origin "$2"
    fi
    cd "$3"
    rm -Rf "$4"
}

# setupWorkspace {[svnURL] [svnUser] [svnPass]} {[gitURL] [gitBranch]} [processCommand]
function setupWorkspace() {
    TMP_DIR="$(readlink -f "$(mktemp -d -q svn2git_converter_tmp_XXXXXXXXXXXXXXXX)")"
    OLD_DIR="$(pwd)"
    cd "$TMP_DIR"
    mkdir -p svn git
    cd svn
    if [ $# -eq 4 ] || [ $# -eq 6 ]; then
        SVN_USER="$2"
        SVN_PASS="$3"
        svnExec co "$(printf "%q ." "$1")"
    fi
    cd ../git
    if [ $# -eq 3 ]; then
        git clone "$1" .
        mv .git ../_git
        ln -s ../_git .git
        git checkout "$2"
        rm .git
    else
        if [ $# -eq 6 ]; then
            git clone "$4" .
            mv .git ../_git
            ln -s ../_git .git
            git checkout "$5"
            rm .git
        fi
    fi
    cd ..
    if [ $# -eq 3 ]; then
        trap "destoryWorkspace \"$(pwd)\" \"$2\" \"$OLD_DIR\" \"$TMP_DIR\"" EXIT
    else
        if [ $# -eq 6 ]; then
            trap "destoryWorkspace \"$(pwd)\" \"$5\" \"$OLD_DIR\" \"$TMP_DIR\"" EXIT
        else
            trap "destoryWorkspace \"$(pwd)\" \"\" \"$OLD_DIR\" \"$TMP_DIR\"" EXIT
        fi
    fi
    case $# in
        3) $3;;
        4) $4;;
        6) $6;;
    esac
}

# convertSection [start] [end]
#   STDOUT: General status updates
function convertSection() {
    cd git
    I=$1
    C=1
    while [ $C -eq 1 ]; do
        log $LOG_COLOR_GREEN "Converting Commit $I"
        cd ../svn
        MSG="$(svnExec log "--revision $I" | grep -v -x -E -- "-*")"
        AUTHOR="$(echo "$MSG" | head -n 1 | sed -e "s,.*| \(.*\) |.*|.*,\1,g")"
        MSG="$(echo "$MSG" | tail -n $(($(echo "$MSG" | wc -l)-1)))"
        rm -Rf ../git/*
        svnExec export "-r $I --force . ../git" | grep -v "No such revision"
        if [ $? -eq 0 ]; then
            cd ../git
            ln -s ../_git .git
            git add --all
            git config user.name "$AUTHOR"
            git config user.email "$AUTHOR"
            git commit -m "[SVN REV $I] $MSG"
            rm .git
            I=$(($I+1))
            if [ $I -gt $2 ]; then
                C=0
            fi
        else
            cd ../git
            log $LOG_COLOR_RED "Commit $I Not Found."
            log $LOG_COLOR_RED "Stopping now."
            C=0
        fi
    done
}

# lastSVNConvert
#   STDOUT: The last commit #
function lastSVNConvert() {
    DEL=0
    if [ ! -d .git ] || [ ! -f .git ]; then
        DEL=1
        ln -s ../_git .git
    fi
    git log | grep -x -E " *\\[SVN REV [0-9]*\\] .*" | sed -e "s| *\\[SVN REV \([0-9]*\)\\] .*|\1|g" | head -n 1
    if [ $DEL -eq 1 ]; then
        rm .git
    fi
}
