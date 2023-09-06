# !/bin/bash

if [ $# -eq 1 ]
then
    sf package version create --package 0HoHY000000000u0AA -n "$1.1" --installation-key-bypass --code-coverage -w 120 &&
    sf package version promote --package "FieloMBC@$1-1" -v dev-hub-infra --no-prompt &&
    result=$(sf package version report --package "FieloMBC@$1-1" --json) &&
    versionId=$(echo ${result} | jq -r ".result.SubscriberPackageVersionId") &&
    scripts/shell/sendPackageEmail.sh "$1" "$versionId"
else
    echo 'missing parameter'
fi