#!/bin/bash
source drv.core

read -r -d '' ARRAY <<-EOF
structure[0].VirtualSwitch.BeaconEnabled.boolean=false
structure[0].VirtualSwitch.BeaconInterval.integer=1
structure[0].VirtualSwitch.BeaconRequiredBy.string[] = 
structure[0].VirtualSwitch.BeaconThreshold.integer=3
structure[0].VirtualSwitch.CDPStatus.string=listen
structure[0].VirtualSwitch.Class.string=cswitch
structure[0].VirtualSwitch.ConfiguredPorts.integer=128
structure[0].VirtualSwitch.MTU.integer=1500
structure[0].VirtualSwitch.Name.string=vSwitch0
structure[0].VirtualSwitch.NumPorts.integer=2560
structure[0].VirtualSwitch.Portgroups.string[0].string=vss-vmnet
structure[0].VirtualSwitch.Portgroups.string[1].string=vss-mgmt
structure[0].VirtualSwitch.Uplinks.string[0].string=vmnic0
structure[0].VirtualSwitch.UsedPorts.integer=4
structure[1].VirtualSwitch.BeaconEnabled.boolean=false
structure[1].VirtualSwitch.BeaconInterval.integer=1
structure[1].VirtualSwitch.BeaconRequiredBy.string[] = 
structure[1].VirtualSwitch.BeaconThreshold.integer=3
structure[1].VirtualSwitch.CDPStatus.string=listen
structure[1].VirtualSwitch.Class.string=cswitch
structure[1].VirtualSwitch.ConfiguredPorts.integer=128
structure[1].VirtualSwitch.MTU.integer=1500
structure[1].VirtualSwitch.Name.string=vSwitch2
structure[1].VirtualSwitch.NumPorts.integer=2560
structure[1].VirtualSwitch.Portgroups.string[] = 
structure[1].VirtualSwitch.Uplinks.string[] = 
structure[1].VirtualSwitch.UsedPorts.integer=1
EOF

# if token contains = then extract value and print
# if token is a word, then merge {}
# if token is a word[], then merge [{}] - track id
## if id change, merge new [{}]

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
	if [[ $LINE =~ ^([^.]*)$ ]]; then # current token is VALUE
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
		RESULT=$(parseToken "${REMAIN}")
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

function moo {
	read -r -d '' CONFIG1 <<-EOF
	[
		{
			"VirtualSwitch": {
				"PortGroups": [
					"vSwitch2"
				]
			}
		}
	]
	EOF
	read -r -d '' CONFIG2 <<-EOF
	[
		{
			"VirtualSwitch": {
				"PortGroups": [
					"vSwitch3"
				]
			}
		}
	]
	EOF
	read -r -d '' JQSPEC <<-EOF
		def flatten: reduce .[] as $i([]; if $i | type == "array" then . + ($i | flatten) else . + [$i] end); [.[] | to_entries] | flatten | reduce .[] as $dot ({}; .[$dot.key] += $dot.value)
	EOF
	local FINAL="{}"
	NEW1="$(echo "${CONFIG1}" | jq '.[0].VirtualSwitch')"
	NEW2="$(echo "${CONFIG2}" | jq '.[0].VirtualSwitch')"
	#printf "${NEW1}" | jq --tab .
	#printf "${JQSPEC}"
	FINAL="$(echo "${NEW1}${FINAL}" | jq -s 'def flatten: reduce .[] as $i([]; if $i | type == "array" then . + ($i | flatten) else . + [$i] end); [.[] | to_entries] | flatten | reduce .[] as $dot ({}; .[$dot.key] += $dot.value)')"
	FINAL="$(echo "${NEW2}${FINAL}" | jq -s 'def flatten: reduce .[] as $i([]; if $i | type == "array" then . + ($i | flatten) else . + [$i] end); [.[] | to_entries] | flatten | reduce .[] as $dot ({}; .[$dot.key] += $dot.value)')"
	#FINAL="$(echo "${NEW2}${FINAL}" | jq -s '.[0] * .[1]')"
	printf "${FINAL}" | jq --tab .
}

function makeBody {
	local IFS=$'\n'
	local RESPONSE=(${@})

	local NODE
	local NEWNODE="{}"
	local FINAL="[]"
	local ID="0"
	for LINE in "${RESPONSE[@]}"; do # each line
		if [[ $LINE =~ ^structure\[([0-9]+)\]\.VirtualSwitch\.([^$]+) ]]; then
			NODE=$(parseToken "${BASH_REMATCH[2]}")
			if [[ ! "$ID" == "${BASH_REMATCH[1]}" ]]; then
				FINAL="$(echo "${FINAL}[${NEWNODE}]" | jq -s '. | add')"
				ID="${BASH_REMATCH[1]}"
				NEWNODE="{}"
			fi
			NEWNODE="$(echo "${NODE}${NEWNODE}" | jq -s 'def flatten: reduce .[] as $i([]; if $i | type == "array" then . + ($i | flatten) else . + [$i] end); [.[] | to_entries] | flatten | reduce .[] as $dot ({}; .[$dot.key] += $dot.value)')"
		fi
	done
	FINAL="$(echo "${FINAL}[${NEWNODE}]" | jq -s '. | add')"
	printf "${FINAL}" | jq --tab .
}

makeBody "${ARRAY[@]}"
