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

[[ -z "$@" ]] && { echo -n "Enter link: "; read sauce; } || sauce="$@"
[[ -z $sauce ]] && { echo "[-] No links given."; exit 1; }

for i in ${sauce[@]}; do
		[[ ! $(curl -sLI $i | head -1) =~ 200 ]] && { echo "[-] Wrong link :: $i"; continue; }
		html=$(curl -s $i)
	title=$(echo $html | pup 'h1#title attr{title}')
	[[ -d "$title" ]] && [[ ! -z $(ls -A "$title") ]] && { echo "[-] Already Downloaded :: $title [$i]"; continue; }
	files=$(echo $html | pup 'p.title text{}' | awk '{print $1}')
	size=$(echo $html | pup 'p.title text{}' | awk '{print $2" "$3}')
	links=$(echo $html |\
		pup 'a.image attr{href}' |\
		sed 's/[[:space:]]/\%20/g')

	printf "[*] Downloading :: [Album: $title :: $files :: $size]" && mkdir -p "$title"
	echo $links |\
		sed 's/[[:space:]]/\n/g' |\
		xargs -P $MAX -I{} aria2c -q -x 5 -d "$title" {}
#	Use this when new line
#	printf "\033[A\33[2K%s\n" "[+] Downloaded [Album: $title :: $files :: $size]"
	printf "\33[2K\r%s\n" "[+] Downloaded [Album: $title :: $files :: $size]"
#	Use when what fixed length output
#	printf "%-100s\r" "[+] Downloaded [Album: $title :: $files :: $size]"
	unset html title files size links
done