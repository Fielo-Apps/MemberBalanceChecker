/**
 * @brief       Batch to update member's balance with the SUM of this point's balance
 *
 * @details     Batch does the following algorithm
 *              If member.balance != SUM(Member.Points.Balance)
 *                  if SUM(Member.Points.Balance) < 0
 *                      member.balance = 0
 *                  else
 *                      member.balance = SUM(Member.Points.Balance)
 *              If member.balance != 0 and Member.Points.isEmpty
 *                      member.balance = 0
 */
global with sharing class MemberBalanceCheckBatchSchedule implements Database.Batchable<SObject>, Schedulable{

    global string query;

    global void execute(Schedulablecontext ctx){
        MemberBalanceCheckBatchSchedule batch = new MemberBalanceCheckBatchSchedule();
        Database.executeBatch(batch);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (String.isNotBlank(this.query)) {
            return Database.getQueryLocator(this.query, AccessLevel.SYSTEM_MODE);
        } else {
            return Database.getQueryLocator('SELECT Id, FieloPLT__Program__c FROM FieloPLT__Member__c LIMIT 50000000', AccessLevel.SYSTEM_MODE);
        }
    }

    global void execute(Database.BatchableContext BC, List<FieloPLT__Member__c> scope) {
        try {
            Set<Id> programIds = new Set<Id>();
            Set<String> memberBalanceFields = new Set<String>();

            for(FieloPLT__Member__c m : (List<FieloPLT__Member__c>) scope) {
                programIds.add(m.FieloPLT__Program__c);
            }

            Map<Id, Map<Id,FieloPLT__PointType__c>> programCurrenciesMap = new Map<Id, Map<Id,FieloPLT__PointType__c>>();

            Boolean hasDecimalsField =
                SObjectType.FieloPLT__PointType__c.fields.getMap().containsKey('FieloPLT__DecimalsNumber__c');

            String currencyQuery =
                'SELECT ' +
                    'FieloPLT__Program__c, ' +
                    'FieloPLT__PointType__r.FieloPLT__MemberBalanceField__c ' +
                    (hasDecimalsField ? ',FieloPLT__PointType__r.FieloPLT__DecimalsNumber__c ' : '') +
                'FROM FieloPLT__ProgramPointType__c ' +
                'WHERE FieloPLT__Program__c IN :programIds';

            for (FieloPLT__ProgramPointType__c ppt : Database.query(currencyQuery, AccessLevel.SYSTEM_MODE)) {
                if (programCurrenciesMap.containsKey(ppt.FieloPLT__Program__c)) {
                    programCurrenciesMap.get(ppt.FieloPLT__Program__c).put(ppt.FieloPLT__PointType__c, ppt.FieloPLT__PointType__r);
                } else {
                    programCurrenciesMap.put(ppt.FieloPLT__Program__c, new Map<Id,FieloPLT__PointType__c>{
                            ppt.FieloPLT__PointType__c => ppt.FieloPLT__PointType__r
                        }
                    );
                }
                memberBalanceFields.add(ppt.FieloPLT__PointType__r.FieloPLT__MemberBalanceField__c);
            }

            Map<Id, FieloPLT__Member__c> membersMap = new Map<Id, FieloPLT__Member__c>((List<FieloPLT__Member__c>)Database.query(
                'SELECT Id, FieloPLT__Program__c, ' +
                    String.join(new List<String>(memberBalanceFields), ',') +
                ' FROM FieloPLT__Member__c ' +
                ' WHERE Id IN: scope',
                AccessLevel.SYSTEM_MODE
            ));

            String memberQuery =
                'SELECT Id, '+
                    '(' +
                        'SELECT ' +
                            'Id, ' +
                            'FieloPLT__MemberBalance__c, ' +
                            'FieloPLT__TotalPoints__c ' +
                        'FROM FieloPLT__Points__r ' +
                        'WHERE FieloPLT__PointType__c = :currencyId ORDER BY CreatedDate, Id LIMIT 1' +
                    ') ' +
                'FROM FieloPLT__Member__c WHERE Id =:memberIds';

            Map<Id, Map<Id, Decimal>> firstMemberBalanceByCurrencyByMember = new Map<Id,Map<Id, Decimal>>();
            Map<String, Object> bindMap = new Map<String, Object>{
                'memberIds' => membersMap.keySet()
            };

            for (Id programId : programCurrenciesMap.keySet()) {
                for (FieloPLT__PointType__c curr : programCurrenciesMap.get(programId).values()) {
                    bindMap.put('currencyId',curr.Id);
                    for (FieloPLT__Member__c m : (List<FieloPLT__Member__c>) Database.queryWithBinds(memberQuery,bindMap,AccessLevel.SYSTEM_MODE)) {
                        Decimal firstBalance =
                            m.FieloPLT__Points__r.isEmpty() ?
                                0 :
                                (
                                    (
                                        m.FieloPLT__Points__r.get(0).FieloPLT__MemberBalance__c != null ?
                                        m.FieloPLT__Points__r.get(0).FieloPLT__MemberBalance__c :
                                        0
                                    ) - m.FieloPLT__Points__r.get(0).FieloPLT__TotalPoints__c
                                );

                        if (firstMemberBalanceByCurrencyByMember.containsKey(m.Id)) {
                            firstMemberBalanceByCurrencyByMember.get(m.Id).put(curr.Id, firstBalance);
                        } else {
                            firstMemberBalanceByCurrencyByMember.put(m.Id, new Map<Id, Decimal>{
                                curr.Id => firstBalance
                            });
                        }
                    }
                }
            }

            Map<Id, FieloPLT__Member__c> membersToAdjust = new Map<Id, FieloPLT__Member__c>();
            Map<Id, Set<String>> memberBalances = new Map<Id, Set<String>>();
            FieloPLT__Member__c member;
            String balanceField;
            List<FieloPLT__PointType__c> currencies;

            String aggregateQuery =
                'SELECT ' +
                    'FieloPLT__Member__r.Id memberId, ' +
                    'FieloPLT__PointType__c, ' +
                    'FieloPLT__PointType__r.FieloPLT__MemberBalanceField__c balanceField, ' +
                    'SUM(FieloPLT__Balance__c) BalanceSum, ' +
                    'SUM(FieloPLT__TotalPoints__c) TotalPointsSum ' +
                'FROM FieloPLT__Point__c ' +
                'WHERE FieloPLT__Member__c IN :scope ' +
                'GROUP BY ' +
                    'FieloPLT__Member__r.Id, ' +
                    'FieloPLT__PointType__c, ' +
                    'FieloPLT__PointType__r.FieloPLT__MemberBalanceField__c';

            // Member.Balance and SUM(Member.Points.Balance) MISSMATCH
            Map<String, MemberBalanceStatus__c> monetaryStatus = new Map<String, MemberBalanceStatus__c>();
            String key;
            Decimal balanceSum, totalPointsSum, memberBalance, calcMemberBalance, firstBalance;
            for(AggregateResult pointsBalance : Database.query(aggregateQuery, AccessLevel.SYSTEM_MODE)) {
                member = membersMap.get(String.valueOf(pointsBalance.get('memberId')));
                balanceField = String.valueOf(pointsBalance.get('balanceField'));
                FieloPLT__PointType__c curr = programCurrenciesMap.get(member.FieloPLT__Program__c).get(String.valueOf(pointsBalance.get('FieloPLT__PointType__c')));
                key = member.Id + '-' + curr.Id;
                balanceSum = hasDecimalsField ?
                    currencyValue(pointsBalance.get('BalanceSum'), curr):
                    toFixed(pointsBalance.get('BalanceSum'), 2);
                totalPointsSum = hasDecimalsField ?
                    currencyValue(pointsBalance.get('TotalPointsSum'), curr):
                    toFixed(pointsBalance.get('TotalPointsSum'), 2);
                memberBalance = hasDecimalsField ?
                    currencyValue(member.get(balanceField), curr):
                    toFixed(member.get(balanceField), 2);
                firstBalance = firstMemberBalanceByCurrencyByMember?.get(member.Id)?.get(curr.Id);
                if (firstBalance == null) firstBalance = 0.00;
                calcMemberBalance = hasDecimalsField ?
                    currencyValue(firstBalance + ((Decimal)pointsBalance.get('TotalPointsSum')), curr):
                    toFixed(firstBalance + ((Decimal)pointsBalance.get('TotalPointsSum')), 2);

                if (balanceSum != memberBalance || totalPointsSum != memberBalance) {
                    monetaryStatus.put(key, new MemberBalanceStatus__c(
                        ExternalId__c = key,
                        Member__c = member.Id,
                        Currency__c = curr.Id,
                        MemberBalance__c = toFixed(member.get(balanceField), 2),
                        CalculatedMemberBalance__c = toFixed(calcMemberBalance, 2),
                        PointsBalanceSum__c = toFixed(pointsBalance.get('BalanceSum'), 2),
                        PointsTotalPointsSum__c = toFixed(pointsBalance.get('TotalPointsSum'), 2),
                        BalanceMismatch__c =
                            balanceSum != memberBalance ?
                            'Y' : 'N',
                        TotalPointsMismatch__c =
                            totalPointsSum != memberBalance ?
                            'Y' : 'N',
                        CalculatedMemberBalanceMismatch__c =
                            calcMemberBalance != memberBalance ?
                            'Y' : 'N'
                    ));
                }
                if (memberBalances.containsKey(member.Id)) {
                    memberBalances.get(member.Id).add(balanceField);
                } else {
                    memberBalances.put(member.Id, new Set<String>{balanceField});
                }
            }

            // Members with balance but with no point records
            Set<String> keys = new Set<String>();
            for(FieloPLT__Member__c m : membersMap.values()) {
                currencies = programCurrenciesMap?.get(m.FieloPLT__Program__c)?.values();

                if (currencies == null) continue;

                for(FieloPLT__PointType__c curr : currencies) {
                    key = m.Id + '-' + curr.Id;
                    keys.add(key);
                    balanceField = curr.FieloPLT__MemberBalanceField__c;
                    firstBalance = firstMemberBalanceByCurrencyByMember?.get(m.Id)?.get(curr.Id);
                    if (firstBalance == null) firstBalance = 0.00;
                    calcMemberBalance = hasDecimalsField ?
                        currencyValue(firstBalance, curr):
                        toFixed(firstBalance, 2);
                    if (memberBalances.containsKey(m.Id) && memberBalances?.get(m.Id)?.contains(curr.FieloPLT__MemberBalanceField__c) == false || !memberBalances.containsKey(m.Id)){
                        monetaryStatus.put(key, new MemberBalanceStatus__c(
                            ExternalId__c = key,
                            Member__c = m.Id,
                            Currency__c = curr.Id,
                            MemberBalance__c = toFixed(m.get(balanceField), 2),
                            CalculatedMemberBalance__c = toFixed(calcMemberBalance, 2),
                            PointsBalanceSum__c = toFixed(0, 2),
                            PointsTotalPointsSum__c = toFixed(0, 2),
                            BalanceMismatch__c =
                                toFixed(m.get(balanceField), 2) != toFixed(0, 2) ?
                                    'Y' :
                                    'N',
                            TotalPointsMismatch__c =
                                toFixed(m.get(balanceField), 2) != toFixed(0, 2) ?
                                'Y' :
                                'N',
                            CalculatedMemberBalanceMismatch__c =
                                toFixed(m.get(balanceField), 2) != calcMemberBalance ?
                                'Y' : 'N'
                        ));
                    }
                }
            }

            List<SObject> existingRecords =
                Database.queryWithBinds(
                    'SELECT Id FROM MemberBalanceStatus__c WHERE ExternalId__c = :keys',
                    new Map<String, Object>{
                        'keys' => keys
                    },
                    AccessLevel.SYSTEM_MODE
                );

            List<SObject> failedOnes =
                Database.queryWithBinds(
                    'SELECT Id FROM FailedMembers__c WHERE Member__c = :memberIds',
                    new Map<String, Object>{
                        'memberIds' => new Map<Id,FieloPLT__Member__C>(scope).keySet()
                    },
                    AccessLevel.SYSTEM_MODE
                );

            Database.delete(failedOnes);

            Database.delete(existingRecords);

            Database.upsert(monetaryStatus.values(), MemberBalanceStatus__c.ExternalId__c);

        } catch (Exception e) {
            Map<String, Object> errorJSON = new Map<String, Object>{
                'message' => e.getMessage(),
                'line' => e.getLineNumber(),
                'cause' => e.getCause(),
                'stack' => e.getStackTraceString(),
                'type' => e.getTypeName()
            };
            MBCService.failedRecords(new Map<Id,FieloPLT__Member__C>(scope).keySet(), JSON.serializePretty(errorJSON));
            throw e;
        }
    }

    public static Decimal currencyValue(Object value, FieloPLT__PointType__c curr) {
        return ((Decimal)(value != null ? value : 0.00)).setScale(((Decimal)curr.get('FieloPLT__DecimalsNumber__c')).intValue());
    }

    public static Decimal toFixed(Object value, Integer places) {
        return ((Decimal)(value != null ? value : 0.00)).setScale(places);
    }

    global void finish(Database.BatchableContext BC) {}
}
