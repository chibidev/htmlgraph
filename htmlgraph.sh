#!/bin/bash

url=''
title='default'
display='false'

imview="`which feh`"
html2gdl="$HOME/projects/perl/htmlgraph/html2gdl.pl"

while getopts ":du:t:" opt; do
	case $opt in
		d)
			display='true'
			;;
		t)
			title="$OPTARG"
			;;
		u)
			url="$OPTARG"
			;;
	esac
done

if [ "$url" == "" ]; then
	echo "Specify url!"
	exit 2
fi

"$html2gdl" --engine=GraphViz --url="$url" --node-color=tag --show-labels=2 --exclude-tags=br --graph=/dev/stdout | dot -Tpng -o "$title.png"

if [ "$display" == "true" ]; then
	"$imview" "$title.png"
fi
