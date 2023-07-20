# !/bin/bash

# If receives an argument create a new scract org with that name, for example InitScratchOrg.sh FL-XXXX
while getopts ":n:h:u:" opt; do
  case $opt in
    n) n_inp="$OPTARG"
    ;;
    h) usage
    ;;
    u) u_inp="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# If receives an argument create a new scract org with that name, for example InitScratchOrg.sh FL-XXXX
if [ $n_inp ]
then
    echo "Creating scratch org" &&
    sfdx force:org:create -f config/project-scratch-def.json --durationdays 15 -a $n_inp orgName=scratchOrg description="PLT: $n_inp" username="scratchOrg@$n_inp.org" -s &&
    echo "Generating Password" &&
    sfdx force:user:password:generate -u $n_inp &&
    echo "Saving Credentials" &&
    sfdx force:user:display -u $n_inp > .local/currentOrg.txt &&
    code -r .local/currentOrg.txt
fi &&

sfdx force:package:install --package 04t2J000000MDhq -w 60 &&

# Push code to Org
sf project deploy start -c -w 60 &&

# Assign Permission Set to user
sfdx force:user:permset:assign --perm-set-name FieloMBCAdmin;