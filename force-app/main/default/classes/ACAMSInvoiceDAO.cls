public with sharing class ACAMSInvoiceDAO {

    public static List<ccrz__E_InvoiceItem__c> getInvoiceIdsFromInvoiceItems(Set<Id> invoiceItemIds) {
        List<ccrz__E_InvoiceItem__c> invoiceItemsWithIds = [
                SELECT
                        Id,
                        ccrz__Invoice__c
                FROM
                        ccrz__E_InvoiceItem__c
                WHERE
                        Id IN :invoiceItemIds
        ];

        return invoiceItemsWithIds;
    }

    public static List<ccrz__E_Invoice__c> getInvoices(Set<Id> invoiceIds) {
        List<ccrz__E_Invoice__c> invoices = [
                SELECT
                        Id
                FROM
                        ccrz__E_Invoice__c
                WHERE
                        Id IN :invoiceIds
        ];

        return invoices;
    }
}