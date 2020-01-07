#!/bin/bash
source mod.core

# inputs
IPADDR=${1}
SWITCH=${2}
DVPORT=${3}
#ESXPASS=$(jq -r '.esxpass' <parameters)
ESXPASS="ObiWan1!"

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p ${ESXPASS} ssh root@${IPADDR} -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${IPADDR}" && -n "${SWITCH}" && -n "${DVPORT}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		netdbg vswitch mac-table port get --dvs-alias ${SWITCH} --dvport ${DVPORT} 2>/dev/null
	EOF
	sshCmd "${COMMANDS}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.vds.port.mactable.get") $(ccyan "<ip-address> <vswitch.name> <dvport.id>")\n" 1>&2
fi
