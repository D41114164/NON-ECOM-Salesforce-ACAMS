public with sharing class ACAMSInvoiceItemTriggerHandler extends CCAviTriggerHandler {
    private List<ccrz__E_InvoiceItem__c> newList = (List<ccrz__E_InvoiceItem__c>) Trigger.new;
    private List<ccrz__E_InvoiceItem__c> oldList = (List<ccrz__E_InvoiceItem__c>) Trigger.old;
    private Map<Id, ccrz__E_InvoiceItem__c> newMap = (Map<Id, ccrz__E_InvoiceItem__c>) Trigger.newMap;
    private Map<Id, ccrz__E_InvoiceItem__c> oldMap = (Map<Id, ccrz__E_InvoiceItem__c>) Trigger.oldMap;

    public static Boolean skipPopulateLegalEntityValueFromFormula = false;

    protected override void beforeInsert() {
        populateLegalEntityValueFromFormula();
    }
    protected override void beforeUpdate() {
        populateLegalEntityValueFromFormula();
        Set<Id> invoiceIds = new Set<Id>();
        for (ccrz__E_InvoiceItem__c invoiceItem : newList) {
            invoiceIds.add(invoiceItem.ccrz__Invoice__c);
        }
        Map<Id, ccrz__E_Invoice__c> idToInvoiceMap = new Map<Id, ccrz__E_Invoice__c>([
                SELECT  Id, ccrz__OriginalAmount__c, ccrz__RemainingAmount__c, ccrz__ParentInvoice__c
                FROM    ccrz__E_Invoice__c
                WHERE   Id IN :invoiceIds
        ]);
        for (Id invoiceItemId : newMap.keySet()) {
            Decimal oldTaxAmount = oldMap.get(invoiceItemId).Tax_Amount__c;
            Decimal newTaxAmount = newMap.get(invoiceItemId).Tax_Amount__c;

            ccrz__E_Invoice__c invoice = idToInvoiceMap.get(newMap.get(invoiceItemId).ccrz__Invoice__c);
            if (newTaxAmount != oldTaxAmount && invoice.ccrz__ParentInvoice__c != null) {
                invoice.ccrz__OriginalAmount__c += newTaxAmount != null ? newTaxAmount : 0;
                invoice.ccrz__RemainingAmount__c += newTaxAmount != null ? newTaxAmount : 0;
            }
        }
        update idToInvoiceMap.values();
    }

    private void populateLegalEntityValueFromFormula() {
        if (!skipPopulateLegalEntityValueFromFormula) {
            ACAMSLegalEntityService.updateLineItemLegalEntityFromFormula(
                    this.newList,
                    ccrz__E_InvoiceItem__c.Legal_Entity_Formula__c.getDescribe().getName(),
                    ccrz__E_InvoiceItem__c.Legal_Entity__c.getDescribe().getName()
            );
        }
    }


}