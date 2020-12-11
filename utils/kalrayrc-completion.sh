export _KENV_CMD_AWK=$(([ -f /bin/awk ] && echo "/bin/awk") || echo "/usr/bin/awk")
export _KENV_CMD_SORT=$(([ -f /bin/sort ] && echo "/bin/sort") || echo "/usr/bin/sort")
export _KENV_CMD_EGREP=$(([ -f /bin/egrep ] && echo "/bin/egrep") || echo "/usr/bin/egrep")
export _KENV_CMD_SED=$(([ -f /bin/sed ] && echo "/bin/sed") || echo "/usr/bin/sed")
_kenv_genoptlist(){
	local COMMAND=$*
	KENV_SKIP_UPDATES=1 ${COMMAND}  --help 2>&1 | \
		${_KENV_CMD_AWK} 'BEGIN { found = 0 } { if(found == 1) print $$0; if($$1 == "Options:") {found = 1}}' | \
		${_KENV_CMD_EGREP} -e "^[[:space:]]*--" -e "^[[:space:]]*-[a-zA-Z0-9]" | \
		${_KENV_CMD_SED} -e 's/^[[:space:]]*//' -e 's/^-[^-], //' | \
		${_KENV_CMD_AWK} '{ print $1}' | \
		${_KENV_CMD_SED} -e 's/^\(.*\)\[no-\]\(.*$\)/\1\2\n\1no-\2/' | \
		${_KENV_CMD_SORT} -u
}

_kenv_compfile(){
    compgen -f  -- "$*"
}
_complete_kenv_config(){
	local LAST=$1
	local cur=$2
	shift 2
	case $LAST in
		--package-db);;
		--package-repo);;
		--package-db-proto)
            compgen -W "http https" -- "$cur";;
		--package-repo-proto)
            compgen -W "http https file" -- "$cur";;
		-T|--table);;
		-m|--machine);;
		--config-file)
			_kenv_compfile $cur;;
		*)
			echo $*
	esac
}
_complete_kenv_env(){
    COMPREPLY=( $( compgen -W  "$(kenv list -n)" -- "$*"));
}
_complete_createEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv create)
	local TYPE_LIST=$(kenv query --list-envs)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
        --name|-n);;
        --type|-t)
             COMPREPLY=( $( compgen -W "$TYPE_LIST" -- "$cur") );;
        *)
            COMPREPLY=( $(_complete_kenv_config "${COMP_WORDS[last]}" "$cur" $(compgen -W "$OPT_LIST" -- "$cur")) );;
    esac

}
_complete_cleanEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv clean)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
        --name|-n)
 			_complete_kenv_env $cur;;
        *)
            COMPREPLY=( $(_complete_kenv_config "${COMP_WORDS[last]}" "$cur" $(compgen -W "$OPT_LIST" -- "$cur")) );;
    esac

}
_complete_configEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv config)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
        --name|-n)
 			_complete_kenv_env $cur;;
        *)
            COMPREPLY=( $(_complete_kenv_config "${COMP_WORDS[last]}" "$cur" $(compgen -W "$OPT_LIST" -- "$cur")) );;
    esac

}


_complete_helpEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv help)
	local CMD_LIST=$(kenv -l)
    _get_comp_words_by_ref cur
    last=$((COMP_CWORD - 1))
    case "${COMP_WORDS[last]}" in
		-*)
			COMPREPLY=( $( compgen -W "$OPT_LIST" -- "$cur") );;
		*)
	        COMPREPLY=( $( compgen -W "$CMD_LIST" -- "$cur") );;
	esac;
}

_complete_listEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv list)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
        *)
            COMPREPLY=( $(_complete_kenv_config "${COMP_WORDS[last]}" "$cur" $(compgen -W "$OPT_LIST" -- "$cur")) );;
    esac

}

_complete_queryEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv query)
	local TYPE_LIST=$(kenv query --list-envs)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
        --version|-v);;
        --sha1|-s);;
		--machine|-m);;
		--branch|-B);;
		--sub-sha1);;
        --type|-t)
             COMPREPLY=( $( compgen -W "$TYPE_LIST" -- "$cur") );;
		--copy-env|-c)
			COMPREPLY=( $( compgen -f  -- "$cur"));;
 		--download|-d)
			COMPREPLY=( $( compgen -d  -- "$cur"));;
		--hudson|-H|-D|--dump-infos|--copy-env)
			COMPREPLY=( $( compgen -f  -- "$cur"));;
		--hudson-all)
			COMPREPLY=( $( compgen -d  -- "$cur"));;
       *)
            COMPREPLY=( $( compgen -W "$OPT_LIST" -- "$cur") );;
    esac

}
_complete_rmEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv rm)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
        --name|-n)
			_complete_kenv_env $cur;;
        *)
            COMPREPLY=( $( compgen -W "$OPT_LIST" -- "$cur") );;
    esac

}
_complete_renameEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv rename)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
        --name|-n|--new-name|-N)
			_complete_kenv_env $cur;;
        *)
            COMPREPLY=( $( compgen -W "$OPT_LIST" -- "$cur") );;
    esac

}
_complete_updateEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv update)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
        --version|-v);;
        --sha1|-s);;
        --date|-d);;
		--branch|-B);;
        --options|-o);;
  		--sub-sha1);;
		--name|-n)
			_complete_kenv_env $cur;;
		--copy-env|-c)
			COMPREPLY=( $( compgen -f  -- "$cur"));;
		--hudson|-H|-D|--dump-infos|--copy-env)
			COMPREPLY=( $( compgen -f  -- "$cur"));;
		--hudson-all)
			COMPREPLY=( $( compgen -d  -- "$cur"));;
        *)
            COMPREPLY=( $( compgen -W "$OPT_LIST" -- "$cur") );;
    esac

}
_complete_switchEnv(){
    local cur
    local last
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
        --name|-n)
			_complete_kenv_env $cur;;
		*)
			case "$cur" in
				-*)
					COMPREPLY=( $( compgen -W "--name" -- "$cur"));;
				*)
					_complete_kenv_env $cur;;
			esac;;
    esac
}

_complete_testEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv test)
	local TYPE_LIST=$(kenv query --list-envs)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
		--name|-n)
			_complete_kenv_env $cur;;
        --type|-t)
             COMPREPLY=( $( compgen -W "$TYPE_LIST" -- "$cur") );;
        *)
            COMPREPLY=( $(_complete_kenv_config "${COMP_WORDS[last]}" "$cur" $(compgen -W "$OPT_LIST" -- "$cur")) );;
   esac

}

_complete_package_lookupEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv package-lookup)
	local TYPE_LIST=$(kenv query --list-envs)
    _get_comp_words_by_ref cur

    last=$((--COMP_CWORD))
    case "${COMP_WORDS[last]}" in
		--package|-p)
		;;
        --type|-t)
             COMPREPLY=( $( compgen -W "$TYPE_LIST" -- "$cur") );;
        *)
            COMPREPLY=( $(_complete_kenv_config "${COMP_WORDS[last]}" "$cur" $(compgen -W "$OPT_LIST" -- "$cur")) );;
   esac

}

_complete_kEnv(){
    local cur
    local last
	local OPT_LIST=$(_kenv_genoptlist kenv)
	local CMD_LIST=$(kenv -l)
    _get_comp_words_by_ref cur
    last=$((COMP_CWORD - 1))
	if [ $last -eq 0 ]; then 
		case "${COMP_WORDS[1]}" in
			-*)

				COMPREPLY=( $( compgen -W "$OPT_LIST" -- "$cur") );;
			*)
	            COMPREPLY=( $( compgen -W "$CMD_LIST" -- "$cur") );;
		esac;
    else
		local cmd_name=$( compgen -W "$CMD_LIST" -- "${COMP_WORDS[1]}" | sed -e 's/-/_/g')
		completion_func="_complete_${cmd_name}Env"
		declare -f $completion_func > /dev/null && $completion_func
	fi
}

complete -F _complete_kEnv -o nospace kenv
