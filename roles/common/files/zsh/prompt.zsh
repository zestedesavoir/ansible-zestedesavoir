# Helper to convert color strings into usable color numbers.
# Well… many many colors are missing, but, what the hell? As long as we’re
# not using them, …
function color {
    case "$1" in
        black)
            echo "16";;
        white)
            echo "253";;
        dark-gr[ae]y)
            echo "236";;
        light-gr[ae]y)
            echo "247";;
        red)
            echo "160";;
        bright-red)
            echo "196";;
        cyan)
            echo "45";;
        bright-cyan)
            echo "51";;
        green)
            echo "118";;
        bright-green)
            echo "120";;
        dark-green)
            echo "70";;
        yellow)
            echo "220";;
        bright-yellow)
            echo "227";;
        blue)
            echo "69";;
        bright-blue)
            echo "75";;
        magenta)
            echo "141";;
        bright-magenta)
            echo "147";;
        *)
            echo "$1";;
    esac
}

# Displays a 256color color code. One for foregrounds, one for backgrounds.
function f { echo -e "\033[38;5;$(color ${1})m" }
function b { echo -e "\033[48;5;$(color ${1})m" }

# Others prompts
PS2="%{$fg_no_bold[yellow]%}%_>%{${reset_color}%} "
PS3="%{$fg_no_bold[yellow]%}?#%{${reset_color}%} "

function precmd {
    local path_color user_color host_color return_code user_at_host
    local cwd sign branch vcs diff remote deco branch_color
    local base_color

    #title

    if [[ ! -e "$PWD" ]]; then
        path_color="${fg_no_bold[black]}"
    elif [[ -O "$PWD" ]]; then
        path_color="${fg_no_bold[white]}"
    elif [[ -w "$PWD" ]]; then
        path_color="${fg_no_bold[blue]}"
    else
        path_color="${fg_no_bold[red]}"
    fi

    if hostname -f | grep -q 'prod'; then
        base_color=green
    else
        base_color=blue
    fi

    sign=">"

    host_color="%{$(f ${host_color:-$base_color})%}"
    user_color="%{$(f ${user_color:-bright-$base_color})%}"
    sign="%{${fg_bold[$base_color]}%}$sign"

    deco="%{${fg_bold[blue]}%}"

    chroot_info=
    if [[ -e /etc/chroot ]]; then
        chroot_info="%{${fg_bold[white]}%} [$(< /etc/chroot)]"
    fi

    return_code="%(?..${deco}-%{${fg_no_bold[red]}%}%?${deco}- )"
    #user_at_host="%{${user_color}%}%n%{${fg_bold[white]}%}/%{${host_color}%}%m"
    user_at_host="%{${host_color}%}%m%{${fg_bold[white]}%}/%{${user_color}%}%n"
    cwd="%{${path_color}%}%48<...<%~"

    PS1="${return_code}${user_at_host}"
    PS1="$PS1 ${cwd}${chroot_info} ${sign}%{${reset_color}%} "

    # Right prompt with VCS info
    if [[ -e .git ]]; then
        vcs=git
        branch=$(git branch | grep '\*' | cut -d " " -f 2)
        diff="$( (( $(git diff | wc -l) != 0 )) && echo '*')"
        vcs_color="${fg_bold[white]}"
    elif [[ -e .hg ]]; then
        vcs=hg
        branch=
        vcs_color="${fg_bold[white]}"
    fi

    if [[ -n "$diff" ]]; then
        branch_color="${fg_bold[yellow]}"
        diff=" ±"
    else
        branch_color="${fg_bold[white]}"
    fi

    if [[ -n "$vcs" ]]; then
        RPS1="- %{${vcs_color}%}$vcs%{${reset_color}%}:%{$branch_color%}$branch$diff%{${reset_color}%} -"
    else
        RPS1=""
    fi
}

# vim: set ts=4 sw=4 cc=80 :
