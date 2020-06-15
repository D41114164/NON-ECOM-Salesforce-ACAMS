trigger ACAMSCaseScoreTrigger on Contact_Center_Scorecard__c (before insert, before update ) {
    (new ACAMSCaseScoreTriggerHandler()).run();
}