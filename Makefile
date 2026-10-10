# Variables can be overridden: make run DIR=/some/path INTERVAL=2
DIR          ?= test_dir
MALICIOUS_DIR ?= malicious_dir
INTERVAL     ?= 5

.PHONY: run restore setup clean

# Default target: start the antivirus daemon
run: setup
	./antivirusd.sh $(DIR) $(MALICIOUS_DIR) $(INTERVAL)

# Run the restore tool
restore: setup
	./restore.sh $(DIR) $(MALICIOUS_DIR)

# Pre-build step: make scripts executable and create directories if missing
setup:
	chmod +x antivirusd.sh restore.sh antivirus-cron.sh common.sh
	mkdir -p $(MALICIOUS_DIR)
	mkdir -p $(DIR)

# Remove snapshot files
clean:
	rm -f directory-info.last directory-info.new
