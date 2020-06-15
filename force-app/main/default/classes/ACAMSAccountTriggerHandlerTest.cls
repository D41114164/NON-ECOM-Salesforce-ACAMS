@IsTest
class ACAMSAccountTriggerHandlerTest {
    
    @IsTest
    static void testBillingCountryCodeUpdated() {
        List<Account> accounts = new List<Account>();
        Account account1 = new Account();
        account1.Name = 'testAccount1';
        account1.BillingCountryCode = 'US';
        accounts.add(account1);
        Account account2 = new Account();
        account2.Name = 'testAccount2';
        account2.BillingCountryCode = 'US';
        accounts.add(account2);
        insert accounts;

        account1.BillingCountryCode = 'UY';
        account2.BillingCountryCode = 'SI';
        update accounts;

        List<Account> updatedAccounts = [
                SELECT
                        Id,
                        Billing_Named_Territory__c
                FROM
                        Account
                WHERE
                        Id IN :accounts
        ];

        System.assert(updatedAccounts.get(0).Billing_Named_Territory__c.equals('LATAM'));
        System.assert(updatedAccounts.get(1).Billing_Named_Territory__c.equals('Other Europe'));
    }

    @IsTest
    static void testPrimaryEmailCheck() {
        RecordType personAccountRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' AND SobjectType = 'Account'];

        Account newAccount = new Account();
        newAccount.Email__c = 'test@test.com';
        newAccount.FirstName = 'testFirstName';
        newAccount.LastName = 'testLastName';
        newAccount.RecordTypeId = personAccountRecordType.Id;
        insert newAccount;

        newAccount.Work_Email__pc = 'workemail@test.com';
        newAccount.Primary_Email__pc = 'Work';
        update newAccount;

        Account updatedAccount = [
                SELECT
                        PersonEmail
                FROM
                        Account
                WHERE
                        Id = :newAccount.Id
        ];

        System.assertEquals(newAccount.Work_Email__pc, updatedAccount.PersonEmail);

        newAccount.Secondary_Email__pc = 'personalemail@test.com';
        newAccount.Primary_Email__pc = 'Personal';
        update newAccount;

        updatedAccount = [
                SELECT
                        PersonEmail
                FROM
                        Account
                WHERE
                        Id = :newAccount.Id
        ];

        System.assertEquals(newAccount.Secondary_Email__pc, updatedAccount.PersonEmail);

        newAccount.Other_Email__pc = 'otheremail@test.com';
        newAccount.Primary_Email__pc = 'Other';
        update newAccount;

        updatedAccount = [
                SELECT
                        PersonEmail
                FROM
                        Account
                WHERE
                        Id = :newAccount.Id
        ];

        System.assertEquals(newAccount.Other_Email__pc, updatedAccount.PersonEmail);
    }

}