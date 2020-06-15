trigger ACAMSCartItemTrigger on ccrz__E_CartItem__c (
    before insert,
    after insert,
    before update,
    after update,
    before delete,
    after delete,
    after undelete
) {
    (new ACAMSCartItemTriggerHandler()).run();
}