trigger ACAMSRegionFundingTrigger on Regional_Funding__c (Before insert,Before update,After insert,After update) {
    (new ACAMSRegionFundingTriggerHandler()).run();
}