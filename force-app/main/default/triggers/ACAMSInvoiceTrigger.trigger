trigger ACAMSInvoiceTrigger on ccrz__E_Invoice__c (
    before insert,
    after insert,
    before update,
    after update,
    before delete,
    after delete,
    after undelete
) {
    (new ACAMSInvoiceTriggerHandler()).run();
}