Set<String> members = new Set<String>{
    'a0T3f000000GTxeEAG',
    'a0T3f000002F80CEAS'
};

FieloMBC.MemberBalanceCheckBatchSchedule batch = new FieloMBC.MemberBalanceCheckBatchSchedule();
batch.query =
    'SELECT ' +
        'Id, ' +
        'FieloPLT__Program__c ' +
    'FROM FieloPLT__Member__c ' +
    'WHERE Id IN (' +
        '\'' + String.join(new List<String>(members), '\',\'') + '\'' +
    ')';

System.debug('query: ' + batch.query);

Database.executeBatch(batch);