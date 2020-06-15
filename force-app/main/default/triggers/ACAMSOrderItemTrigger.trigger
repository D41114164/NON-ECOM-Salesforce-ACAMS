trigger ACAMSOrderItemTrigger on ccrz__E_OrderItem__c (before insert, before update, after update) {
    new ACAMSOrderItemTriggerHandler().run();
}