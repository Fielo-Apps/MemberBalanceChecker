public class MBCService {

    public static void failedRecords(Set<Id> recordIds, String message) {
        MBCFailedRecord__e payload = new MBCFailedRecord__e(
            Payload__c = String.join(new List<Id>(recordIds), ','),
            Message__c = message
        );
        // Call method to publish events
        Database.SaveResult result = EventBus.publish(payload);

        // Inspect publishing result for each event
        if (!result.isSuccess()) {
            insertErrors(result.getErrors());
        }
    }

    public static void insertErrors(List<Database.Error> errors){
        List<ErrorLog__c> errorList = new List<ErrorLog__c>();
        for (Database.Error e : errors) {
            errorList.add(
                new ErrorLog__c(
                    Message__c = e.getStatusCode() + ' ' + e.getMessage(),
                    Type__c = 'Database.Error',
                    UserId__c = UserInfo.getUserId()
                )
            );
        }
        insert errorList;
    }

    public static void insertError(Exception except){
        insert new ErrorLog__c(
            LineNumber__c = except.getLineNumber(),
            Message__c = except.getMessage(),
            StackTrace__c = except.getStackTraceString(),
            Type__c = except.getTypeName(),
            UserId__c = UserInfo.getUserId()
        );
    }

    public static void processEvents(List<MBCFailedRecord__e> mbcFailedRecords) {
        List<FailedMembers__c> records = new List<FailedMembers__c>();

        for (MBCFailedRecord__e event : mbcFailedRecords) {
            if(String.isNotBlank(event.Payload__c)) {
                for(String memberId : event.Payload__c.split(',')) {
                    records.add(
                        new FailedMembers__c(
                            Member__c = memberId,
                            Message__c = event.Message__c
                        )
                    );
                }
            }
        }

        insert records;
    }
}