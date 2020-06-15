@IsTest
public class ACAMSUserTriggerHandlerTest {

    @IsTest
    public static void testPortalAccountSet() {

        User drupalIntegrationUser = ACAMSUserDAO.getDrupalIntegrationUser();
        System.runAs(drupalIntegrationUser) {
            ccrz__E_AccountGroup__c portalAccountGroup = new ccrz__E_AccountGroup__c(
                    Name = 'PortalAccount'
            );
            insert portalAccountGroup;

            RecordType personAccountRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' AND SobjectType = 'Account'];

            Account newAccount = new Account();
            newAccount.Email__c = 'test@test.com';
            newAccount.FirstName = 'testFirstName';
            newAccount.LastName = 'testLastName';
            newAccount.RecordTypeId = personAccountRecordType.Id;
            insert newAccount;

            Account updatedAccount = [
                    SELECT
                            Id, PersonContactId
                    FROM
                            Account
                    WHERE
                            Email__c = 'test@test.com'
            ];

            updatedAccount.PersonEmail = 'test@test.com';
            update updatedAccount;

            User newUser = new User();
            newUser.ContactId = updatedAccount.PersonContactId;
            newUser.Username = 'test@test.com';
            newUser.LastName = 'testLastName';
            newUser.Email = 'test@test.com';
            newUser.Alias = 'alias';
            newUser.TimeZoneSidKey = 'GMT';
            newUser.LocaleSidKey = 'en_US';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.ProfileId = ACAMSUserDAO.getB2BProfile().Id;
            newUser.LanguageLocaleKey = 'en_US';
            insert newUser;

            Account updatedAccount2 = [
                    SELECT
                            Id, ccrz__E_AccountGroup__c
                    FROM
                            Account
                    WHERE
                            PersonEmail = 'test@test.com'
            ];

            System.assert(updatedAccount2.ccrz__E_AccountGroup__c == portalAccountGroup.Id);
        }
    }

    @IsTest
    public static void testMilPortalAccountSet() {

        User drupalIntegrationUser = ACAMSUserDAO.getDrupalIntegrationUser();
        System.runAs(drupalIntegrationUser) {
            ccrz__E_AccountGroup__c portalAccountGroup = new ccrz__E_AccountGroup__c(
                    Name = 'PortalAccount-Government/Non-Member'
            );
            insert portalAccountGroup;

            RecordType personAccountRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' AND SobjectType = 'Account'];

            Account newAccount = new Account();
            newAccount.Email__c = 'test@test.mil';
            newAccount.FirstName = 'testFirstName';
            newAccount.LastName = 'testLastName';
            newAccount.RecordTypeId = personAccountRecordType.Id;
            insert newAccount;

            Account updatedAccount = [
                    SELECT
                            Id, PersonContactId
                    FROM
                            Account
                    WHERE
                            Email__c = 'test@test.mil'
            ];

            updatedAccount.PersonEmail = 'test@test.mil';
            update updatedAccount;

            User newUser = new User();
            newUser.ContactId = updatedAccount.PersonContactId;
            newUser.Username = 'test@test.com';
            newUser.LastName = 'testLastName';
            newUser.Email = 'test@test.mil';
            newUser.Alias = 'alias';
            newUser.TimeZoneSidKey = 'GMT';
            newUser.LocaleSidKey = 'en_US';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.ProfileId = ACAMSUserDAO.getB2BProfile().Id;
            newUser.LanguageLocaleKey = 'en_US';
            insert newUser;

            Account updatedAccount2 = [
                    SELECT
                            Id, ccrz__E_AccountGroup__c
                    FROM
                            Account
                    WHERE
                            PersonEmail = 'test@test.mil'
            ];

            System.assert(updatedAccount2.ccrz__E_AccountGroup__c == portalAccountGroup.Id);
        }
    }

    @IsTest
    public static void testGovPortalAccountSet() {

        User drupalIntegrationUser = ACAMSUserDAO.getDrupalIntegrationUser();
        System.runAs(drupalIntegrationUser) {
            ccrz__E_AccountGroup__c portalAccountGroup = new ccrz__E_AccountGroup__c(
                    Name = 'PortalAccount-Government/Non-Member'
            );
            insert portalAccountGroup;

            RecordType personAccountRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' AND SobjectType = 'Account'];

            Account newAccount = new Account();
            newAccount.Email__c = 'test@test.gov';
            newAccount.FirstName = 'testFirstName';
            newAccount.LastName = 'testLastName';
            newAccount.RecordTypeId = personAccountRecordType.Id;
            insert newAccount;

            Account updatedAccount = [
                    SELECT
                            Id, PersonContactId
                    FROM
                            Account
                    WHERE
                            Email__c = 'test@test.gov'
            ];

            updatedAccount.PersonEmail = 'test@test.gov';
            update updatedAccount;

            User newUser = new User();
            newUser.ContactId = updatedAccount.PersonContactId;
            newUser.Username = 'test@test.com';
            newUser.LastName = 'testLastName';
            newUser.Email = 'test@test.gov';
            newUser.Alias = 'alias';
            newUser.TimeZoneSidKey = 'GMT';
            newUser.LocaleSidKey = 'en_US';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.ProfileId = ACAMSUserDAO.getB2BProfile().Id;
            newUser.LanguageLocaleKey = 'en_US';
            insert newUser;

            Account updatedAccount2 = [
                    SELECT
                            Id, ccrz__E_AccountGroup__c
                    FROM
                            Account
                    WHERE
                            PersonEmail = 'test@test.gov'
            ];

            System.assert(updatedAccount2.ccrz__E_AccountGroup__c == portalAccountGroup.Id);
        }
    }

}