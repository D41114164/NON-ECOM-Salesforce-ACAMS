trigger ACAMSCertificationApplicationTrigger on Certification_Application__c (before insert, after insert,
        before update, after update) {
    new ACAMSCertAppTriggerHandler().run();
}