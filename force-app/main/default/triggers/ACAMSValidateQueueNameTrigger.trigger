trigger ACAMSValidateQueueNameTrigger on Assignment_Group_Queues__c (before insert, before update) {
    (new ACAMSValidateQueueNameTriggerHandler()).run();
}