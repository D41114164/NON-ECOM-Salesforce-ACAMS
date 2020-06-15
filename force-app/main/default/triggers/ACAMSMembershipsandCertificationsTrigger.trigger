trigger ACAMSMembershipsandCertificationsTrigger on Memberships_and_Certifications__c (after insert, after update) {
     (new ACAMSMemsandCertTriggerHandler()).run();
}