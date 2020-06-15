public with sharing class ACAMSCreditTriggerHandler extends CCAviTriggerHandler {

    private List<Credit__c> newList;
    private List<Credit__c> oldList;
    private Map<Id, Credit__c> newMap;
    private Map<Id, Credit__c> oldMap;
    private Map<Id, ccrz__E_Order__c> orders;

    public ACAMSCreditTriggerHandler() {
        this.newList = (List<Credit__c>) Trigger.new;
        this.oldList = (List<Credit__c>) Trigger.old;
        this.newMap = (Map<Id, Credit__c>) Trigger.newMap;
        this.oldMap = (Map<Id, Credit__c>) Trigger.oldMap;
        Set<Id> orderIds = new Set<Id>();
        if (Trigger.isUpdate || Trigger.isDelete) {
            for (Credit__c credit : oldList) {
                orderIds.add(credit.CC_Order__c);
            }
        }
        if (Trigger.isUpdate || Trigger.isInsert) {
            for (Credit__c credit : newList) {
                orderIds.add(credit.CC_Order__c);
            }
        }
        orders = new Map<Id, ccrz__E_Order__c> (ACAMSOrderDAO.getOrders(orderIds));
    }
    public override void afterInsert() {
        applyCredits();
        createTransferCreditObject();
    }

    public override void afterUpdate() {
        applyCredits();
    }

    public override void afterDelete() {
        applyCredits();
    }

    private void applyCredits() {
        Map<Id, Credit__c> oldCreditMap = new Map<Id, Credit__c>();
        Map<Id, Credit__c> newCreditMap = new Map<Id, Credit__c>();
        if (Trigger.isUpdate || Trigger.isDelete) {
            for (Credit__c credit : oldList) {
                oldCreditMap.put(credit.CC_Order__c, credit);
            }
        }
        if (Trigger.isUpdate || Trigger.isInsert) {
            for (Credit__c credit : newList) {
                newCreditMap.put(credit.CC_Order__c, credit);
            }
        }

        List<ccrz__E_Order__c> ordersToUpdate = new List<ccrz__E_Order__c>();
        for (ccrz__E_Order__c order : orders.values()) {
            Credit__c creditFromOrder;
            if (Trigger.isDelete || Trigger.isUpdate) {
                if (oldCreditMap.containsKey(order.Id)) {
                    creditFromOrder = oldCreditMap.get(order.Id);
                    order.Applied_Credits__c = order.Applied_Credits__c - Math.abs(creditFromOrder.Amount__c);
                }
                if (Trigger.isUpdate) {
                    if (newCreditMap.containsKey(order.Id)) {
                        creditFromOrder = newCreditMap.get(order.Id);
                        ccrz__E_Order__c newOrder = orders.get(creditFromOrder.CC_Order__c);
                        newOrder.Applied_Credits__c = newOrder.Applied_Credits__c + Math.abs(creditFromOrder.Amount__c);
                    }
                }
            } else {
                creditFromOrder = newCreditMap.get(order.Id);
                order.Applied_Credits__c = order.Applied_Credits__c + Math.abs(creditFromOrder.Amount__c);
            }
            ordersToUpdate.add(order);
        }
        update ordersToUpdate;
    }

    private void createTransferCreditObject() {
        List<Credit__c> creditsToInsert = new List<Credit__c>();
        for (Credit__c credit : newList) {
            if (credit.Credit_Type__c == 'Transfer between accounts' && credit.Amount__c > 0) {
                Credit__c clonedCredit = credit.clone();
                clonedCredit.Amount__c = -(credit.Amount__c);
                clonedCredit.Account__c = credit.Origin_Account__c;
                clonedCredit.Origin_Account__c = credit.Account__c;

                creditsToInsert.add(clonedCredit);
            }
        }
        insert creditsToInsert;
    }
}