@istest
public class TestMemberBalanceCheckBatchSchedule {
    @isTest
    static void checkBalances() {
        FieloPLT__Program__c program = TestUtils.createPrograms('Program', 1)[0];
        insert program;

        List<FieloPLT__Member__c> members = TestUtils.createIndividualAccounts('Member ', 4, program.Id);
        members.get(0).Name = 'Zero Balance Member';
        members.get(1).Name = 'Mismatch Balance Member';
        members.get(2).Name = 'Negative Balance Member';
        members.get(3).Name = 'Dont Touch Member';
        insert members;

        FieloPLT.SOBjectService.enableAdminPermission(true);
        update new FieloPLT__Member__c(
            Id = members.get(0).Id,
            FieloPLT__Points__c = 100
        );
        FieloPLT.SOBjectService.enableAdminPermission(false);

        List<FieloPLT__Transaction__c> transactions = new List<FieloPLT__Transaction__c>{
            new FieloPLT__Transaction__c(FieloPLT__Member__c = members.get(1).Id, FieloPLT__isAdjust__c = true, FieloPLT__Points__c = 50),
            new FieloPLT__Transaction__c(FieloPLT__Member__c = members.get(1).Id, FieloPLT__isAdjust__c = true, FieloPLT__Points__c = 50),
            new FieloPLT__Transaction__c(FieloPLT__Member__c = members.get(2).Id, FieloPLT__isAdjust__c = true, FieloPLT__Points__c = 50),
            new FieloPLT__Transaction__c(FieloPLT__Member__c = members.get(2).Id, FieloPLT__isAdjust__c = true, FieloPLT__Points__c = -50),
            new FieloPLT__Transaction__c(FieloPLT__Member__c = members.get(3).Id, FieloPLT__isAdjust__c = true, FieloPLT__Points__c = 100)
        };

        Id zeroBalanceMember = members.get(0).Id;
        Id missMatchBalanceMember = members.get(1).Id;
        Id negativeBalanceMember = members.get(2).Id;
        Id dontTouchMember = members.get(3).Id;

        insert transactions;

        FieloPLT.SOBjectService.enableAdminPermission(true);
        Set<Id> transactionsToDeletePoints = new Set<Id>{transactions.get(1).Id,transactions.get(2).Id};
        delete [SELECT Id FROM FieloPLT__Point__c WHERE FieloPLT__Transaction__c IN :transactionsToDeletePoints];
        FieloPLT.SOBjectService.enableAdminPermission(false);

        members = [SELECT Id, Name, FieloPLT__Points__c FROM FieloPLT__Member__c WHERE Id IN :members];

        Test.startTest();
            Database.executeBatch(new MemberBalanceCheckBatchSchedule());
        Test.stopTest();

        Map<Id, FieloPLT__Member__c> membersMap = new Map<Id, FieloPLT__Member__c>([SELECT Id, Name, FieloPLT__Points__c FROM FieloPLT__Member__c WHERE Id IN :members]);

        Map<Id, Decimal> calculatedMemberBalances = new Map<Id, Decimal>();
        for(AggregateResult memberBalance : [SELECT FieloPLT__Member__r.Id memberId, FieloPLT__PointType__c, FieloPLT__PointType__r.FieloPLT__MemberBalanceField__c balanceField, SUM(FieloPLT__Balance__c) CalculatedBalance FROM FieloPLT__Point__c WHERE FieloPLT__Member__c IN :members GROUP BY FieloPLT__Member__r.Id, FieloPLT__PointType__c, FieloPLT__PointType__r.FieloPLT__MemberBalanceField__c]) {
            calculatedMemberBalances.put(Id.valueOf(String.valueOf(memberBalance.get('memberId'))),((Decimal)memberBalance.get('CalculatedBalance')));
        }

        for (FieloPLT__Member__c m : members) {
            Assert.areEqual(m.FieloPLT__Points__c, membersMap.get(m.Id).FieloPLT__Points__c, 'Wrong balance for "' + m.Name + '"');
        }

        String memberBalanceQuery =
            'SELECT ' +
                String.join(new List<String>(SObjectType.MemberBalanceStatus__c.fields.getMap().keySet()), ',') +
            ' FROM MemberBalanceStatus__c';

        Map<String, MemberBalanceStatus__c> mbsMap = new Map<String, MemberBalanceStatus__c>();
        for (MemberBalanceStatus__c mbs : (List<MemberBalanceStatus__c>)Database.query(memberBalanceQuery)) {
            mbsMap.put(mbs.ExternalId__c, mbs);
        }

        List<FieloPLT__PointType__c> currencies = [SELECT Id, Name FROM FieloPLT__PointType__c];

        String zeroBalanceMemberKey = members.get(0).Id + '-' + currencies.get(0).Id;
        String missMatchBalanceMemberKey = members.get(1).Id + '-' + currencies.get(0).Id;
        String negativeBalanceMemberKey = members.get(2).Id + '-' + currencies.get(0).Id;
        String dontTouchMemberKey = members.get(3).Id + '-' + currencies.get(0).Id;

        Assert.isTrue(mbsMap.containsKey(zeroBalanceMemberKey), 'Member "' + members.get(0).Name + '" should have a balance status');
        Assert.isTrue(mbsMap.containsKey(missMatchBalanceMemberKey), 'Member "' + members.get(1).Name + '" should have a balance status');
        Assert.isTrue(mbsMap.containsKey(negativeBalanceMemberKey), 'Member "' + members.get(2).Name + '" should have a balance status');
        Assert.isFalse(mbsMap.containsKey(dontTouchMemberKey), 'Member "' + members.get(3).Name + '" should have a balance status');

        Assert.isNull(mbsMap.get(dontTouchMemberKey));

        Assert.areEqual(members.get(0).FieloPLT__Points__c?.setScale(2), mbsMap.get(zeroBalanceMemberKey)?.MemberBalance__c?.setScale(2));
        Assert.areEqual(members.get(1).FieloPLT__Points__c?.setScale(2), mbsMap.get(missMatchBalanceMemberKey)?.MemberBalance__c?.setScale(2));
        Assert.areEqual(members.get(2).FieloPLT__Points__c?.setScale(2), mbsMap.get(negativeBalanceMemberKey)?.MemberBalance__c?.setScale(2));

        Assert.areEqual((100.00).setScale(2), mbsMap.get(zeroBalanceMemberKey)?.MemberBalance__c?.setScale(2));
        Assert.areEqual((100.00).setScale(2), mbsMap.get(missMatchBalanceMemberKey)?.MemberBalance__c?.setScale(2));
        Assert.areEqual((0.00).setScale(2), mbsMap.get(negativeBalanceMemberKey)?.MemberBalance__c?.setScale(2));

        Assert.areEqual(currencies.get(0).Id, mbsMap.get(zeroBalanceMemberKey)?.Currency__c);
        Assert.areEqual(currencies.get(0).Id, mbsMap.get(missMatchBalanceMemberKey)?.Currency__c);
        Assert.areEqual(currencies.get(0).Id, mbsMap.get(negativeBalanceMemberKey)?.Currency__c);

        Assert.areEqual(members.get(0).Id, mbsMap.get(zeroBalanceMemberKey).Member__c);
        Assert.areEqual(members.get(1).Id, mbsMap.get(missMatchBalanceMemberKey).Member__c);
        Assert.areEqual(members.get(2).Id, mbsMap.get(negativeBalanceMemberKey).Member__c);

        Assert.areEqual(  0, mbsMap.get(zeroBalanceMemberKey).PointsBalanceSum__c);
        Assert.areEqual( 50, mbsMap.get(missMatchBalanceMemberKey).PointsBalanceSum__c);
        Assert.areEqual(  0, mbsMap.get(negativeBalanceMemberKey).PointsBalanceSum__c);

        Assert.areEqual(  0, mbsMap.get(zeroBalanceMemberKey).PointsTotalPointsSum__c);
        Assert.areEqual( 50, mbsMap.get(missMatchBalanceMemberKey).PointsTotalPointsSum__c);
        Assert.areEqual(-50, mbsMap.get(negativeBalanceMemberKey).PointsTotalPointsSum__c);

        Assert.areEqual(  0, mbsMap.get(zeroBalanceMemberKey).CalculatedMemberBalance__c);
        Assert.areEqual( 50, mbsMap.get(missMatchBalanceMemberKey).CalculatedMemberBalance__c);
        Assert.areEqual(  0, mbsMap.get(negativeBalanceMemberKey).CalculatedMemberBalance__c);

        Assert.areEqual('Y', mbsMap.get(zeroBalanceMemberKey).BalanceMismatch__c);
        Assert.areEqual('Y', mbsMap.get(missMatchBalanceMemberKey).BalanceMismatch__c);
        Assert.areEqual('N', mbsMap.get(negativeBalanceMemberKey).BalanceMismatch__c);

        Assert.areEqual('Y', mbsMap.get(zeroBalanceMemberKey).TotalPointsMismatch__c);
        Assert.areEqual('Y', mbsMap.get(missMatchBalanceMemberKey).TotalPointsMismatch__c);
        Assert.areEqual('Y', mbsMap.get(negativeBalanceMemberKey).TotalPointsMismatch__c);

        Assert.areEqual('Y', mbsMap.get(zeroBalanceMemberKey).CalculatedMemberBalanceMismatch__c);
        Assert.areEqual('Y', mbsMap.get(missMatchBalanceMemberKey).CalculatedMemberBalanceMismatch__c);
        Assert.areEqual('N', mbsMap.get(negativeBalanceMemberKey).CalculatedMemberBalanceMismatch__c);
    }
}