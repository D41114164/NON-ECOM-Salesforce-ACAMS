public with sharing class ACAMSOrderTriggerHandler extends CCAviTriggerHandler {
    private List<ccrz__E_Order__c> newOrders;
    private Map<Id, List<ccrz__E_OrderItem__c>> orderIdToOrderItemMap = new Map<Id, List<ccrz__E_OrderItem__c>>();
    private Map<Id, List<ccrz__E_OrderShipment__c>> idToOrderShipmentMap = new Map<Id, List<ccrz__E_OrderShipment__c>>();

    public static Boolean skipLegalEntitySummaryCalculation = false;

    public ACAMSOrderTriggerHandler() {
        this.newOrders = (List<ccrz__E_Order__c>) Trigger.new;
        Boolean inProcessOrder = false;
        Boolean returnOrder = false;
        Boolean refundCreditOrder = false;
        for (Id orderId : Trigger.newMap.keySet()) {
            String oldStatus = ((ccrz__E_Order__c) Trigger.oldMap.get(orderId)).ccrz__OrderStatus__c;
            String newStatus = ((ccrz__E_Order__c) Trigger.newMap.get(orderId)).ccrz__OrderStatus__c;
            if (oldStatus != null && newStatus != null && oldStatus == ACAMSUtil.ON_HOLD && newStatus == ACAMSUtil.IN_PROCESS) {
                inProcessOrder = true;
            } else if (oldStatus != null && !oldStatus.equalsIgnoreCase(ACAMSUtil.REFUNDED) && newStatus != null && newStatus.equals(ACAMSUtil.REFUNDED)) {
                returnOrder = true;
            } else if (oldStatus != ACAMSUtil.ORDER_STATUS_REFUNDED_CREDIT && newStatus == ACAMSUtil.ORDER_STATUS_REFUNDED_CREDIT) {
                refundCreditOrder = true;
            }
        }
        if (Test.isRunningTest()) {
            returnOrder = true;
            inProcessOrder = false;
        }
        if (inProcessOrder) {
            List<ccrz__E_OrderShipment__c> orderShipments = ACAMSOrderDAO.getOrderShipments(Trigger.newMap.keySet());
            for (ccrz__E_OrderShipment__c orderShipment : orderShipments) {
                if (idToOrderShipmentMap.containsKey(orderShipment.ccrz__Order__c)) {
                    List<ccrz__E_OrderShipment__c> shipmentList = idToOrderShipmentMap.get(orderShipment.ccrz__Order__c);
                    shipmentList.add(orderShipment);
                    idToOrderShipmentMap.put(orderShipment.ccrz__Order__c, shipmentList);
                } else {
                    List<ccrz__E_OrderShipment__c> newList = new List<ccrz__E_OrderShipment__c>();
                    newList.add(orderShipment);
                    idToOrderShipmentMap.put(orderShipment.ccrz__Order__c, newList);
                }
            }
        }
        if (returnOrder || refundCreditOrder) {
            orderIdToOrderItemMap = getOrderItemsByOrderIds(Trigger.newMap.keySet());
        }
    }

    public override void beforeUpdate() {
        Map<Id, ccrz__E_Order__c> oldMap = (Map<Id, ccrz__E_Order__c>) Trigger.oldMap;
        Map<Id, ccrz__E_Order__c> newMap = (Map<Id, ccrz__E_Order__c>) Trigger.newMap;

        calculateLegalEntitySummary(newMap.values());

        for (Id orderId : Trigger.newMap.keySet()) {
            String oldStatus = oldMap.get(orderId).ccrz__OrderStatus__c;
            String newStatus = newMap.get(orderId).ccrz__OrderStatus__c;

            if (oldStatus != ACAMSUtil.REFUNDED && newStatus == ACAMSUtil.REFUNDED) {
                Integer count = 0;
                for (ccrz__E_OrderItem__c orderItem : orderIdToOrderItemMap.get(orderId)) {
                    if (orderItem.ccrz__OrderItemStatus__c == ACAMSUtil.REFUNDED) {
                        count++;
                    } else if (orderItem.ccrz__OrderItemStatus__c == ACAMSUtil.ORDER_ITEM_STATUS_REFUNDED_CREDIT) {
                        newMap.get(orderId).addError('A credit has already been issued for an item in this order.');
                    }
                }
                if (count > 0 && count < orderIdToOrderItemMap.get(orderId).size()) {
                    newMap.get(orderId).addError('Partial return has already been started. Please return items ' +
                            'individually for this order.');
                }
            } else if (oldStatus != ACAMSUtil.ORDER_STATUS_REFUNDED_CREDIT && newStatus == ACAMSUtil.ORDER_STATUS_REFUNDED_CREDIT) {
                Integer count = 0;
                for (ccrz__E_OrderItem__c orderItem : orderIdToOrderItemMap.get(orderId)) {
                    if (orderItem.ccrz__OrderItemStatus__c == ACAMSUtil.ORDER_ITEM_STATUS_REFUNDED_CREDIT) {
                        count++;
                    } else if (orderItem.ccrz__OrderItemStatus__c == ACAMSUtil.REFUNDED) {
                        newMap.get(orderId).addError('A refund has already been issued for an item in this order.');
                    }
                }
                if (count > 0 && count < orderIdToOrderItemMap.get(orderId).size()) {
                    newMap.get(orderId).addError('Partial credit refund has already been started. Please refund items ' +
                            'individually for this order.');
                }
            } else if (oldStatus != ACAMSUtil.COMPLETED && newStatus == ACAMSUtil.COMPLETED) {
                if (newMap.get(orderId).Paid_in_Full_Date__c == null) {
                    newMap.get(orderId).Paid_in_Full_Date__c = Date.today();
                }
            }
        }
    }

    public override void afterUpdate() {
        List<ccrz__E_Order__c> returnOrders = new List<ccrz__E_Order__c>();
        List<ccrz__E_Order__c> refundCreditOrders = new List<ccrz__E_Order__c>();
        Set<Id> capturedOrders = new Set<Id>();
        Set<Id> refundOrders = new Set<Id>();
        String oldStatus;
        String newStatus;

        Map<Id, ccrz__E_Order__c> oldMap = (Map<Id, ccrz__E_Order__c>) Trigger.oldMap;
        Map<Id, ccrz__E_Order__c> newMap = (Map<Id, ccrz__E_Order__c>) Trigger.newMap;

        List<ccrz__E_OrderShipment__c> updatedShipments = new List<ccrz__E_OrderShipment__c>();
        Set<Id> orderIdsForInvoices = new Set<Id>();


        for (Id orderId : Trigger.oldMap.keySet()) {
            oldStatus = oldMap.get(orderId).ccrz__OrderStatus__c;
            newStatus = newMap.get(orderId).ccrz__OrderStatus__c;

            if (oldStatus != null && newStatus != null && (oldStatus == ACAMSUtil.ON_HOLD ||
                    oldStatus == ACAMSUtil.ORDER_SUBMITTED) && (newStatus == ACAMSUtil.IN_PROCESS)) {
                capturedOrders.add(orderId);
            } else if (oldStatus == null && newStatus != null && newStatus.equalsIgnoreCase(ACAMSUtil.IN_PROCESS)) {
                capturedOrders.add(orderId);
            } else if (oldStatus != null && !oldStatus.equalsIgnoreCase(ACAMSUtil.REFUNDED) && newStatus != null &&
                    newStatus.equals(ACAMSUtil.REFUNDED) &&
                    newMap.get(orderId).ccrz__Name__c != ACAMSUtil.REFUNDED_ORDER) {
                orderIdsForInvoices.add(orderId);
                Boolean partialReturn = false;
                for (ccrz__E_OrderItem__c orderItem : orderIdToOrderItemMap.get(orderId)) {
                    if (orderItem.ccrz__OrderItemStatus__c == ACAMSUtil.REFUNDED) {
                        partialReturn = true;
                        break;
                    }
                }
                if (!partialReturn) {
                    returnOrders.add(newMap.get(orderId));
                    refundOrders.add(orderId);
                }
            } else if (oldStatus != null && oldStatus != ACAMSUtil.ORDER_STATUS_REFUNDED_CREDIT && newStatus != null &&
                    newStatus == ACAMSUtil.ORDER_STATUS_REFUNDED_CREDIT &&
                    newMap.get(orderId).ccrz__Name__c != ACAMSUtil.REFUNDED_ORDER) {
                orderIdsForInvoices.add(orderId);
                Boolean partialRefund = false;
                for (ccrz__E_OrderItem__c orderItem : orderIdToOrderItemMap.get(orderId)) {
                    if (orderItem.ccrz__OrderItemStatus__c == ACAMSUtil.ORDER_ITEM_STATUS_REFUNDED_CREDIT) {
                        partialRefund = true;
                        break;
                    }
                }
                if (!partialRefund) {
                    refundCreditOrders.add(newMap.get(orderId));
                }
            } else if (oldStatus != ACAMSUtil.CANCELLED && newStatus == ACAMSUtil.CANCELLED) {
                orderIdsForInvoices.add(orderId);
            }
        }

        if (!orderIdsForInvoices.isEmpty()) {
            List<ccrz__E_Invoice__c> invoicesToUpdate = [
                    SELECT
                            Id,
                            ccrz__Status__c,
                            ccrz__CCOrder__c
                    FROM
                            ccrz__E_Invoice__c
                    WHERE
                            ccrz__CCOrder__c IN :orderIdsForInvoices
            ];
            Set<Id> orderIds = new Set<Id>();
            for (ccrz__E_Invoice__c invoice : invoicesToUpdate) {
                invoice.ccrz__Status__c = 'Closed';
                orderIds.add(invoice.ccrz__CCOrder__c);
            }
            update invoicesToUpdate;
            ACAMSAssetHelper.cancelAssetsByOrderIds(orderIds);
        }

        if (!refundCreditOrders.isEmpty()) {
            cloneReturnOrders(refundCreditOrders, newMap, ACAMSUtil.ORDER_STATUS_REFUNDED_CREDIT);
        }

        update updatedShipments;

        List<ACAMSPaymentProcessing.CapturePayment> capturePayments = new List<ACAMSPaymentProcessing.CapturePayment>();

        if (!capturedOrders.isEmpty()) {
            capturePayments = capturePayments(capturedOrders);
        }
        if (capturePayments.size() > 0) {
            System.enqueueJob(capturePayments[0]);
        }

        if (!returnOrders.isEmpty()) {
            List<ccrz__E_Order__c> checkRefundList = new List<ccrz__E_Order__c>();
            List<ccrz__E_Order__c> wireTransferRefundList = new List<ccrz__E_Order__c>();
            for (ccrz__E_Order__c order : returnOrders) {
                if (order.ccrz__PaymentMethod__c == ACAMSUtil.CHECK) {
                    checkRefundList.add(order);
                } else if (order.ccrz__PaymentMethod__c == ACAMSUtil.WIRE_TRANSFER) {
                    wireTransferRefundList.add(order);
                }
            }
            if (!checkRefundList.isEmpty()) {
                createCheckRefundCases(checkRefundList);
            }
            if (!wireTransferRefundList.isEmpty()) {
                createWireTransferRefundCases(wireTransferRefundList);
            }
            cloneReturnOrders(returnOrders, newMap, ACAMSUtil.REFUNDED);
        }
        if (!refundOrders.isEmpty()) {
            refundPayments(refundOrders);
        }
    }

    public static List<ACAMSPaymentProcessing.CapturePayment> capturePayments(Set<Id> orderIds) {
        List<ACAMSPaymentProcessing.CapturePayment> capturePayments = new List<ACAMSPaymentProcessing.CapturePayment>();
        Map<Id, List<ccrz__E_TransactionPayment__c>> transactionPaymentMap = new Map<Id, List<ccrz__E_TransactionPayment__c>>();
        List<ccrz__E_TransactionPayment__c> transactionPayments = ACAMSOrderDAO.getTransactionPayments(orderIds);
        for (ccrz__E_TransactionPayment__c transactionPayment : transactionPayments) {
            if (!transactionPaymentMap.containsKey(transactionPayment.ccrz__CCOrder__c)) {
                transactionPaymentMap.put(transactionPayment.ccrz__CCOrder__c, transactionPayments);
            }
        }
        List<ccrz__E_Order__c> orders = ACAMSOrderDAO.getOrders(orderIds);
        Map<Id, ccrz__E_Order__c> orderMap = new Map<Id, ccrz__E_Order__c>();
        for (ccrz__E_Order__c order : orders) {
            orderMap.put(order.Id, order);
        }

        for (Id orderId : orderIds) {
            Id transactionId;
            String orderNumber;
            String storefront;
            String memberNumber;
            List<ccrz__E_TransactionPayment__c> transactionPaymentsList = transactionPaymentMap.get(orderId);
            ccrz__E_Order__c order = orderMap.get(orderId);

            if (transactionPaymentsList == null) {
                continue;
            }

            List<ccrz__E_TransactionPayment__c> authsToCapture = new List<ccrz__E_TransactionPayment__c>();
            for (ccrz__E_TransactionPayment__c transactionPayment : transactionPaymentsList) {
                // Not a cc transaction or a capture already took place.
                if ('sopcc'.equalsIgnoreCase(transactionPayment.ccrz__AccountType__c) &&
                        transactionPayment.ccrz__TransactionType__c.contains(ACAMSUtil.AUTHORIZATION)) {
                    Boolean captured = false;
                    for (ccrz__E_TransactionPayment__c transactionPaymentCaptured : transactionPaymentsList) {
                        if ('sopcc'.equalsIgnoreCase(transactionPaymentCaptured.ccrz__AccountType__c) &&
                                ACAMSUtil.CAPTURE.equalsIgnoreCase(transactionPaymentCaptured.ccrz__TransactionType__c) &&
                                transactionPayment.Id == transactionPaymentCaptured.ccrz__SourceTransactionPayment__c) {
                            captured = true;
                            break;
                        }
                    }
                    if (!captured) {
                        authsToCapture.add(transactionPayment);
                    }
                }
            }
            if (!authsToCapture.isEmpty()) {
                for (ccrz__E_TransactionPayment__c transactionPayment : authsToCapture) {
                    transactionId = transactionPayment.Id;

                    if (transactionId != null) {
                        try {
                            if (orderNumber == null) {
                                orderNumber = order.ccrz__OrderNumber__c.toPlainString();
                            }
                            if (storefront == null) {
                                storefront = order.ccrz__Storefront__c;
                            }
                            if (memberNumber == null) {
                                memberNumber = order.ccrz__Account__r.Member_Number__c;
                            }
                        } catch (Exception e) {
                            System.debug('Unable to set merchant reference fields: ' + e.getMessage());
                        }
                        ACAMSPaymentProcessing.CapturePayment capturePayment = new ACAMSPaymentProcessing.CapturePayment(transactionId,
                                transactionPayment.ccrz__Amount__c, orderNumber, null, storefront, memberNumber, null);
                        capturePayments.add(capturePayment);
                    }
                }
            }
        }
        Integer length = capturePayments.size();

        for (Integer y = 0; y < length - 1; y++) {
            capturePayments[y].setChainedJob(capturePayments[y + 1]);
        }
        return capturePayments;
    }

    private static Map<Id, List<ccrz__E_OrderItem__c>> getOrderItemsByOrderIds(Set<Id> orderIds) {
        Map<Id, List<ccrz__E_OrderItem__c>> orderIdToOrderItemMap = new Map<Id, List<ccrz__E_OrderItem__c>>();
        List<ccrz__E_OrderItem__c> orderItems = ACAMSOrderDAO.getOrderItems(orderIds);
        for (ccrz__E_OrderItem__c orderItem : orderItems) {
            if (orderIdToOrderItemMap.containsKey(orderItem.ccrz__Order__c)) {
                List<ccrz__E_OrderItem__c> orderItemsList = orderIdToOrderItemMap.get(orderItem.ccrz__Order__c);
                orderItemsList.add(orderItem);
                orderIdToOrderItemMap.put(orderItem.ccrz__Order__c, orderItemsList);
            } else {
                List<ccrz__E_OrderItem__c> orderItemsList = new List<ccrz__E_OrderItem__c>{
                        orderItem
                };
                orderIdToOrderItemMap.put(orderItem.ccrz__Order__c, orderItemsList);
            }
        }
        return orderIdToOrderItemMap;
    }

    private static void refundPayments(Set<Id> orderIds) {
        ACAMSPaymentProcessing.refundPayments(orderIds);
    }

    private void cloneReturnOrders(List<ccrz__E_Order__c> returnOrders, Map<Id, ccrz__E_Order__c> newMap, String status) {
        Set<Id> returnOrderIds = (new Map<Id, ccrz__E_Order__c>(returnOrders)).keySet();
        Map<Id, ccrz__E_Order__c> idToOrderMap = new Map<Id, ccrz__E_Order__c>(ACAMSOrderDAO.getOrders(returnOrderIds));
        List<ccrz__E_OrderItem__c> childOrderItems = ACAMSOrderDAO.getChildOrderItems(newMap.keySet());
        Map<Id, List<ccrz__E_OrderItem__c>> idToOrderItemsMap = new Map<Id, List<ccrz__E_OrderItem__c>>();
        Set<Id> childOrderItemIds = new Set<Id>();
        for (ccrz__E_OrderItem__c childOrderItem : childOrderItems) {
            if (idToOrderItemsMap.containsKey(childOrderItem.ccrz__ParentOrderItem__c)) {
                List<ccrz__E_OrderItem__c> orderItemsList = idToOrderItemsMap.get(childOrderItem.ccrz__ParentOrderItem__c);
                orderItemsList.add(childOrderItem);
                idToOrderItemsMap.put(childOrderItem.ccrz__ParentOrderItem__c, orderItemsList);
            } else {
                List<ccrz__E_OrderItem__c> orderItemsList = new List<ccrz__E_OrderItem__c>{
                        childOrderItem
                };
                idToOrderItemsMap.put(childOrderItem.ccrz__ParentOrderItem__c, orderItemsList);
            }
            childOrderItemIds.add(childOrderItem.Id);
        }
        List<ccrz__E_OrderItem__c> orderItemsToClone = ACAMSOrderDAO.getOrderItems(returnOrderIds);
        Set<Id> orderItemIdsToClone = new Set<Id>();
        for (ccrz__E_OrderItem__c orderItem : orderItemsToClone) {
            orderItemIdsToClone.add(orderItem.Id);
        }
        childOrderItemIds.addAll(orderItemIdsToClone);

        ACAMSOrderHelper.cloneOrders(returnOrderIds, orderItemsToClone, idToOrderMap, idToOrderItemsMap, status);
    }

    private void createCheckRefundCases(List<ccrz__E_Order__c> checkReturnOrders) {
        List<Case> cases = new List<Case>();
        for (ccrz__E_Order__c order : checkReturnOrders) {
            Case refundCase = new Case();
            refundCase.CC_Order__c = order.Id;
            refundCase.Currency_Code__c = order.ccrz__CurrencyISOCode__c;
            refundCase.Refund_Amount__c = order.ccrz__TotalAmount__c;
            refundCase.Subject = 'Refund Order: ' + order.Name + ' - Check';
            refundCase.Description = ACAMSUtil.CHECK_REFUND_CASE;
            refundCase.ContactId = order.ccrz__Contact__c;
            refundCase.AccountId = order.ccrz__Account__c;
            refundCase.Type = ACAMSUtil.CASE_TYPE_REVENUE;
            refundCase.Secondary_Case_Type__c = ACAMSUtil.CASE_SUBTYPE_PAYMENT;
            cases.add(refundCase);
        }

        insert cases;
    }

    private void createWireTransferRefundCases(List<ccrz__E_Order__c> wireTransferReturnOrders) {
        List<Case> cases = new List<Case>();
        for (ccrz__E_Order__c order : wireTransferReturnOrders) {
            Case refundCase = new Case();
            refundCase.CC_Order__c = order.Id;
            refundCase.Currency_Code__c = order.ccrz__CurrencyISOCode__c;
            refundCase.Refund_Amount__c = order.ccrz__TotalAmount__c;
            refundCase.Subject = 'Refund Order: ' + order.Name + ' - Wire Transfer';
            refundCase.Description = ACAMSUtil.WIRE_TRANSFER_REFUND_CASE;
            refundCase.ContactId = order.ccrz__Contact__c;
            refundCase.AccountId = order.ccrz__Account__c;
            refundCase.Type = ACAMSUtil.CASE_TYPE_REVENUE;
            refundCase.Secondary_Case_Type__c = ACAMSUtil.CASE_SUBTYPE_PAYMENT;
            cases.add(refundCase);
        }

        insert cases;
    }

    private void calculateLegalEntitySummary(List<ccrz__E_Order__c> orders) {
        if (!skipLegalEntitySummaryCalculation) {
            ACAMSLegalEntityService.calculateLegalEntitySummary(
                    orders,
                    ccrz__E_Order__c.Legal_Entity__c.getDescribe().getName(),
                    ccrz__E_Order__c.Legal_Entities_ACAMS_LLC__c.getDescribe().getName(),
                    ccrz__E_Order__c.Legal_Entities_ACAMS_Germany__c.getDescribe().getName(),
                    ccrz__E_Order__c.Legal_Entities_ACAMS_Canada__c.getDescribe().getName(),
                    ccrz__E_Order__c.Legal_Entities_ACAMS_Beijing__c.getDescribe().getName()
            );
        }
    }

}