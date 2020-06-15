trigger ACAMSBeckerLMSTrigger on BeckerLMS_Enrollment__c (after insert, after update) {
	(new ACAMSBeckerLMSTriggerHandler()).run();
}