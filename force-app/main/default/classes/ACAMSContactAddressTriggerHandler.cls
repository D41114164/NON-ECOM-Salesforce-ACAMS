public with sharing class ACAMSContactAddressTriggerHandler extends CCAviTriggerHandler {
    private List<ccrz__E_ContactAddr__c> newList = (List<ccrz__E_ContactAddr__c>) Trigger.new;
    private List<ccrz__E_ContactAddr__c> oldList = (List<ccrz__E_ContactAddr__c>) Trigger.old;
    private Map<Id, ccrz__E_ContactAddr__c> newMap = (Map<Id, ccrz__E_ContactAddr__c>) Trigger.newMap;
    private Map<Id, ccrz__E_ContactAddr__c> oldMap = (Map<Id, ccrz__E_ContactAddr__c>) Trigger.oldMap;

    public static Boolean skipAddressValidation = false;
    public static Boolean skipCountryFieldsCalculation = false;

    protected override void beforeInsert() {
        this.updateRegionField();
    }

    protected override void beforeUpdate() {
        this.updateRegionField();
    }

    protected override void afterInsert() {
        if (!skipAddressValidation) {
            ACAMSAddressValidationService.getContactAddressValidationService()
                .identifyAddressTaxAreaIdAsync(this.newList);
        }
    }

    protected override void afterUpdate() {
        if (!skipAddressValidation) {
            updateAddressesTaxAreaIds();
        }
    }

    private void updateAddressesTaxAreaIds() {
        List<ccrz__E_ContactAddr__c> addressesToUpdateTaxAreaId = new List<ccrz__E_ContactAddr__c>();
        for (ccrz__E_ContactAddr__c currentAddress : this.newList) {
            if (isAddressDataUpdated(currentAddress)) {
                addressesToUpdateTaxAreaId.add(currentAddress);
            }
        }
        if (!addressesToUpdateTaxAreaId.isEmpty()) {
            ACAMSAddressValidationService.getContactAddressValidationService()
                .identifyAddressTaxAreaIdAsync(addressesToUpdateTaxAreaId);
        }
    }

    private void updateRegionField() {
        if (!skipCountryFieldsCalculation) {
            ACAMSAddressFieldsService.beforeTriggerCall(
                this.newList,
                this.oldMap,
                ccrz__E_ContactAddr__c.ccrz__Country__c.getDescribe().getName(),
                ccrz__E_ContactAddr__c.ccrz__CountryISOCode__c.getDescribe().getName(),
                ccrz__E_ContactAddr__c.Region__c.getDescribe().getName(),
                ccrz__E_ContactAddr__c.Continent__c.getDescribe().getName(),
                ccrz__E_ContactAddr__c.Named_Territory__c.getDescribe().getName(),
                ccrz__E_ContactAddr__c.SubTerritory__c.getDescribe().getName()
            );
        }
    }

    private Boolean isAddressDataUpdated(ccrz__E_ContactAddr__c address) {
        ccrz__E_ContactAddr__c previousAddress = this.oldMap.get(address.Id);
        return (
            previousAddress != null && (
                previousAddress.ccrz__AddressFirstline__c != address.ccrz__AddressFirstline__c ||
                previousAddress.ccrz__AddressSecondline__c != address.ccrz__AddressSecondline__c ||
                previousAddress.ccrz__City__c != address.ccrz__City__c ||
                previousAddress.ccrz__StateISOCode__c != address.ccrz__StateISOCode__c ||
                previousAddress.ccrz__State__c != address.ccrz__State__c ||
                previousAddress.ccrz__PostalCode__c != address.ccrz__PostalCode__c ||
                previousAddress.ccrz__CountryISOCode__c != address.ccrz__CountryISOCode__c ||
                previousAddress.ccrz__Country__c != address.ccrz__Country__c
            )
        );
    }

}