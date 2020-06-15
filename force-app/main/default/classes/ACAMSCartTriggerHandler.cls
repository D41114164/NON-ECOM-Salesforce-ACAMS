public with sharing class ACAMSCartTriggerHandler extends CCAviTriggerHandler {

    private List<ccrz__E_Cart__c> newList = (List<ccrz__E_Cart__c>) Trigger.new;
    private List<ccrz__E_Cart__c> oldList = (List<ccrz__E_Cart__c>) Trigger.old;
    private Map<Id, ccrz__E_Cart__c> newMap = (Map<Id, ccrz__E_Cart__c>) Trigger.newMap;
    private Map<Id, ccrz__E_Cart__c> oldMap = (Map<Id, ccrz__E_Cart__c>) Trigger.oldMap;

    public static Boolean skipLegalEntitySummaryCalculation = false;

    protected override void beforeUpdate() {
        calculateLegalEntitySummary();
        for (ccrz__E_Cart__c cart : newList) {
            if (oldMap.get(cart.Id).Cart_Items_Taxes__c != newMap.get(cart.Id).Cart_Items_Taxes__c) {
                cart.ccrz__TaxAmount__c = cart.Cart_Items_Taxes__c;
            }
        }
    }

    private void calculateLegalEntitySummary() {
        if (!skipLegalEntitySummaryCalculation) {
            ACAMSLegalEntityService.calculateLegalEntitySummary(
                this.newList,
                ccrz__E_Cart__c.Legal_Entity__c.getDescribe().getName(),
                ccrz__E_Cart__c.Legal_Entities_ACAMS_LLC__c.getDescribe().getName(),
                ccrz__E_Cart__c.Legal_Entities_ACAMS_Germany__c.getDescribe().getName(),
                ccrz__E_Cart__c.Legal_Entities_ACAMS_Canada__c.getDescribe().getName(),
                ccrz__E_Cart__c.Legal_Entities_ACAMS_Beijing__c.getDescribe().getName()
            );
        }
    }
}