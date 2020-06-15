trigger ACAMSAccountAddressBookTrigger on ccrz__E_AccountAddressBook__c (after insert, after update) {
        new ACAMSAccountAddressBookTriggerHandler().run();
}