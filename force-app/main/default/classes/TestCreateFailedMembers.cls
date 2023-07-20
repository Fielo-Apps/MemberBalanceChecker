@isTest
public class TestCreateFailedMembers {

    @isTest
    static void createFailedMembers() {
        FieloPLT__Program__c program = TestUtils.createPrograms('Program', 1)[0];
        insert program;

        List<FieloPLT__Member__c> members = TestUtils.createIndividualAccounts('Member ', 4, program.Id);
        insert members;

        Test.startTest();
            MBCService.failedRecords(new Map<Id,FieloPLT__Member__C>(members).keySet(), 'error');
            Test.getEventBus().deliver();
        Test.stopTest();

        List<FailedMembers__c> failures = [SELECT Id, Member__c, Message__c FROM FailedMembers__c];

        Assert.areEqual(4, failures.size(), 'Wrong number of records created');
        Set<Id> memberIds = new Set<Id>(new Map<Id,FieloPLT__Member__c>(members).keySet());

        for (FailedMembers__c fail : failures) {
            Assert.areEqual('error', fail.Message__c);
            memberIds.remove(fail.Member__c);
        }

        Assert.isTrue(memberIds.isEmpty());
    }
}