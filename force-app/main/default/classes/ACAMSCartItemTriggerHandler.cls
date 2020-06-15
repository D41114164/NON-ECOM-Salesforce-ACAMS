public with sharing class ACAMSCartItemTriggerHandler extends CCAviTriggerHandler {
    private List<ccrz__E_CartItem__c>    newList = (List<ccrz__E_CartItem__c>)    Trigger.new;
    private List<ccrz__E_CartItem__c>    oldList = (List<ccrz__E_CartItem__c>)    Trigger.old;
    private Map<Id, ccrz__E_CartItem__c> newMap  = (Map<Id, ccrz__E_CartItem__c>) Trigger.newMap;
    private Map<Id, ccrz__E_CartItem__c> oldMap  = (Map<Id, ccrz__E_CartItem__c>) Trigger.oldMap;

    public static Boolean skipPopulateLegalEntityValueFromFormula = false;

    protected override void beforeInsert() {
        populateLegalEntityValueFromFormula();
    }
    protected override void beforeUpdate() {
        populateLegalEntityValueFromFormula();
    }

    private void populateLegalEntityValueFromFormula() {
        if (!skipPopulateLegalEntityValueFromFormula) {
            ACAMSLegalEntityService.updateLineItemLegalEntityFromFormula(
                this.newList,
                ccrz__E_CartItem__c.Legal_Entity_Formula__c.getDescribe().getName(),
                ccrz__E_CartItem__c.Legal_Entity__c.getDescribe().getName()
            );
        }
    }

}