#!/bin/bash
source drv.core

ID="${1}"
NIC="${2}"
SWITCH="${3}"

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p 'VMware1!' ssh root@"${ID}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${ID}" && "${NIC}" && "${SWITCH}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli network vswitch standard uplink add --vswitch-name "${SWITCH}" --uplink-name "${NIC}"
	EOF
	sshCmd "${COMMANDS}"
	./drv.host.switch.list.sh "${ID}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "node.interface.list") $(ccyan "<ip-address> <nic> <vswitch>")\n" 1>&2
fi
