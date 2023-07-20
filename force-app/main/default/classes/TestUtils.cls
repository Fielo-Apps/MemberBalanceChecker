@isTest
public class TestUtils {

    public static Integer num = 0;

    public static string getTimeStampBase62() {
        return toBase62(System.currentTimeMillis());
    }

    public static string toBase62(Integer n) {
        return toBase62((Long) n);
    }

    public static string toBase62(Long n) {
        List<String> numbers = new List<String>{
            '0','1','2','3','4','5','6','7','8','9',
            'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
            'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'
        };
        List<String> digits = new List<String>();

        if (n == 0) {
            return '0';
        } else {
            while (n > 0) {
                if (digits.isEmpty()) {
                    digits.add(numbers.get(Math.mod(n, 62).intValue()));
                } else {
                    digits.add(0, numbers.get(Math.mod(n, 62).intValue()));
                }
                n = Math.ceil(n/62).longValue();
            }
            return String.join(digits,'');
        }
    }

    public static string getExternalId() {
        return String.valueOf(++num) + '-' + getTimeStampBase62();
    }

    public static List<FieloPLT__Program__c> createPrograms(String basename, Integer count) {
		List<FieloPLT__Program__c> results = new List<FieloPLT__Program__c>();
		for(Integer x = 0; x < count; x++){
			results.add(
				new FieloPLT__Program__c(
					Name = basename + x,
					FieloPLT__OnlineTransactionProcessing__c = true,
					FieloPLT__CapAdjustmentTransactions__c = true,
					FieloPLT__ExternalId__c = getExternalId()
				)
			);
		}
		return results;
	}

    public static List<FieloPLT__Member__c> createIndividualAccounts(String basename, Integer count, Id programId){
		List<FieloPLT__Member__c> results = new List<FieloPLT__Member__c>();
		for(Integer x = 0; x < count; x++){
			results.add(
				new FieloPLT__Member__c(
					Name = basename + x,
					FieloPLT__Email__c = (basename + x).deleteWhitespace() + getTimeStampBase62() + '@fielo.com',//se agrega el datetime para que si se crean más de 200 registros los mails sean distintos
					FieloPLT__Program__c = programId,
					FieloPLT__Type__c = 'Individual Account'
				)
			);
		}
		System.assertNotEquals(null, results);
		return results;
	}
}