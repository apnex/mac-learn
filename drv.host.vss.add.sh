#!/bin/bash
source mod.core

ID="${1}"
SWITCH="${2}"
ESXPASS=$(jq -r '.esxpass' <parameters)

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p ${ESXPASS} ssh root@"${ID}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${ID}" && "${SWITCH}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli network vswitch standard add --vswitch-name "${SWITCH}"
	EOF
	sshCmd "${COMMANDS}"
	./drv.host.switch.list.sh "${ID}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "node.interface.list") $(ccyan "<ip-address> <vswitch>")\n" 1>&2
fi
