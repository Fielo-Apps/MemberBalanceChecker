FieloMBC.MemberBalanceCheckBatchSchedule batch = new FieloMBC.MemberBalanceCheckBatchSchedule();
batch.query =
    'SELECT Id, FieloPLT__Program__c FROM FieloPLT__Member__c ORDER BY FieloPLT__Program__c';
Database.executeBatch(batch,100);