@isTest
public class TestMemberBalanceCheckController {

    @istest
    static void run() {
        Test.startTest();
        MemberBalanceCheckBatchSchedule batch = new MemberBalanceCheckBatchSchedule();
        Database.executeBatch(batch);
        Test.stopTest();

        Map<String, Object> result = (Map<String, Object>) MemberBalanceCheckController.run();

        Assert.isFalse(result.isEmpty());
    }

    @istest
    static void runFailed() {
        Test.startTest();
        MemberBalanceCheckBatchSchedule batch = new MemberBalanceCheckBatchSchedule();
        Database.executeBatch(batch);
        Test.stopTest();

        String errorMessage = '';
        try {
            Map<String, Object> result = (Map<String, Object>) MemberBalanceCheckController.runFailed();
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        Assert.isTrue(String.isNotBlank(errorMessage));
    }

    @istest
    static void getRecord() {
        Test.startTest();
        MemberBalanceCheckBatchSchedule batch = new MemberBalanceCheckBatchSchedule();
        Database.executeBatch(batch);
        Test.stopTest();

        Map<String, Object> result = (Map<String, Object>) MemberBalanceCheckController.getRecord();

        Assert.isFalse(result.isEmpty());
    }
}