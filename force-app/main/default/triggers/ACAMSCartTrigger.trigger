trigger ACAMSCartTrigger on ccrz__E_Cart__c (before update) {
    new ACAMSCartTriggerHandler().run();
}