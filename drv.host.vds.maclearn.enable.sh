#!/bin/bash
if [[ $0 =~ ^(.*)/[^/]+$ ]]; then
	WORKDIR=${BASH_REMATCH[1]}
fi
source ${WORKDIR}/mod.core

# inputs
HOST=$1
PORTGROUP=$2

function buildNode {
	local KEY=${1}
	NODE=$(${WORKDIR}/drv.host.vds.maclearn.port.enable.sh "${HOST}" fabric "${KEY}")
	printf "%s\n" "${NODE}"
}

if [[ -n "${HOST}" && -n "${PORTGROUP}" ]]; then
	read -r -d '' JQSPEC <<-CONFIG # collapse into single line
		map(select(.DVPortgroupID | contains ("${PORTGROUP}")))
	CONFIG
	INPUT=$(${WORKDIR}/drv.host.vds.ports.status.sh "${HOST}")
	NODES=($(echo ${INPUT} | jq -r "$JQSPEC" | jq -r '.[] | .PortID'))

	FINAL="[]"
	for KEY in ${NODES[@]}; do
		MYNODE=$(buildNode "${KEY}")
		FINAL="$(echo "${FINAL}[${MYNODE}]" | jq -s '. | add')"
	done
	printf "${FINAL}" | jq --tab .
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.vds.maclearn.enable") $(ccyan "<ip-address> <portgroup-id>")\n" 1>&2
fi

