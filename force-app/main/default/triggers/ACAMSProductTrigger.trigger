trigger ACAMSProductTrigger on ccrz__E_Product__c (
    before insert,
    after insert,
    before update,
    after update,
    before delete,
    after delete,
    after undelete
) {
    (new ACAMSProductTriggerHandler()).run();
}