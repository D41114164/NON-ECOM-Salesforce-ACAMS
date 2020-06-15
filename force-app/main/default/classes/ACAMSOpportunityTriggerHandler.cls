public without sharing class ACAMSOpportunityTriggerHandler extends CCAviTriggerHandler {

    public static Boolean skipCartAssignOnQuoteSync = false;
    public static Boolean skipCartCreationOnInsert = false;

    private List<Opportunity> newList;
    private List<Opportunity> oldList;
    private Map<Id, Opportunity> newMap;
    private Map<Id, Opportunity> oldMap;

    public ACAMSOpportunityTriggerHandler() {
        super();
        this.newList = (List<Opportunity>) Trigger.new;
        this.oldList = (List<Opportunity>) Trigger.old;
        this.newMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
    }

    protected override void afterInsert() {
        syncContact();
        createCartOnInsert();
    }

    protected override void afterUpdate() {
        syncContact();
        updateCartLookupOnSync();
        updateCoupons();
    }

    private void syncContact() {
        List<Opportunity> opportunities = [
                SELECT  Id, AccountId, Account.IsPersonAccount, Account.PersonContactId, Contact__c,
                        CC_Cart__c, CC_Cart__r.ccrz__Contact__c, CC_Cart__r.ccrz__Account__c
                FROM Opportunity
                WHERE Id IN :newMap.keySet()
        ];
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<ccrz__E_Cart__c> cartsToUpdate = new List<ccrz__E_Cart__c>();
        for (Opportunity opp : opportunities) {
            if (opp.Account.IsPersonAccount && opp.Contact__c == null) {
                opp.Contact__c = opp.Account.PersonContactId;
                oppsToUpdate.add(opp);
                opp.CC_Cart__r.ccrz__Contact__c = opp.Account.PersonContactId;
                opp.CC_Cart__r.ccrz__Account__c = opp.AccountId;
                cartsToUpdate.add(opp.CC_Cart__r);
            }
        }
        update oppsToUpdate;
        update cartsToUpdate;
    }

    private void updateCoupons() {
        for (Opportunity opportunity : newList) {
            if (opportunity.SyncedQuoteId == null && oldMap.get(opportunity.Id).Coupon_Code__c != opportunity.Coupon_Code__c) {
                Savepoint sp = Database.setSavepoint();
                try {
                    Map<String, Object> cartParams = new Map<String, Object>{
                            ccrz.ccApi.API_VERSION => ccrz.ccApi.CURRENT_VERSION,
                            ACAMSLogicCartAddTo.PARAM_SKIP_CART_ACTIVE_SEARCH_FLOW => true,
                            ccrz.ccApiCart.CART_ID => opportunity.CC_Cart__c,
                            ccrz.ccApiCart.COUPON_CODE => opportunity.Coupon_Code__c
                    };
                    if (opportunity.Coupon_Code__c != null) {
                        Map<String, Object> response = ccrz.ccApiCart.addTo(cartParams);
                        Boolean isSuccess = (Boolean) response.get(ccrz.ccApi.SUCCESS);
                        if (!isSuccess) {
                            opportunity.addError('The coupon code "' + opportunity.Coupon_Code__c + '" could not be added because its invalid or the cart does not meet the requirements.');
                            Database.rollback(sp);
                        }
                    } else {
                        if (oldMap.get(opportunity.Id).Coupon_Code__c != null) {
                            cartParams.put(ccrz.ccApiCart.COUPON_CODE, oldMap.get(opportunity.Id).Coupon_Code__c);
                            Map<String, Object> response = ccrz.ccApiCart.removeFrom(cartParams);
                            Boolean isSuccess = (Boolean) response.get(ccrz.ccApi.SUCCESS);
                            if (!isSuccess) {
                                opportunity.addError('The coupon code "' + opportunity.Coupon_Code__c + '" could not be removed.');
                                Database.rollback(sp);
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error in ACAMSOpportunityTriggerHandler: ' + e.getMessage());
                }
            }
        }
    }

    private void updateCartLookupOnSync() {
        if (!skipCartAssignOnQuoteSync) {

            Opportunity opportunityToCheckSync = this.newList[0];
            Opportunity oldOpportunityToCheckSync = this.oldMap.get(opportunityToCheckSync.Id);
            Boolean wasSuccessful = true;

            if (opportunityStartedSync(opportunityToCheckSync, oldOpportunityToCheckSync)) {
                wasSuccessful = ACAMSOpportunityService.replaceOpportunityCartWithQuoteCart(
                        opportunityToCheckSync,
                        opportunityToCheckSync.SyncedQuoteCartId__c
                );
            } else if (opportunityFinishedSync(opportunityToCheckSync, oldOpportunityToCheckSync)) {
                wasSuccessful = ACAMSOpportunityService.cloneCartToOpportunity(
                        opportunityToCheckSync,
                        opportunityToCheckSync.CC_Cart__c
                );
            }
            if (!wasSuccessful) {
                opportunityToCheckSync.addError(Label.QuoteSync_ErrorMessage);
            }
        }
    }

    private void createCartOnInsert() {
        if (!skipCartCreationOnInsert) {
            Opportunity opportunityToCreateCart = this.newList[0];
            Savepoint sp = Database.setSavepoint();
            Boolean wasSuccessful = ACAMSOpportunityService.createNewCartForOpportunity(opportunityToCreateCart);
            if (!wasSuccessful) {
                Database.rollback(sp);
                opportunityToCreateCart.addError(Label.Opportunity_OpportunityCreationError);
            }
        }
    }

    private Boolean opportunityStartedSync(Opportunity currentOpportunity, Opportunity oldOpportunity) {
        return oldOpportunity.SyncedQuoteId == null && currentOpportunity.SyncedQuoteId != null;
    }

    private Boolean opportunityFinishedSync(Opportunity currentOpportunity, Opportunity oldOpportunity) {
        return oldOpportunity.SyncedQuoteId != null && currentOpportunity.SyncedQuoteId == null;
    }
}