#!/bin/bash
source drv.core

ID="${1}"
SWITCH="${2}"

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p 'VMware1!' ssh root@"${ID}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${ID}" && "${SWITCH}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli network vswitch standard remove --vswitch-name "${SWITCH}"
	EOF
	sshCmd "${COMMANDS}"
	./drv.host.switch.list.sh "${ID}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "node.interface.list") $(ccyan "<ip-address> <vswitch>")\n" 1>&2
fi
