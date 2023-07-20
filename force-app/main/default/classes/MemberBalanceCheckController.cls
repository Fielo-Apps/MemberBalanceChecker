public class MemberBalanceCheckController {

    public
    static final Set<String> ACTIVE_BATCH_STATUS = new Set<String>{'Holding','Queued','Preparing','Processing'};

    @AuraEnabled
    public static object run(){
        List<AsyncApexJob> aajs = [
            SELECT
                Id
            FROM AsyncApexJob
            WHERE
                JobType = 'BatchApex' AND
                ApexClass.NamespacePrefix = 'FieloMBC' AND
                ApexClass.Name = 'MemberBalanceCheckBatchSchedule' AND
                Status IN :ACTIVE_BATCH_STATUS
            ];
        if (aajs.isEmpty() == false) throw new FieloPLT.FieloException('Member Balance Check is already running');

        MemberBalanceCheckBatchSchedule batch = new MemberBalanceCheckBatchSchedule();
        Database.executeBatch(batch);
        return getRecord();
    }

    @AuraEnabled
    public static object runFailed(){
        List<FailedMembers__c> failures = [SELECT Member__c FROM FailedMembers__c];

        if (failures.isEmpty()) throw new FieloPLT.FieloException('There are no failures to be reprocessed');

        List<AsyncApexJob> aajs = [
            SELECT
                Id
            FROM AsyncApexJob
            WHERE
                JobType = 'BatchApex' AND
                ApexClass.NamespacePrefix = 'FieloMBC' AND
                ApexClass.Name = 'MemberBalanceCheckBatchSchedule' AND
                Status IN :ACTIVE_BATCH_STATUS
            ];
        if (aajs.isEmpty() == false) throw new FieloPLT.FieloException('Member Balance Check is already running');

        MemberBalanceCheckBatchSchedule batch = new MemberBalanceCheckBatchSchedule();
        batch.query =
            'SELECT '+
                'Id, ' +
                'FieloPLT__Program__c ' +
            'FROM FieloPLT__Member__c ' +
            'WHERE Id IN (SELECT Member__c FROM FailedMembers__c) ' +
            'LIMIT 50000000';
        Database.executeBatch(batch);
        return getRecord();
    }

    @AuraEnabled
    public static object getRecord(){
        List<AsyncApexJob> aajs = [
            SELECT
                Id,
                JobType,
                Status,
                CreatedDate,
                CompletedDate,
                TotalJobItems,
                JobItemsProcessed,
                NumberOfErrors,
                ExtendedStatus
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
                AND ApexClass.NamespacePrefix = 'FieloMBC'
                AND ApexClass.Name = 'MemberBalanceCheckBatchSchedule'
            ORDER BY
                CreatedDate DESC,
                Id DESC
            ];
        if (aajs.isEmpty()) {
            return null;
        } else {
            Long dt1Long = aajs.get(0).CompletedDate != null ?
                aajs.get(0).CompletedDate.getTime() :
                DateTime.now().getTime();
            Long dt2Long = aajs.get(0).CreatedDate.getTime();
            Long milliseconds = dt1Long - dt2Long;
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            Long hours = minutes / 60;
            Long days = hours / 24;

            Integer day_ms = 86400000;
            Integer hour_ms = 3600000;
            Integer minute_ms = 60000;
            Integer second_ms =  1000;

            String elapsedTime = String.format(
                '{0}d {1}h {2}m {3}s',
                new List<String>{
                    String.valueOf(Math.abs(milliseconds/day_ms)),
                    String.valueOf(Math.abs(Math.mod(milliseconds,day_ms)/hour_ms)),
                    String.valueOf(Math.abs(Math.mod(milliseconds,hour_ms)/minute_ms)),
                    String.valueOf(Math.abs(Math.mod(milliseconds,minute_ms)/second_ms))
                }
            );

            Long msPerItem = milliseconds / getDivider(aajs.get(0).JobItemsProcessed).intValue();
            Long totalETA = msPerItem * (aajs.get(0).TotalJobItems - aajs.get(0).JobItemsProcessed);

            String eta = String.format(
                '{0}d {1}h {2}m {3}s',
                new List<String>{
                    String.valueOf(Math.abs(totalETA/day_ms)),
                    String.valueOf(Math.abs(Math.mod(totalETA,day_ms)/hour_ms)),
                    String.valueOf(Math.abs(Math.mod(totalETA,hour_ms)/minute_ms)),
                    String.valueOf(Math.abs(Math.mod(totalETA,minute_ms)/second_ms))
                }
            );

            String progress = String.valueOf(
                ((aajs.get(0).JobItemsProcessed / getDivider(aajs.get(0).TotalJobItems) )*100.00).setScale(2)
            ) + '%';

            return new Map<String, Object> {
                'submittedOn' => aajs.get(0).CreatedDate,
                'completedOn' => aajs.get(0).CompletedDate,
                'progress' => aajs.get(0).CompletedDate != null || aajs.get(0).Status == 'Completed' ?
                    '100.00%' :
                    progress,
                'totalJobItems' => aajs.get(0).TotalJobItems,
                'jobItemsProcessed' => aajs.get(0).JobItemsProcessed,
                'numberOfErrors' => aajs.get(0).NumberOfErrors,
                'elapsedTime' => elapsedTime,
                'eta' => aajs.get(0).CompletedDate != null ?
                    '' :
                    aajs.get(0).TotalJobItems != null && aajs.get(0).TotalJobItems > 0 ?
                        eta :
                        ''
            };
        }
    }

    public static Decimal getDivider(Decimal value) {
        return value != null && value != 0 ?
            value :
            1;
    }
}