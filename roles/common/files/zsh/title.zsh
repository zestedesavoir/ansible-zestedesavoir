
# Display the title. Contains the command if given in $1
function title {
	t="zsh"
	[[ -n "$1" ]] && t="${1//\%/\%\%}"

	case $TERM in
		screen|screen-256color)
			print -nP "\ek$t\e\\"
			print -nP "\e]0;%m:%~\a"
			;;
		xterm*|rxvt*|(E|e)term)
			print -nP "\e]0;$t\a"
			;;
	esac
}

function preexec {
	emulate -L zsh
	local -a cmd; cmd=(${(z)1})  # Re-parse the command line

	# Construct a command that will output the desired job number.
	case $cmd[1] in
		fg)
			if (( $#cmd == 1 )); then
				# No arguments, must find the current job
				cmd=(builtin jobs -l %+)
			else
				# Replace the command name, ignore extra args.
				cmd=(builtin jobs -l ${(Q)cmd[2]})
			fi ;;
		%*)
			cmd=(builtin jobs -l ${(Q)cmd[1]}) ;; # Same as "else" above
		exec)
			shift cmd ;& # If the command is 'exec', drop that, because
			             # we'd rather just see the command that is being
			             # exec'd. Note the ;& to fall through.
		*)
			title "${cmd}" # Not resuming a job,
			return ;;      # so we're all done
	esac

	local -A jt; jt=(${(kv)jobtexts}) # Copy jobtexts for subshell

	# Run the command, read its output, and look up the jobtext.
	# Could parse $rest here, but $jobtexts (via $jt) is easier.
	$cmd >>(read num rest
		cmd=(${(z)${(e):-\$jt$num}})
		title "${cmd}") 2>/dev/null
}

# vim: set ts=4 sw=4 cc=80 :
