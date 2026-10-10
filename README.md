# Simple Antivirus Daemon

This project is a small antivirus written in bash. It watches a folder, and when something changes in it, it scans the files. Any file that looks malicious is copied to a quarantine folder and deleted from the original folder. There is also a restore script to review the quarantined files.

The monitored folder must contain only files (no subfolders).

## Files in the project

    antivirus-lab/
    |-- antivirusd.sh        the antivirus daemon
    |-- restore.sh           the restore tool
    |-- common.sh            functions shared between the scripts
    |-- antivirus-cron.sh    the cron version of the daemon (bonus 1)
    |-- Makefile             to run everything with make
    |-- README.md            this file

These files are created while running: `directory-info.last`, `directory-info.new` and `whitelist.txt`.

## How it works

1. The daemon runs `ls -l` on the folder and saves it in `directory-info.new`.
2. It compares it with `directory-info.last` using `diff`.
3. If this is the first run, or the two files are different, it scans the folder and then copies `directory-info.new` to `directory-info.last`.
4. If they are the same, it just waits and checks again.
5. For each malicious file it prints `<file> is malicious and it is DELETED`, copies it to `malicious_dir`, and deletes the original.

## Prerequisites (Linux)

Bash, grep, diff and sha256sum are already installed on Ubuntu. I only need make (and cron for the bonus):

    sudo apt update
    sudo apt install make cron

## How to run

Antivirus daemon (press Ctrl+C to stop it):

    make run

The default values are `dir=test_dir`, `malicious_dir=malicious_dir` and `interval=5`. They can be changed like this:

    make run dir=my_folder malicious_dir=my_quarantine interval=3

Restore tool (do not run it at the same time as the daemon):

    make restore

It shows the quarantined files with numbers. I pick a file by its number, then choose:
- 1: restore the file back to the folder (it was a false positive)
- 2: delete the file permanently
- 3: leave it and go back to the list

Before running, the Makefile creates `malicious_dir` if it does not exist (the `setup` target).

## Where the flagged lists are

At the top of `common.sh`:

    flagged_extensions=(".exe" ".bat" ".vbs" ".scr" ".ps1")
    flagged_keywords=("virus" "trojan" "malware" "worm" "ransomware")

## Bonus 1: Cron job

`antivirus-cron.sh` does one check and scan, and then it ends. Cron runs it every minute.

Before starting:
- cron must be installed and running: `sudo apt install cron` then `sudo systemctl enable --now cron`
- the scripts must be executable: `make setup`
- use full paths (not relative paths) in the cron line

Steps:
1. Open the crontab: `crontab -e`
2. Add this line at the end (change the paths to yours):

        * * * * * sleep 23; /home/zisa/antivirus-lab/antivirus-cron.sh /home/zisa/antivirus-lab/test_dir /home/zisa/antivirus-lab/malicious_dir >> /home/zisa/antivirus-cron.log 2>&1

3. Save and exit, then check with `crontab -l`.
4. Put a bad file in the folder and wait about 1.5 minutes. The result is written in `antivirus-cron.log`.

Cron cannot run on a second, it only knows minutes. So the job starts at second 0 and `sleep 23` makes the script start at second 23.

Cron expression to run it every 3rd Friday of the month at 12:31 am:

    31 0 15-21 * * [ "$(date +\%u)" = 5 ] && /home/zisa/antivirus-lab/antivirus-cron.sh /home/zisa/antivirus-lab/test_dir /home/zisa/antivirus-lab/malicious_dir

The 3rd Friday is always between day 15 and day 21 of the month. If I write both the day of the month and the day of the week in cron, it runs when either one matches, so I only put the days 15-21 and check that today is Friday with `date +%u` (5 means Friday). The `%` has a backslash before it because cron treats `%` in a special way.

## Bonus 2: Whitelist

- When I restore a file with option 1 in `restore.sh`, the script saves the file hash (sha256) and the file name in `whitelist.txt`. This file stays after stopping the daemon, so it is remembered when the daemon starts again.
- When the daemon scans, it calculates the hash of each file and looks for the hash and the name in `whitelist.txt` (function `is_whitelisted` in `common.sh`). If they are found, the file is skipped and not flagged.
- If a whitelisted file is changed later, its hash changes, so it will be scanned again.
