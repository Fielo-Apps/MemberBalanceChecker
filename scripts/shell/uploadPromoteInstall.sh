# !/bin/bash

versionNumber="1.11.0"

sf package version create --package 0HoHY000000000u0AA -n "${versionNumber}.1" --installation-key-bypass --code-coverage -w 120 --verbose &&

sf package version promote --package "FieloMBC@${versionNumber}-1" -v dev-hub-infra --no-prompt &&

sfdx force:package:install --package "FieloMBC@${versionNumber}-1" --target-org terpel-prod -w 120