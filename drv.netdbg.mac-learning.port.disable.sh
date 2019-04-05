#!/bin/bash
source drv.core

# inputs
ID="${1}"
VDSNAME="${2}"
DVPORT="${3}"

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p 'VMware1!' ssh root@"${ID}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

function makeBody {
	local IFS=$'\n'
	local RESPONSE=(${@})
	NODE="{}"
	for KEY in "${RESPONSE[@]}"; do
		if [[ $KEY =~ ([A-Za-z0-9][^:]*):[[:space:]]*([-$, A-Za-z0-9]*) ]]; then # grabs key:pair
			# convert key to lower case and replace spaces with underline
			local ITEM=$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
			local VALUE=$(printf '%s' "${BASH_REMATCH[2]}")
			RECORD="{\"${ITEM}\":\"${VALUE}\"}"
			NODE="$(echo "${NODE}${RECORD}" | jq -s '. | add')"
		fi
	done
	printf "${NODE}" | jq --tab .
}

if [[ -n "${ID}" && "${VDSNAME}" && "${DVPORT}" ]]; then
	RESPONSE=$(
		read -r -d '' COMMANDS <<-EOF
			netdbg vswitch mac-learning port set --dvs-alias "${VDSNAME}" --dvport "${DVPORT}" --disable
			printf "%s\n" "dvport: ${DVPORT}"
			netdbg vswitch mac-learning port get --dvs-alias "${VDSNAME}" --dvport "${DVPORT}"
		EOF
		sshCmd "${COMMANDS}"
	)
	makeBody "${RESPONSE}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.switch.list") $(ccyan "<ip-address> <vds-name> <dvport>")\n" 1>&2
fi
