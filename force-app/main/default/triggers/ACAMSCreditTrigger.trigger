trigger ACAMSCreditTrigger on Credit__c (after insert, after update, after delete) {
    new ACAMSCreditTriggerHandler().run();
}