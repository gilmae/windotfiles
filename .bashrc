alias e=notepad++
alias vs13='C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\devenv.exe'
alias vs17='C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\devenv.exe'

set EDITOR=notepad++

open_pr() {
    if [[ $1 == *"visualstudio.com"* ]]; then
        start "$1it's there$2"
    elif  [[ $1 == *"github.com"* ]]; then
        start "$1/compare/$2"
    elif [[ $1 == *"bitbucket"* ]]; then
        start "$1/pull-requests/new?source=$2"
    fi
}