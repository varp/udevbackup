UDEV_RULE_FILE=99-udevbackup.rules
BACKUP_SCRIPT=udevbackup.sh

configure:
	@if [ -z $(SMB_DOMAIN) ];	then echo "ERROR: SMB_DOMAIN is not provided"; exit 99 ; fi
	@if [ -z $(SMB_SHARE) ];	then echo "ERROR: SMB_SHARE is not provided"; exit 99 ; fi
	@if [ -z $(SMB_USER) ]; then echo "ERROR: SMB_USER is not provided"; exit 99; fi
	@if [ -z $(SMB_PASSWORD) ]; then echo "ERROR: SMB_PASSWORD is not provided"; exit 99; fi
	@if [ -z $(HARD_SERIAL) ]; then	echo "ERROR: HARD_SERIAL is not provided"; exit 99; fi

	@cat ./$(BACKUP_SCRIPT) | sed -e 's|\[\[SMB_SHARE\]\]|$(SMB_SHARE)|g' -e 's/\[\[SMB_USER\]\]/$(SMB_USER)/g' -e 's/\[\[SMB_PASSWORD\]\]/$(SMB_PASSWORD)/g' -e 's/\[\[SMB_DOMAIN\]\]/$(SMB_DOMAIN)/g'	> ./script.tmp
	@cat ./script.tmp > ./$(BACKUP_SCRIPT) && rm -f ./script.tmp

	@cat ./$(UDEV_RULE_FILE) | sed -e 's/\[\[HARD_SERIAL\]\]/$(HARD_SERIAL)/g' -e 's|\[\[BACKUP_SCRIPT\]\]|`pwd`/$(BACKUP_SCRIPT)|g' > ./rule.tmp
	@cat ./rule.tmp > ./$(UDEV_RULE_FILE) && rm -f ./rule.tmp


install:
	@chmod 400 ./$(UDEV_RULE_FILE)
	@chmod 500 ./$(BACKUP_SCRIPT)
	@ln -s `pwd`/$(UDEV_RULE_FILE) /etc/udev/rules.d/$(UDEV_RULE_FILE)

uninstall:
	@rm -vf /etc/udev/rules.d/$(UDEV_RULE_FILE)