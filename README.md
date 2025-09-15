# Subdomain Finder

**piyu.sh** is an advanced Bash-based subdomain enumeration tool designed to work similarly to tools like *amass* and *subfinder*. It uses multiple data sources, optional brute-forcing, and optional live-host resolution. Built for bug bounty hunters, pentesters, and security professionals who want a versatile and extendable tool without pulling in heavy dependencies.

---

## ⚙️ Features

- Enumerates subdomains from multiple sources:
  - Certificate Transparency logs via `crt.sh`
  - HackerTarget API
  - ThreatCrowd API
  - Tools like `assetfinder`, `subfinder`, `amass` (if installed)
- Optional *brute-force* mode using a wordlist (in `wordlists/top-subdomains.txt`)
- Optional *live resolution* of subdomains (filters only *reachable* ones)
- Clean, deduplicated output
- Useful CLI interface with color-coded informational messages
- Simple dependencies: `curl`, `jq`, `dig` etc.

---

## 🛠️ Requirements / Dependencies

Make sure you have the following installed:

- `bash`
- `curl`
- `jq`
- `dig` (usually part of `dnsutils`)
- Optionally:
  - `assetfinder`
  - `subfinder`
  - `amass`

Also have a wordlist ready for brute-force mode (e.g. `wordlists/top-subdomains.txt`).

---

## 📂 Installation / Setup

1. Clone or copy the tool into a folder:
   ```bash
   https://github.com/sherrysharmaPp123/subdomain.git

2. Make the script executable:

   chmod +x piyush.sh

4. Ensure dependencies are installed:

   sudo apt update
   sudo apt install -y curl jq dnsutils
# Also install other tools if you plan to use them, like:

   https://github.com/tomnomnom/assetfinder@latest
   https://github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
   https://github.com/owasp-amass/amass/v3/...@latest

4. Prepare the wordlist if using brute force (put it in wordlists/top-subdomains.txt).

🚀 Usage

Basic usage:

  bash piyu.sh -d example.com

Enable brute-force:

 bash piyu.sh -d example.com -b

Enable live resolution (show only subdomains that resolve):
 
 bash piyu.sh -d example.com -r

Combine both:
 
 bash piyu.sh -d example.com -b -r

📁 Output

The script saves discovered subdomains in example.com_subs.txt

If live resolution is used, results are in example.com_live.txt

Brute-forced subdomains (if any) are included in the main output

🔍 Example

Here’s how it might look:
$ ./piyu.sh -d example.com -b -r
[Banner]
[+] Target domain: example.com
[+] Trying crt.sh...
[+] Trying HackerTarget...
[!] ThreatCrowd returned no data
[+] Running assetfinder...
[+] Running subfinder...
[+] Running amass (passive)...
[*] Running brute-force with wordlist: wordlists/top-subdomains.txt
[✓] Found 25 unique subdomains
[✓] Results saved to example.com_subs.txt
[✓] Live subdomains saved to: example.com_live.txt

