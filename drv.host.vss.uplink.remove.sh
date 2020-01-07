#!/bin/bash
source mod.core

IPADDR="${1}"
SWITCH="${2}"
VMNIC="${3}"
ESXPASS=$(jq -r '.esxpass' <parameters)

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p ${ESXPASS} ssh root@"${IPADDR}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${IPADDR}" && "${VMNIC}" && "${SWITCH}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli network vswitch standard uplink remove --vswitch-name "${SWITCH}" --uplink-name "${VMNIC}"
	EOF
	#esxcli network vswitch standard list
	sshCmd "${COMMANDS}"
	./drv.host.vss.list.sh "${IPADDR}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "node.interface.list") $(ccyan "<ip-address> <vswitch> <vmnic>")\n" 1>&2
fi
