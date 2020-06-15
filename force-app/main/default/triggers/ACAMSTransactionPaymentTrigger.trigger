trigger ACAMSTransactionPaymentTrigger on ccrz__E_TransactionPayment__c (before insert, after insert) {
    new ACAMSTransactionPaymentTriggerHandler().run();
}