public with sharing class ACAMSTransactionPaymentTriggerHandler extends CCAviTriggerHandler {
    private List<ccrz__E_TransactionPayment__c> newTransactionPayments;

    public ACAMSTransactionPaymentTriggerHandler() {
        this.newTransactionPayments = (List<ccrz__E_TransactionPayment__c>) Trigger.new;
    }

    public override void beforeInsert() {
        List<ccrz__E_TransactionPayment__c> captureList = new List<ccrz__E_TransactionPayment__c>();
        for (ccrz__E_TransactionPayment__c tp : newTransactionPayments) {
            if (tp.ccrz__TransactionType__c == 'capture') {
                captureList.add(tp);
            }
        }

        Set<Id> orderIds = new Set<Id>();
        for (ccrz__E_TransactionPayment__c tp : captureList) {
            orderIds.add(tp.ccrz__CCOrder__c);
        }

        List<ccrz__E_Order__c> orderList = ACAMSOrderDAO.getInvoiceOrders(orderIds);

        Map<Id, ccrz__E_Order__c> orderIdMap = new Map<Id, ccrz__E_Order__c>();
        for (ccrz__E_Order__c order : orderList) {
            if (!orderIdMap.containsKey(order.Id)) {
                orderIdMap.put(order.Id, order);
            }
        }

        List<ccrz__E_Invoice__c> invoiceUpdateList = new List<ccrz__E_Invoice__c>();
        for (ccrz__E_TransactionPayment__c tp : captureList) {
            ccrz__E_Order__c order = orderIdMap.get(tp.ccrz__CCOrder__c);
            if (order != null && order.ccrz__CCInvoices__r != null && !order.ccrz__CCInvoices__r.isEmpty() && order.ccrz__CCInvoices__r.get(0) != null) {
                ccrz__E_Invoice__c invoice = order.ccrz__CCInvoices__r.get(0);
                if (tp.ccrz__InvoiceAppliedFor__c != null) {
                    for (ccrz__E_Invoice__c orderInvoice : order.ccrz__CCInvoices__r) {
                        if (orderInvoice.Id == tp.ccrz__InvoiceAppliedFor__c) {
                            invoice = orderInvoice;
                        }
                    }
                }
                invoice.ccrz__RemainingAmount__c = invoice.ccrz__RemainingAmount__c - tp.ccrz__Amount__c;
                if (invoice.ccrz__RemainingAmount__c == 0) {
                    invoice.ccrz__Status__c = 'Closed';
                }
                invoiceUpdateList.add(invoice);
            }
        }
        if (!invoiceUpdateList.isEmpty()) {
            update invoiceUpdateList;
        }

        List<ccrz__E_Order__c> ordersToUpdate = new List<ccrz__E_Order__c>();
        for (ccrz__E_Order__c order : orderList) {
            Boolean paid = true;
            for (ccrz__E_Invoice__c invoice : order.ccrz__CCInvoices__r) {
                if (invoice.ccrz__Status__c != 'Closed') {
                    paid = false;
                    break;
                }
            }
            if (paid) {
                order.ccrz__OrderStatus__c = 'Completed';
                ordersToUpdate.add(order);
            }
        }
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }

    public override void afterInsert() {
        List<ccrz__E_TransactionPayment__c> authsToCapture = new List<ccrz__E_TransactionPayment__c>();
        List<ACAMSPaymentProcessing.CapturePayment> capturePayments = new List<ACAMSPaymentProcessing.CapturePayment>();

        for (ccrz__E_TransactionPayment__c tp : newTransactionPayments) {
            if (tp.ccrz__TransactionType__c.contains(ACAMSUtil.AUTHORIZATION) && tp.Web_Invoice_Payment__c) {
                authsToCapture.add(tp);
            }
        }

        Set<Id> orderIds = new Set<Id>();
        for (ccrz__E_TransactionPayment__c tp : authsToCapture) {
            orderIds.add(tp.ccrz__CCOrder__c);
        }

        Map<Id, ccrz__E_Order__c> idToOrderMap = new Map<Id, ccrz__E_Order__c>(ACAMSOrderDAO.getOrders(orderIds));

        if (!authsToCapture.isEmpty()) {
            for (ccrz__E_TransactionPayment__c transactionPayment : authsToCapture) {
                Id transactionId = transactionPayment.Id;
                String orderNumber;
                String storeFront;
                String memberNumber;

                ccrz__E_Order__c order = idToOrderMap.get(transactionPayment.ccrz__CCOrder__c);
                if (transactionId != null) {
                    try {
                        if (orderNumber == null) {
                            orderNumber = order.ccrz__OrderNumber__c.toPlainString();
                        }
                        if (storeFront == null) {
                            storeFront = order.ccrz__Storefront__c;
                        }
                        if (memberNumber == null) {
                            memberNumber = order.ccrz__Account__r.Member_Number__c;
                        }
                    } catch (Exception e) {
                        System.debug('Unable to set merchant reference fields: ' + e.getMessage());
                    }
                    ACAMSPaymentProcessing.CapturePayment capturePayment = new ACAMSPaymentProcessing.CapturePayment(transactionId,
                            transactionPayment.ccrz__Amount__c, orderNumber, null, storeFront, memberNumber,
                            transactionPayment.ccrz__InvoiceAppliedFor__c);
                    capturePayments.add(capturePayment);
                }
            }
        }

        Integer length = capturePayments.size();
        for (Integer y = 0; y < length - 1; y++) {
            capturePayments[y].setChainedJob(capturePayments[y + 1]);
        }

        if (capturePayments.size() > 0) {
            System.enqueueJob(capturePayments[0]);
        }
    }
}