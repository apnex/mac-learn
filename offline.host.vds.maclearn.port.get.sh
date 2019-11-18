#!/bin/bash
source drv.core

# inputs
ID="${1}"
VDSNAME="${2}"
DVPORT="${3}"

if [[ -n "${ID}" && "${VDSNAME}" && "${DVPORT}" ]]; then
	NODE=$(cat vds.learn.json | jq ".[] | select(.dvport==${DVPORT})")
	printf "${NODE}" | jq --tab .
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.switch.list") $(ccyan "<ip-address> <vds-name> <dvport>")\n" 1>&2
fi
