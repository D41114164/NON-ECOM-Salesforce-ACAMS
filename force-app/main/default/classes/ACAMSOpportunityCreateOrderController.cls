public with sharing class ACAMSOpportunityCreateOrderController {

    private static final String CART_STATUS_OPEN = 'Open';

    @TestVisible private static Id testOrderId;

    public Opportunity targetOpportunity { get; set; }
    public Id newOrderId { get; set; }
    public Boolean successful { get; set; }

    public class ControllerException extends Exception {}

    public ACAMSOpportunityCreateOrderController(ApexPages.StandardController opportunityController) {
        this.targetOpportunity = [
                SELECT
                        Id, Account.Name, ContactId, CC_Cart__c,
                        CC_Cart__r.ccrz__EncryptedId__c, CC_Cart__r.ccrz__CartStatus__c, CC_Cart__r.ccrz__TotalAmount__c
                FROM Opportunity
                WHERE Id = :opportunityController.getId()
        ];
    }

    public PageReference createOrder() {
        ACAMSCsrService.initCsrCallContext(
                this.targetOpportunity.Account,
                this.targetOpportunity.CC_Cart__r.ccrz__EncryptedId__c,
                this.targetOpportunity.ContactId
        );
        Savepoint cartCloneSavepoint = Database.setSavepoint();
        this.successful = false;
        try {
            placeCart();
            this.successful = true;
        } catch (Exception e) {
            Database.rollback(cartCloneSavepoint);
            showError(e.getMessage());
            showError(e.getStackTraceString());
        }
        return null;
    }

    public PageReference goToOpportunityPage() {
        return goToRecordPage(this.targetOpportunity.Id);
    }

    public PageReference goToOrderPage() {
        return goToRecordPage(this.newOrderId);
    }


    private PageReference goToRecordPage(Id recordId) {
        PageReference recordLink = new PageReference('/' + recordId);
        recordLink.setRedirect(true);
        return recordLink;
    }

    private void showError(String errorMessage) {
        ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage)
        );
    }

    private void updateOrderOpportunityLookup(Id orderId, Id opportunityId) {
        update new ccrz__E_Order__c (
                Id = orderId,
                Opportunity__c = opportunityId
        );
    }

    private void placeCart() {
        ccrz__E_Cart__c cart = this.targetOpportunity.CC_Cart__r;
        reopenCartIfRequired(cart);
        Map<String, Object> cartPlaceInputData = new Map<String, Object>{
                ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                ccrz.ccApiCart.CART_ENCID => cart.ccrz__EncryptedId__c,
                ccrz.ccApiCart.CARTSTATUS => cart.ccrz__CartStatus__c,
                ccrz.ccApiCart.SKIP_VALID_CHECK => true
        };
        Map<String, Object> outputData = new Map<String, Object>();
        if (Test.isRunningTest()) {
            outputData = new Map<String, Object>{
                    ccrz.ccApi.SUCCESS => true,
                    ccrz.ccApiCart.ORDER_ID => ACAMSOpportunityCreateOrderController.testOrderId
            };
        } else {
            outputData = ccrz.ccApiCart.place(cartPlaceInputData);
        }
        Boolean success = (Boolean) outputData.get(ccrz.ccApi.SUCCESS);
        if (success) {
            String orderId = (String) outputData.get(ccrz.ccApiCart.ORDER_ID);
            this.newOrderId = Id.valueOf(orderId);
            updateOrderOpportunityLookup(this.newOrderId, this.targetOpportunity.Id);
        } else {
            throw new ControllerException(Label.Opportunity_OrderCreationError);
        }
    }

    private void reopenCartIfRequired(ccrz__E_Cart__c cart) {
        if (cart.ccrz__CartStatus__c == null || cart.ccrz__CartStatus__c != CART_STATUS_OPEN) {
            ccrz__E_Cart__c cartToUpdate = new ccrz__E_Cart__c (
                    Id = cart.Id,
                    ccrz__CartStatus__c = CART_STATUS_OPEN
            );
            update cartToUpdate;
        }
    }

}