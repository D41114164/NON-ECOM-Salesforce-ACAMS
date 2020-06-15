public with sharing class ACAMSAccountAddressBookTriggerHandler extends CCAviTriggerHandler {
    private List<ccrz__E_AccountAddressBook__c> newList = (List<ccrz__E_AccountAddressBook__c>) Trigger.new;

    protected override void afterInsert() {
        updateAccountAddressInfo();
    }

    protected override void afterUpdate() {
        updateAccountAddressInfo();
    }

    private void updateAccountAddressInfo() {
        Map<String, Account> accountIdToAccountObjectMap = new Map<String, Account>();

        Set<Id> accountAddressBookAccountIdSet = new Set<Id>();
        Set<Id> accountAddressBookIdSet = new Set<Id>();
        Map<Id, Account> accountAddressBookIdToAccountMap = new Map<Id, Account>();
        Map<Id, ccrz__E_ContactAddr__c> accountAddressBookToContactAddressMap = new Map<Id, ccrz__E_ContactAddr__c>();
        for (ccrz__E_AccountAddressBook__c accountAddressBook : newList) {
            accountAddressBookAccountIdSet.add(accountAddressBook.ccrz__AccountId__c);
            accountAddressBookIdSet.add(accountAddressBook.ccrz__E_ContactAddress__c);
        }

        List<Account> accountsFromAddressBooks =
                ACAMSAccountDAO.getAccountsFromIds(accountAddressBookAccountIdSet);
        for (ccrz__E_AccountAddressBook__c accountAddressBook : newList) {
            for (Account account : accountsFromAddressBooks) {
                if (accountAddressBook.ccrz__Account__c == account.Id) {
                    accountAddressBookIdToAccountMap.put(accountAddressBook.Id, account);
                    break;
                }
            }
        }

        List<ccrz__E_ContactAddr__c> contactAddrs =
                ACAMSContactAddressDAO.getContactAddrsByIds(accountAddressBookIdSet);
        for (ccrz__E_AccountAddressBook__c accountAddressBook : newList) {
            for (ccrz__E_ContactAddr__c contactAddr : contactAddrs) {
                if (accountAddressBook.ccrz__E_ContactAddress__c == contactAddr.Id) {
                    accountAddressBookToContactAddressMap.put(accountAddressBook.Id, contactAddr);
                    break;
                }
            }
        }

        try {
            for (ccrz__E_AccountAddressBook__c accountAddressBook : newList) {
                if (accountAddressBook.ccrz__Default__c == true) {
                    Account associatedAccount = accountAddressBookIdToAccountMap.get(accountAddressBook.Id);
                    ccrz__E_ContactAddr__c contactAddr =
                            accountAddressBookToContactAddressMap.get(accountAddressBook.Id);

                    associatedAccount.BillingCity = contactAddr.ccrz__City__c;
                    associatedAccount.BillingState = contactAddr.ccrz__State__c;
                    associatedAccount.BillingCountry = contactAddr.ccrz__Country__c;
                    associatedAccount.BillingPostalCode = contactAddr.ccrz__PostalCode__c;
                    associatedAccount.BillingCountryCode = contactAddr.ccrz__CountryISOCode__c;
                    associatedAccount.BillingStateCode = contactAddr.ccrz__StateISOCode__c;

                    String billingStreet = contactAddr.ccrz__AddressFirstline__c;
                    if (String.isNotBlank(contactAddr.ccrz__AddressSecondline__c)) {
                        billingStreet = billingStreet + '\n' + contactAddr.ccrz__AddressSecondline__c;
                    }
                    if (String.isNotBlank(contactAddr.ccrz__AddressThirdline__c)) {
                        billingStreet = billingStreet + '\n' + contactAddr.ccrz__AddressThirdline__c;
                    }
                    associatedAccount.BillingStreet = billingStreet;

                    accountIdToAccountObjectMap.put(accountAddressBook.ccrz__AccountId__c, associatedAccount);
                }
            }

            update accountIdToAccountObjectMap.values();
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
        }
    }

}