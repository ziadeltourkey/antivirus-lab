# Simple Antivirus Daemon (Shell + Makefile)

A simplified antivirus written in Bash. A daemon polls a directory, and when it changes, scans it for malicious files, copies them into a quarantine directory, and deletes the originals. A restore tool lets you review quarantined files. Includes the cron and whitelist bonuses.

> Assumption (from the lab): the monitored directory contains only files, no subdirectories.

## 1. Overview and folder hierarchy

```
.
├── antivirusd.sh        # Part 1: daemon (loops forever with sleep)
├── restore.sh           # Part 2: interactive restore/delete tool
├── common.sh            # shared functions + flagged lists + whitelist logic
├── antivirus-cron.sh    # Bonus 1: one-shot scan for cron
├── Makefile             # Part 3: run / restore / setup targets
├── README.md            # this file
├── whitelist.txt        # created automatically by restore.sh (Bonus 2)
├── directory-info.last  # created at runtime: previous directory snapshot
└── directory-info.new   # created at runtime: current directory snapshot
```

How it works:
1. The daemon runs `ls -l dir > directory-info.new` every `interval-secs`.
2. It compares that with `directory-info.last` using `diff`.
3. First run (no `.last` file) or a difference -> scan `dir`, then `cp directory-info.new directory-info.last`. No difference -> wait and repeat.
4. For each malicious file it prints `<file> is malicious and it is DELETED`, copies it to `malicious_dir`, and deletes the original.

(Note: deleting files changes the listing, so one extra harmless scan may run right after a quarantine. It finds nothing and the snapshots then match.)

## 2. Prerequisites (Linux)

```bash
sudo apt update
sudo apt install -y bash make coreutils grep diffutils
```
Most of these are already installed. For Bonus 1 you also need `cron`:
```bash
sudo apt install -y cron
sudo systemctl enable --now cron
```

## 3. Running

Defaults: `dir=test_dir`, `malicious_dir=malicious_dir`, `interval=5`. Override on the command line.

**Antivirus daemon** (Ctrl+C to stop):
```bash
make                       # same as: make run
make run dir=/path/to/dir malicious_dir=/path/to/quarantine interval=3
# or directly:
./antivirusd.sh test_dir malicious_dir 5
```
The `setup` pre-build step runs automatically: it makes scripts executable and creates `malicious_dir` (and `dir`) if missing.

**Restore tool** (do not run at the same time as the daemon):
```bash
make restore
# or: ./restore.sh test_dir malicious_dir
```
Pick a file by number, then choose:
- `1` restore to `dir` (false positive) -> prints `Restored <file> to <dir>.`
- `2` permanently delete -> prints `<file> permanently deleted.`
- `3` leave it and go back to the list

If quarantine is empty it prints `No malicious files to review.` Enter `q` to quit.

**Quick test:**
```bash
mkdir -p test_dir
echo "hello" > test_dir/ok.txt
echo "this has a Trojan" > test_dir/notes.txt
touch test_dir/setup.exe
make run interval=2        # notes.txt and setup.exe get quarantined
```

## 4. Where the flagged lists are defined

Both are at the top of **`common.sh`**:

```bash
flagged_extensions=(".exe" ".bat" ".vbs" ".scr" ".ps1")
flagged_keywords=("virus" "trojan" "malware" "worm" "ransomware")
```
Extensions are matched against the end of the filename; keywords are matched case-insensitively in the file content (`grep -i`).

## 5. Bonus 1: Cron job

`antivirus-cron.sh dir malicious_dir` performs one check-and-scan pass (same logic as the daemon, no loop). Its snapshot files are stored next to the scripts because cron's working directory is unpredictable.

**Prerequisites:** cron installed and running (`sudo systemctl status cron`), scripts executable (`make setup`), and the monitored directory existing. Always use **absolute paths**.

**Steps:**
1. `cd` into the project and note the path with `pwd` (e.g. `/home/zisa/antivirus-lab`).
2. `make setup`
3. Open your crontab: `crontab -e`
4. Cron only has minute resolution, so to run at **second 23** of every minute, wait 23 seconds before the script:
   ```
   * * * * * sleep 23; /home/zisa/antivirus-lab/antivirus-cron.sh /home/zisa/antivirus-lab/test_dir /home/zisa/antivirus-lab/malicious_dir >> /home/zisa/antivirus-cron.log 2>&1
   ```
5. Save and exit. Verify with `crontab -l`, and watch `tail -f ~/antivirus-cron.log`.
6. To remove it, run `crontab -e` and delete the line.

**Every 3rd Friday of the month at 12:31 am:**
```
31 0 15-21 * * [ "$(date +\%u)" = 5 ] && /home/zisa/antivirus-lab/antivirus-cron.sh /home/zisa/antivirus-lab/test_dir /home/zisa/antivirus-lab/malicious_dir
```
Explanation: `31 0` = 00:31; the 3rd Friday always falls on day 15 to 21, so `15-21` is the day-of-month. In cron, if both day-of-month and day-of-week are restricted they are OR-ed, so day-of-week is left as `*` and the `date +%u` test (5 = Friday) enforces Friday. The `%` is escaped as `\%` because cron treats a bare `%` as a newline.

## 6. Bonus 2: Whitelist

- **File:** `whitelist.txt` in the same folder as the scripts (override with the `whitelist_file` env variable). It persists across daemon restarts because it is a plain file.
- **How a file gets added:** when you choose option 1 (restore) in `restore.sh`, before moving the file back it appends the line `<sha256 hash>  <filename>` to `whitelist.txt`.
- **How the daemon checks it:** in `scan_directory` (`common.sh`), before the malicious checks, `is_whitelisted` computes the file's SHA-256 and looks for the exact line `<hash>  <filename>` with `grep -qxF`. If found, the file is skipped.
- Because the content hash is stored, if a whitelisted file is later modified, it will be scanned again.
