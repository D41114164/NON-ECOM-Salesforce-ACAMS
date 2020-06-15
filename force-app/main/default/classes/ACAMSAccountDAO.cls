public with sharing class ACAMSAccountDAO {

    public static List<Account> getPersonAccountsFromIds(Set<Id> idSet) {
        List<Account> accounts = [
                SELECT
                        Id,
                        ccrz__E_AccountGroup__c,
                        PersonEmail
                FROM
                        Account
                WHERE
                        Id IN :idSet
                AND
                        IsPersonAccount = TRUE
        ];

        return accounts;
    }

    public static Contact getContact(Id contactId) {
        Contact contact;
        List<Contact> contacts = [
                SELECT
                        Id,
                        FirstName,
                        LastName,
                        AccountId,
                        Email
                FROM
                        Contact
                WHERE
                        Id = :contactId
        ];
        if (!contacts.isEmpty()) {
            contact = contacts.get(0);
        }

        return contact;
    }

    public static List<Account> getAccountsFromIds(Set<Id> ids) {
        List<Account> accounts = [
                SELECT
                        Id,
                        ccrz__E_AccountGroup__c,
                        Enterprise_Account__c,
                        Parent_Account__pc
                FROM
                        Account
                WHERE
                        Id IN :ids
        ];

        return accounts;
    }

    public static List<Lead> queryLeadsByEmails(List<String> emails) {
        List<Lead> leads = [
                SELECT
                        ConvertedAccountId,
                        Email,
                        Id,
                        Name,
                        Status
                FROM
                        Lead
                WHERE
                        Email IN :emails
        ];
        return leads;
    }

    public static List<Contact> getContactsByContactIds(Set<Id> contactIds) {
        List<Contact> contacts = [
                SELECT
                        Chapter_Member_Expire_Date__c,
                        Member_Expire_Date__c
                FROM
                        Contact
                WHERE
                        Id IN :contactIds
        ];
        return contacts;
    }
}