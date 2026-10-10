# elvariables momken yb2o overridden: hn3ml run dir=/some/path w el interval=2
dir ?= test_dir
malicious_dir ?= malicious_dir
interval ?= 5

.PHONY: run restore setup clean
# default target: start the antivirus daemon
run: setup
	./antivirusd.sh $(dir) $(malicious_dir) $(interval)

# hn run elrestore tool
restore: setup
	./restore.sh $(dir) $(malicious_dir)

# hena hn5li el scripts executable
# whn create directories if missing
setup:
	chmod +x antivirusd.sh restore.sh antivirus-cron.sh common.sh
	mkdir -p $(malicious_dir)
	mkdir -p $(dir)

# remove snapshot files
clean:
	rm -f directory-info.last directory-info.new
