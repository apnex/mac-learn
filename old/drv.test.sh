#!/bin/bash
source drv.core

IPADDR="${1}"

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p 'VMware1!' ssh root@"${IPADDR}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

read -r -d '' ARRAY <<-EOF
structure[0].VDS.BeaconTimeout.integer=-1
structure[0].VDS.CDPStatus.string=listen
structure[0].VDS.Class.string=cswitch
structure[0].VDS.ConfiguredPorts.integer=512
structure[0].VDS.DVPort.structure[0].DVPort.Client.string[] = 
structure[0].VDS.DVPort.structure[0].DVPort.DVPortgroupID.string=dvportgroup-22
structure[0].VDS.DVPort.structure[0].DVPort.InUse.boolean=false
structure[0].VDS.DVPort.structure[0].DVPort.PortID.string=74
structure[0].VDS.DVPort.structure[1].DVPort.Client.string[] = 
structure[0].VDS.DVPort.structure[1].DVPort.DVPortgroupID.string=dvportgroup-22
structure[0].VDS.DVPort.structure[1].DVPort.InUse.boolean=false
structure[0].VDS.DVPort.structure[1].DVPort.PortID.string=75
structure[0].VDS.DVPort.structure[2].DVPort.Client.string[] = 
structure[0].VDS.DVPort.structure[2].DVPort.DVPortgroupID.string=dvportgroup-24
structure[0].VDS.DVPort.structure[2].DVPort.InUse.boolean=false
structure[0].VDS.DVPort.structure[2].DVPort.PortID.string=10
structure[0].VDS.DVPort.structure[3].DVPort.Client.string[0].string=boot.lab.eth1
structure[0].VDS.DVPort.structure[3].DVPort.DVPortgroupID.string=dvportgroup-24
structure[0].VDS.DVPort.structure[3].DVPort.InUse.boolean=true
structure[0].VDS.DVPort.structure[3].DVPort.PortID.string=9
structure[0].VDS.DVPort.structure[4].DVPort.Client.string[0].string=boot.lab.eth2
structure[0].VDS.DVPort.structure[4].DVPort.DVPortgroupID.string=dvportgroup-25
structure[0].VDS.DVPort.structure[4].DVPort.InUse.boolean=true
structure[0].VDS.DVPort.structure[4].DVPort.PortID.string=17
structure[0].VDS.DVPort.structure[5].DVPort.Client.string[] = 
structure[0].VDS.DVPort.structure[5].DVPort.DVPortgroupID.string=dvportgroup-27
structure[0].VDS.DVPort.structure[5].DVPort.InUse.boolean=false
structure[0].VDS.DVPort.structure[5].DVPort.PortID.string=27
structure[0].VDS.DVPort.structure[6].DVPort.Client.string[] = 
structure[0].VDS.DVPort.structure[6].DVPort.DVPortgroupID.string=dvportgroup-27
structure[0].VDS.DVPort.structure[6].DVPort.InUse.boolean=false
structure[0].VDS.DVPort.structure[6].DVPort.PortID.string=28
structure[0].VDS.DVPort.structure[7].DVPort.Client.string[] = 
structure[0].VDS.DVPort.structure[7].DVPort.DVPortgroupID.string=dvportgroup-27
structure[0].VDS.DVPort.structure[7].DVPort.InUse.boolean=false
structure[0].VDS.DVPort.structure[7].DVPort.PortID.string=25
structure[0].VDS.DVPort.structure[8].DVPort.Client.string[] = 
structure[0].VDS.DVPort.structure[8].DVPort.DVPortgroupID.string=dvportgroup-27
structure[0].VDS.DVPort.structure[8].DVPort.InUse.boolean=false
structure[0].VDS.DVPort.structure[8].DVPort.PortID.string=26
structure[0].VDS.MTU.integer=9000
structure[0].VDS.Name.string=fabric
structure[0].VDS.NumPorts.integer=2816
structure[0].VDS.Uplinks.string[] = 
structure[0].VDS.UsedPorts.integer=3
structure[0].VDS.VDSID.string=50 10 a1 4e 6e 5f 54 ea-2b 71 b7 bf b6 2f dd 02
structure[0].VDS.VMwareBranded.boolean=false
EOF

function parseToken {
	local LINE="${1}"
	local NODE
	local REMAIN
	local TOKEN
	local VALUE
	if [[ $LINE =~ ^([0-9a-zA-Z]+)\[([0-9]+)\]\.([^$]+) ]]; then # current token is ARRAY
		TOKEN="ARRAY"
		VALUE="${BASH_REMATCH[1]}"
		#[${BASH_REMATCH[2]}]"
		REMAIN="${BASH_REMATCH[3]}"
	fi
	if [[ $LINE =~ ^([0-9a-zA-Z]+)\.([^$]+) ]]; then # current token is WORD
		TOKEN="WORD"
		VALUE="${BASH_REMATCH[1]}"
		REMAIN="${BASH_REMATCH[2]}"
	fi
	if [[ $LINE =~ ^[^.]+=([^=]*)$ ]]; then
		#if [[ $LINE =~ ^([^.]*)$ ]]; then # current token is VALUE
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
	local ID="0"
	for LINE in "${RESPONSE[@]}"; do # each line
		if [[ $LINE =~ ^structure\[([0-9]+)\]\.VDS.([[:print:]]+) ]]; then
			local ITEM1="${BASH_REMATCH[1]}"
			local ITEM2="${BASH_REMATCH[2]}"
			if [[ ! $LINE =~ ^structure\[[0-9]+\]\.VDS\.DVPort\..* ]]; then
				NODE=$(parseToken "${ITEM2}")
				if [[ ! "$ID" == "${ITEM1}" ]]; then
					FINAL="$(echo "${FINAL}[${NEWNODE}]" | jq -s '. | add')"
					ID="${ITEM1}"
					NEWNODE="{}"
				fi
				NEWNODE="$(echo "${NODE}${NEWNODE}" | jq -s 'def flatten: reduce .[] as $i([]; if $i | type == "array" then . + ($i | flatten) else . + [$i] end); [.[] | to_entries] | flatten | reduce .[] as $dot ({}; .[$dot.key] += $dot.value)')"
			fi
		fi
	done
	if [[ ! ${NEWNODE} =~ ^\{\}$ ]]; then
		FINAL="$(echo "${FINAL}[${NEWNODE}]" | jq -s '. | add')"
	fi
	printf "${FINAL}" | jq --tab .
}

if [[ -n "${IPADDR}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli --formatter=keyvalue network vswitch dvs vmware list
		#esxcli network vswitch dvs vmware list
	EOF
	RESPONSE=$(sshCmd "${COMMANDS}")
	makeSwitch "${RESPONSE}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.netdbg.instance.list") $(ccyan "<ip-address>")\n" 1>&2
	TEST1="{\"DVPort\":$(makePort "${ARRAY}")}"
	TEST2=$(makeSwitch "${ARRAY}")
	#FINAL="$(echo "${TEST1}${TEST2}" | jq -s '. | add')"
	printf "${TEST1}" | jq --tab .
	printf "${TEST2}" | jq --tab .
fi

## need to adjust recursion logic/:
## Go BREADTH first
## Tokenise left to right
## pop first TOKEN and determine type
## group REMAIN according to current TOKEN type
## recurse per new group and ASSIGN accordingly
