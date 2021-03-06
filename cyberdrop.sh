#!/bin/bash

VERSION="0.2"
MAX=5

dep_ck () {
    for dep; do
        if ! command -v "$dep" 1>/dev/null; then
            printf "%s not found. Please install it.\n" "$dep" >&2
            exit
        fi
    done
    unset dep
}

usage () {
	cat <<EOF
Usage:
	cyberdrop.sh [options] [link]...

Optional arguements:
	--help, -h		Show this text.
	--count, -c		Specify the number of parallel downloads (default 5).
EOF
}

dep_ck "aria2c" "pup.exe" "curl"

while getopts "hvc:" OPT; do
	case $OPT in
		h)
			usage
			exit
			;;
		v)
			echo $VERSION
			exit
			;;
		c)
			MAX=$OPTARG
			;;
	esac
done
shift $((OPTIND - 1))

[[ -z "$@" ]] && { echo -n "Enter link: "; read source; } || source="$@"
[[ -z $source ]] && { echo "[-] No links given."; exit 1; }

for i in ${source[@]}; do

	[[ ! $(curl -sLI $i | head -1) =~ 200 ]] && { echo "[-] Wrong link :: $i"; continue; }
	html=$(curl -s $i)
	title=$(pup.exe 'h1#title attr{title}' <<< $html)
	[[ -d "$title" ]] && [[ ! -z $(ls -A "$title") ]] && { echo "[-] Already Downloaded :: $title [$i]"; continue; }
	files=$(pup.exe 'p#totalFilesAmount text{}' <<< $html)
	size=$(pup.exe 'nav.level > div:nth-child(2) > div > p.title text{}' <<< $html)
	links=$(pup.exe 'a.image attr{href}' <<< $html | sed 's/[[:space:]]/\%20/g')

	printf "[*] Downloading :: [Album: $title :: $files :: $size]" && mkdir -p "$title"
	sed 's/[[:space:]]/\n/g' <<< $links | xargs -P $MAX -I{} aria2c -q -x 5 -d "$title" {}
#	Use this when new line
#	printf "\033[A\33[2K%s\n" "[+] Downloaded [Album: $title :: $files :: $size]"
	printf "\33[2K\r%s\n" "[+] Downloaded [Album: $title :: $files :: $size]"
#	Use when what fixed length output
#	printf "%-100s\r" "[+] Downloaded [Album: $title :: $files :: $size]"
	unset html title files size links
done
