trigger ACAMSOrderTrigger on ccrz__E_Order__c (before update, after update) {
    new ACAMSOrderTriggerHandler().run();
}