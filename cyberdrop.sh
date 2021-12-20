#!/bin/bash
# adding a comment
MAX=5 # change this to download more simultaneously

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
usage:
	--help, -h		Show this text.
	--count, -c		Specify the number of parallel downloads (default 5).
EOF
}

main () {
	dep_ck "aria2c" "pup.exe" "curl"

	[[ -z $@ ]] && { echo -n "Enter link: "; read sauce; } || sauce="$@"
	[[ -z $sauce ]] && { echo "[-] No links given."; exit 1; }
	for i in ${sauce[@]}; do
		if [[ ! $(curl -s -LI $i | head -1) =~ 200 ]]; then
			echo "[-] Wrong link :: $i";
			continue;
		fi
		html=$(curl -s $i)
		title=$(echo $html | pup.exe 'h1#title attr{title}')
		tmp=$(echo $html | pup.exe 'p.title text{}')
		files=$(echo $tmp | awk '{print $1}')
		size=$(echo $tmp | awk '{print $2" "$3}')
		links=$(echo $html |\
			pup.exe 'a.image attr{href}' |\
			sed 's/[[:space:]]/\%20/g')
		if [[ -d "$title" ]] && [[ ! -z $(ls -A "$title") ]]; then
			echo "[-] Already Downloaded :: $title [$i]";
			continue;
		fi
		printf "[*] Downloading :: [Album: $title :: $files :: $size]" && mkdir -p "$title"
		echo $links |\
			sed 's/[[:space:]]/\n/g' |\
			xargs -P $MAX -I{} aria2c -q -x 5 -d "$title" {}
	#	printf "\033[A\33[2K%s\n" "[+] Downloaded [Album: $title :: $files :: $size]" use this when new line
		printf "\33[2K\r%s\n" "[+] Downloaded [Album: $title :: $files :: $size]"
	#	printf "%-100s\r" "[+] Downloaded [Album: $title :: $files :: $size]" use when what fixed length output
		unset html title tmp files size links
	done
}

while true; do
	case "$1" in
		--help | -h)
			usage
			exit
			;;
		--count | -c)
			MAX=$2
			shift 2
			break
			;;
		-*)
			echo "Wrong option $1"
			exit
			;;
	esac
done

main "$@"
