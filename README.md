# FieloMBC - Member Balance Checker

Package to detect member balance inconsistency.

## Requirements

- FieloPLT 2.56.23 or newer.

## How Do You Run FieloMBC?

- Install the latest version: [FieloMBC 1.11.0](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tHY0000000VktYAE)
- Assign the PermissionSet FieloMBCAdmin to your user
- Access in `Lightning Experience > App Launcher > FieloMBC > Home`
- Click on Run
![Alt text](image-1.png)
- Wait for it to finish
- If the package is no longer needed, unassign the permission set and uninstall it in `Setup > Installed Packages`

## Reading the Results

After the FieloMBC process finishes, the results will be saved in the object `FieloMBC__MemberBalanceStatus__c`

This Object has the following fields:
| Field | Description |
| :---- | :---------- |
| Member | (Lookup) Id of the member |
| Currency | (Lookup) Id of currency |
| Member Balance | (Decimal) Current Member Balance |
| Calculated Member Balance | (Decimal) Member Balance prior to all points plus "Points Total Sum" |
| Points Balance Sum | (Decimal) Sum of all point records Balance field of the member |
| Points Total Sum | (Decimal) Sum of all point records Total Points field of the member |
| Calculated Member Balance Mismatch | (Flag) Y if there is a mismatch between Member Balance and Calculated Member Balance, N otherwise |
| Balance Mismatch | (Flag) Y if there is a mismatch between Member Balance and Points Balance Sum, N otherwise |
| Total Points Mismatch | (Flag) Y if there is a mismatch between Member Balance and Points Total Points Sum, N otherwise |

## Which Mismatch flag should You use?

- **Total Points Mismatch** if you have the entire points history in the database
- **Balance Mismatch** if you don't have negative accruals
- **Calculated Member Balance** if you want to check if member balance was rolled up correctly

## Getting the results
Currently we don't have the results displayed in a fancy way in the UI. One must go and query the `FieloMBC__MemberBalanceStatus__c`.
```SQL
SELECT
    FieloMBC__Member__c,
    FieloMBC__Member__r.Name,
    FieloMBC__Currency__r.Name,
    FieloMBC__MemberBalance__c,
    FieloMBC__CalculatedMemberBalance__c,
    FieloMBC__PointsBalanceSum__c,
    FieloMBC__BalanceMismatch__c,
    FieloMBC__CalculatedMemberBalanceMismatch__c
FROM FieloMBC__MemberBalanceStatus__c
WHERE FieloMBC__BalanceMismatch__c = 'Y'
```
In this example we are getting all the members that have a Balance mismatch `FieloMBC__BalanceMismatch__c = 'Y'`

## Searching for issues
Failures may happen, like if the environment is heavily used we can face some `Unable do lock row` issues. One can check what happened in the object `FieloMBC__FailedMembers__c`
```SQL
SELECT FieloMBC__Member__c, FieloMBC__Message__c FROM FieloMBC__FailedMembers__c
```
if any rows are returned, one must go to the app again and click on `Run failed`