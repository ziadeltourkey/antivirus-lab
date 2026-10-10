# elvariables mmken yb2o overridden: hn3ml run DIR=/some/path w el interval=2
DIR ?= test_dir
MALICIOUS_DIR ?= malicious_dir
INTERVAL ?= 5

.PHONY: run restore setup clean

# default target: start the antivirus daemon
run: setup
	./antivirusd.sh $(DIR) $(MALICIOUS_DIR) $(INTERVAL)

# hn run elrestore tool
restore: setup
	./restore.sh $(DIR) $(MALICIOUS_DIR)

# hena hn5li el scripts executable
# whn create directories if missing
setup:
	chmod +x antivirusd.sh restore.sh antivirus-cron.sh common.sh
	mkdir -p $(MALICIOUS_DIR)
	mkdir -p $(DIR)

# remove snapshot files
clean:
	rm -f directory-info.last directory-info.new
