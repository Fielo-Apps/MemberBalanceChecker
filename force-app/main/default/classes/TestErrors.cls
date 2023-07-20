@isTest
public class TestErrors {

    @istest
    static void insertDBErrors() {
        Database.SaveResult result = Database.insert(new FieloPLT__Member__c(), false);

        MBCService.insertErrors(result.getErrors());

        List<ErrorLog__c> errors = [SELECT Id FROM ErrorLog__c];

        Assert.isFalse(errors.isEmpty());
    }

    @istest
    static void insertErrors() {
        try {
            throw new FieloPLT.FieloException('ERROR');
        } catch (Exception e) {
            MBCService.insertError(e);
        }

        List<ErrorLog__c> errors = [SELECT Id FROM ErrorLog__c];

        Assert.isFalse(errors.isEmpty());
    }
}