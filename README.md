# FieloMBC - Member Balance Checker

Package to detect member balance inconsistency.

## How Do You Run FieloMBC?

- Install the latest version: [FieloMBC 1.7](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tHY0000000VgmYAE)
- Assign the PermissionSet FieloMBCAdmin to your user
- Access in LEX > App Launcher > FieloMBC > Home
- Click on Run
![Alt text](image-1.png)
- Wait for it to finish

## Reading the Results

After the FieloMBC process finishes, the results will be saved in the object `FieloMBC__MemberBalanceStatus__c`

This Object has 6 important fields:
| Field | Description |
| :---: | :---------: |
| Member | (Lookup) Id of the member |