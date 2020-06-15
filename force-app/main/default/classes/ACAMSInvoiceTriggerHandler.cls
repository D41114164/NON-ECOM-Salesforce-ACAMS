public with sharing class ACAMSInvoiceTriggerHandler extends CCAviTriggerHandler {

    private List<ccrz__E_Invoice__c> newList = (List<ccrz__E_Invoice__c>) Trigger.new;
    private List<ccrz__E_Invoice__c> oldList = (List<ccrz__E_Invoice__c>) Trigger.old;
    private Map<Id, ccrz__E_Invoice__c> newMap = (Map<Id, ccrz__E_Invoice__c>) Trigger.newMap;
    private Map<Id, ccrz__E_Invoice__c> oldMap = (Map<Id, ccrz__E_Invoice__c>) Trigger.oldMap;

    public static Boolean skipLegalEntitySummaryCalculation = false;

    protected override void beforeUpdate() {
        this.calculateLegalEntitySummary();
        Map<Id, ccrz__E_Invoice__c> newInvoices = new Map<Id, ccrz__E_Invoice__c>([
                SELECT Id, Sold_To_Tax_Area_Id__c, (SELECT Id FROM ccrz__ChildInvoices__r)
                FROM ccrz__E_Invoice__c
                WHERE Id IN :newMap.keySet()
        ]);
        Set<Id> invoiceIdsToFinalize = new Set<Id>();
        for (Id invoiceId : newMap.keySet()) {
            Boolean oldFinalized = oldMap.get(invoiceId).Finalized__c;
            Boolean newFinalized = newMap.get(invoiceId).Finalized__c;
            String oldStatus = oldMap.get(invoiceId).ccrz__Status__c;
            String newStatus = newMap.get(invoiceId).ccrz__Status__c;
            if (oldStatus != newStatus && newStatus == 'Closed') {
                if (newInvoices.get(invoiceId).Sold_To_Tax_Area_Id__c != null &&
                        newInvoices.get(invoiceId).ccrz__ChildInvoices__r.size() == 0) {
                    newInvoices.get(invoiceId).Finalized__c = true;
                    newFinalized = true;
                }
            }
            if (!oldFinalized && newFinalized) {
                invoiceIdsToFinalize.add(invoiceId);
                if (newInvoices.get(invoiceId).ccrz__ChildInvoices__r.size() > 0) {
                    newMap.get(invoiceId).addError('This is a parent invoice and cannot be finalized. ' +
                            'Please finalize or remove the child invoices attached to this record.');
                }
            }
        }
        for (Id invoiceId : invoiceIdsToFinalize) {
            if (newInvoices.get(invoiceId).Sold_To_Tax_Area_Id__c == null) {
                newMap.get(invoiceId).addError('Please review the address(es) on this Invoice. They were not ' +
                        'validated through Vertex.');
            }
        }

    }

    protected override void afterUpdate() {
        Map<Id, ccrz__E_Invoice__c> newInvoices = new Map<Id, ccrz__E_Invoice__c>([
                SELECT Id, Sold_To_Tax_Area_Id__c, ccrz__CCOrder__c, ccrz__CCOrder__r.ccrz__OrderStatus__c,
                (SELECT Id, ccrz__CCOrderItem__c, Quantity__c, ItemQuantity__c FROM ccrz__InvoiceItems__r)
                FROM ccrz__E_Invoice__c
                WHERE Id IN :newMap.keySet()
        ]);
        Map<Id, Decimal> orderItemsMap = new Map<Id, Decimal>();
        for (Id invoiceId : newMap.keySet()) {
            String oldStatus = oldMap.get(invoiceId).ccrz__Status__c;
            String newStatus = newMap.get(invoiceId).ccrz__Status__c;
            if (oldStatus != newStatus && newStatus == 'Closed' &&
                    newMap.get(invoiceId).ccrz__CCOrder__r.ccrz__OrderStatus__c != ACAMSUtil.CANCELLED &&
                    newMap.get(invoiceId).ccrz__CCOrder__r.ccrz__OrderStatus__c != ACAMSUtil.REFUNDED &&
                    newMap.get(invoiceId).ccrz__CCOrder__r.ccrz__OrderStatus__c != ACAMSUtil.ORDER_STATUS_REFUNDED_CREDIT) {
                for (ccrz__E_InvoiceItem__c invoiceItem : newInvoices.get(invoiceId).ccrz__InvoiceItems__r) {
                    Decimal quantity = invoiceItem.Quantity__c != null ?
                            invoiceItem.Quantity__c : invoiceItem.ItemQuantity__c;
                    orderItemsMap.put(invoiceItem.ccrz__CCOrderItem__c, quantity);
                }
                ACAMSAssetHelper.activateAssets(orderItemsMap);
            }
        }
    }

    private void calculateLegalEntitySummary() {
        if (!skipLegalEntitySummaryCalculation) {
            ACAMSLegalEntityService.calculateLegalEntitySummary(
                    this.newList,
                    ccrz__E_Invoice__c.Legal_Entity__c.getDescribe().getName(),
                    ccrz__E_Invoice__c.Legal_Entities_ACAMS_LLC__c.getDescribe().getName(),
                    ccrz__E_Invoice__c.Legal_Entities_ACAMS_Germany__c.getDescribe().getName(),
                    ccrz__E_Invoice__c.Legal_Entities_ACAMS_Canada__c.getDescribe().getName(),
                    ccrz__E_Invoice__c.Legal_Entities_ACAMS_Beijing__c.getDescribe().getName()
            );
        }
    }
}