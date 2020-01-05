#!/bin/bash
source drv.core

IPADDR="${1}"
ESXPASS=$(jq -r '.esxpass' <parameters)

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p ${ESXPASS} ssh root@"${IPADDR}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

function parseToken {
	local LINE="${1}"
	local NODE
	local REMAIN
	local TOKEN
	local VALUE
	if [[ $LINE =~ ^([0-9a-zA-Z]+)\[([0-9]+)\]\.([^$]+) ]]; then # current token is ARRAY
		TOKEN="ARRAY"
		VALUE="${BASH_REMATCH[1]}"
		REMAIN="${BASH_REMATCH[3]}"
	fi
	if [[ $LINE =~ ^([0-9a-zA-Z]+)\.([^$]+) ]]; then # current token is WORD
		TOKEN="WORD"
		VALUE="${BASH_REMATCH[1]}"
		REMAIN="${BASH_REMATCH[2]}"
	fi
	if [[ $LINE =~ ^[^.]+=([^=]*)$ ]]; then
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
			printf "{\"${VALUE}\":${RESULT}}"
		;;
		VALUE)
			printf "\"${VALUE}\""
		;;
	esac
}

function makePort {
	local IFS=$'\n'
	local RESPONSE=(${@})
	local NODE
	local NEWNODE="{}"
	local FINAL="[]"
	local ID="0"
	for LINE in "${RESPONSE[@]}"; do # each line
		if [[ $LINE =~ ^structure\[[0-9]+\]\.VDS\.DVPort.structure\[([0-9]+)\]\.DVPort\.([[:print:]]+) ]]; then
			NODE=$(parseToken "${BASH_REMATCH[2]}")
			if [[ ! "$ID" == "${BASH_REMATCH[1]}" ]]; then
				FINAL="$(echo "${FINAL}[${NEWNODE}]" | jq -s '. | add')"
				ID="${BASH_REMATCH[1]}"
				NEWNODE="{}"
			fi
			NEWNODE="$(echo "${NODE}${NEWNODE}" | jq -s 'def flatten: reduce .[] as $i([]; if $i | type == "array" then . + ($i | flatten) else . + [$i] end); [.[] | to_entries] | flatten | reduce .[] as $dot ({}; .[$dot.key] += $dot.value)')"
		fi
	done
	if [[ ! ${NEWNODE} =~ ^\{\}$ ]]; then
		FINAL="$(echo "${FINAL}[${NEWNODE}]" | jq -s '. | add')"
	fi
	printf "${FINAL}" | jq --tab .
}

function makeSwitch {
	local IFS=$'\n'
	local RESPONSE=(${@})
	local NODE
	local NEWNODE="{}"
	local FINAL="[]"
	local FINAL
	local ID="0"
	for LINE in "${RESPONSE[@]}"; do # each line
		if [[ $LINE =~ ^structure\[([0-9]+)\]\.VDS.([[:print:]]+) ]]; then
			local ITEM1="${BASH_REMATCH[1]}"
			local ITEM2="${BASH_REMATCH[2]}"
			if [[ ! $LINE =~ ^structure\[[0-9]+\]\.VDS\.DVPort\..* ]]; then
				NODE=$(parseToken "${ITEM2}")
				if [[ ! "$ID" == "${ITEM1}" ]]; then
					local PORTS="{\"DVPort\":$(makePort "${RESPONSE[*]}")}"
					NEWNODE="$(echo "${PORTS}${NEWNODE}" | jq -s '. | add')"
					FINAL="$(echo "${FINAL}[${NEWNODE}]" | jq -s '. | add')"
					ID="${ITEM1}"
					NEWNODE="{}"
				fi
				NEWNODE="$(echo "${NODE}${NEWNODE}" | jq -s 'def flatten: reduce .[] as $i([]; if $i | type == "array" then . + ($i | flatten) else . + [$i] end); [.[] | to_entries] | flatten | reduce .[] as $dot ({}; .[$dot.key] += $dot.value)')"
			fi
		fi
	done
	if [[ ! ${NEWNODE} =~ ^\{\}$ ]]; then
		local PORTS="{\"DVPort\":$(makePort "${RESPONSE[*]}")}"
		NEWNODE="$(echo "${PORTS}${NEWNODE}" | jq -s '. | add')"
		FINAL="$(echo "${FINAL}[${NEWNODE}]" | jq -s '. | add')"
	fi
	printf "${FINAL}" | jq --tab .
}

if [[ -n "${IPADDR}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli --formatter=keyvalue network vswitch dvs vmware list
	EOF
	RESPONSE=$(sshCmd "${COMMANDS}")
	makeSwitch "${RESPONSE}"
	#makeSwitch "$(cat vds.data.txt)"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.vds.list") $(ccyan "<ip-address>")\n" 1>&2
fi
