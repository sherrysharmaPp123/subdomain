#!/bin/bash

# HACKER-SCANNER-X-FIXED - Debugged & Improved Subdomain Finder
# Author: PIYUSH
# Github: github.com/sherrysharmaPp123

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

banner() {
    echo -e "${GREEN}"
    echo "██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗     ███████╗ ██████╗ █████╗ "
    echo "██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗    ██╔════╝██╔════╝██╔══██╗"
    echo "███████║███████║██║     █████╔╝ █████╗  ██████╔╝    ███████╗██║     ███████║"
    echo "██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔═══╝     ╚════██║██║     ██╔══██║"
    echo "██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██║         ███████║╚██████╗██║  ██║"
    echo "╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝         ╚══════╝╚═════╝╚═╝  ╚═╝"
    echo "         🛠️ HACKER-SCANNER-X-FIXED | PIYUSH"
    echo -e "${NC}"
}

usage() {
    echo -e "${YELLOW}Usage:${NC} $0 -d <domain> [-b] [-r]"
    echo "  -d <domain>     Target domain"
    echo "  -b              Enable brute-force with wordlist"
    echo "  -r              Resolve and filter only live subdomains"
    exit 1
}

resolve_live() {
    echo -e "${GREEN}[*] Resolving live subdomains...${NC}"
    local infile="$1"
    local outfile="${DOMAIN}_live.txt"
    > "$outfile"
    while read -r sub; do
        # ignore blank lines
        [[ -z "$sub" ]] && continue
        ip=$(dig +short "$sub" | grep -v '^$' | head -n1)
        if [[ -n "$ip" ]]; then
            echo "$sub -> $ip"
            echo "$sub" >> "$outfile"
        fi
    done < "$infile"
    echo -e "${GREEN}[✓] Live subdomains saved to: $outfile${NC}"
}

# Sources

enum_crtsh() {
    echo -e "${GREEN}[+] Trying crt.sh...${NC}"
    # Try wildcard query, then fallback
    result=$(curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" 2>/dev/null || true)
    if [[ -z "$result" ]]; then
        echo -e "${YELLOW}[!] crt.sh returned no JSON. Trying non-wildcard query...${NC}"
        result=$(curl -s "https://crt.sh/?q=$DOMAIN&output=json" 2>/dev/null || true)
    fi
    if [[ -z "$result" ]]; then
        echo -e "${RED}[!] crt.sh failed or no data${NC}"
    else
        echo "$result" | jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//g' || echo -e "${YELLOW}[!] jq parse fail for crt.sh${NC}"
    fi
}

enum_hackertarget() {
    echo -e "${GREEN}[+] Trying HackerTarget...${NC}"
    result=$(curl -s "https://api.hackertarget.com/hostsearch/?q=$DOMAIN" 2>/dev/null || true)
    if [[ -z "$result" ]]; then
        echo -e "${YELLOW}[!] HackerTarget returned no data${NC}"
    else
        echo "$result" | cut -d',' -f1
    fi
}

enum_threatcrowd() {
    echo -e "${GREEN}[+] Trying ThreatCrowd...${NC}"
    result=$(curl -s "https://www.threatcrowd.org/searchApi/v1/api.php?type=domain&query=$DOMAIN" 2>/dev/null || true)
    if [[ -z "$result" ]]; then
        echo -e "${YELLOW}[!] ThreatCrowd returned no data${NC}"
    else
        # ThreatCrowd returns CSV lines or maybe JSON; parse domain field
        echo "$result" | grep -oP "(?<=,)[^,]*\.$DOMAIN" || echo -e "${YELLOW}[!] ThreatCrowd parse yielded no subdomain matches${NC}"
    fi
}

enum_assetfinder() {
    if command -v assetfinder &>/dev/null; then
        echo -e "${GREEN}[+] Running assetfinder...${NC}"
        assetfinder --subs-only "$DOMAIN"
    else
        echo -e "${YELLOW}[!] assetfinder not installed${NC}"
    fi
}

enum_subfinder() {
    if command -v subfinder &>/dev/null; then
        echo -e "${GREEN}[+] Running subfinder...${NC}"
        subfinder -silent -d "$DOMAIN"
    else
        echo -e "${YELLOW}[!] subfinder not installed${NC}"
    fi
}

enum_amass() {
    if command -v amass &>/dev/null; then
        echo -e "${GREEN}[+] Running amass (passive)...${NC}"
        amass enum -passive -d "$DOMAIN" || echo -e "${YELLOW}[!] amass failed${NC}"
    else
        echo -e "${YELLOW}[!] amass not installed${NC}"
    fi
}

brute_force() {
    local w="$WORDLIST"
    echo -e "${GREEN}[*] Running brute-force with wordlist: $w${NC}"
    if [[ ! -f "$w" ]]; then
        echo -e "${RED}[!] Wordlist file $w not found${NC}"
        return
    fi
    while read -r sub; do
        [[ -z "$sub" ]] && continue
        full="${sub}.$DOMAIN"
        ip=$(dig +short "$full" | grep -v "^$" | head -n1)
        if [[ -n "$ip" ]]; then
            echo "$full"
        fi
    done < "$w"
}

# Main

BRUTE=false
RESOLVE=false

while getopts ":d:br" opt; do
    case $opt in
        d) DOMAIN=$OPTARG ;;
        b) BRUTE=true ;;
        r) RESOLVE=true ;;
        *) usage ;;
    esac
done

if [[ -z $DOMAIN ]]; then
    usage
fi

banner
echo -e "${GREEN}[+] Target domain: $DOMAIN${NC}"

TEMP=$(mktemp)

# call sources
enum_crtsh >> $TEMP
enum_hackertarget >> $TEMP
enum_threatcrowd >> $TEMP
enum_assetfinder >> $TEMP
enum_subfinder >> $TEMP
enum_amass >> $TEMP

# if brute
if $BRUTE; then
    WORDLIST="wordlists/top-subdomains.txt"
    brute_force >> $TEMP
fi

# Clean
sort -u $TEMP | grep -E "\.${DOMAIN}$" > "${DOMAIN}_subs.txt"
rm $TEMP

count=$(wc -l < "${DOMAIN}_subs.txt")
echo -e "${GREEN}[✓] Found $count unique subdomains${NC}"
if [[ $count -eq 0 ]]; then
    echo -e "${RED}[!] No subdomains found. Possible issues:"
    echo "- Domain has no public certificate entries"
    echo "- APIs are blocked or rate limited"
    echo "- Parsing failed (check dependencies: jq, etc.)"
fi

echo -e "${GREEN}[✓] Results saved to ${DOMAIN}_subs.txt${NC}"

if $RESOLVE; then
    resolve_live "${DOMAIN}_subs.txt"
fi
