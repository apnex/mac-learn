#!/bin/bash

function parseToken {
	local LINE="${1}"
	local NODE
	local REMAIN
	local TOKEN
	local VALUE

	#if [[ $LINE =~ ^([0-9a-zA-Z]+)\[([0-9]+)\]\.([^$]+) ]]; then # current token is ARRAY
	if [[ $LINE =~ ^([0-9a-zA-Z]+)\[([0-9]+)\]\.([^.$]+)\.([^$]+) ]]; then # current token is ARRAY
		TOKEN="ARRAY"
		VALUE="${BASH_REMATCH[1]}"
		#[${BASH_REMATCH[2]}]"
		REMAIN="${BASH_REMATCH[4]}"
		# if ARRAY, strip next value
	fi
	if [[ $LINE =~ ^([0-9a-zA-Z]+)\.([^$]+) ]]; then # current token is WORD
		TOKEN="WORD"
		VALUE="${BASH_REMATCH[1]}"
		REMAIN="${BASH_REMATCH[2]}"
	fi
	if [[ $LINE =~ ^([^.]*)$ ]]; then # current token is VALUE
		TOKEN="VALUE"
		VALUE="${BASH_REMATCH[1]}"
		if [[ $LINE =~ =([^=]*)$ ]]; then # current token is VALUE
			VALUE="${BASH_REMATCH[1]}"
		fi
		if [[ $LINE =~ \[\].=([^=]*)$ ]]; then # current token is VALUE
			TOKEN="ARRAY"
			VALUE="${BASH_REMATCH[1]}"
			REMAIN="${BASH_REMATCH[1]}"
		fi
	fi
	if [[ -n "${REMAIN}" ]]; then
		if [[ ! ${REMAIN} =~ ^[[:blank:]]*$ ]]; then
			RESULT=$(parseToken "${REMAIN}")
		fi
	fi
	case "${TOKEN}" in
		ARRAY)
			printf "[${RESULT}]"
		;;
		WORD)
			#printf "\"${VALUE}\":${RESULT}"
			printf "{\"${VALUE}\":${RESULT}}"
		;;
		VALUE)
			printf "\"${VALUE}\""
		;;
	esac
}

function makeSwitch {
	local IFS=$'\n'
	local RESPONSE=($(cat moo2))
	for LINE in "${RESPONSE[@]}"; do # each line
		echo $LINE
	done
	for LINE in "${RESPONSE[@]}"; do # each line
		parseToken "${LINE}"
		echo
	done
}

makeSwitch
