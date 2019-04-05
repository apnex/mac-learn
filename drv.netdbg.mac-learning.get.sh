#!/bin/bash
if [[ $0 =~ ^(.*)/[^/]+$ ]]; then
	WORKDIR=${BASH_REMATCH[1]}
fi
source ${WORKDIR}/drv.core
#source ${WORKDIR}/drv.nsx.client

## input driver
NODES=(25 26 27 28)
HOST=${1}

function buildNode {
	local KEY=${1}
	NODE=$(${WORKDIR}/drv.netdbg.mac-learning.port.get.sh "${HOST}" fabric "${KEY}")
	printf "%s\n" "${NODE}"
}

if [[ -n "${HOST}" ]]; then
	FINAL="[]"
	for KEY in ${NODES[@]}; do
		MYNODE=$(buildNode "${KEY}")
		FINAL="$(echo "${FINAL}[${MYNODE}]" | jq -s '. | add')"
	done
	printf "${FINAL}" | jq --tab .
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.switch.list") $(ccyan "<ip-address>")\n" 1>&2
fi
