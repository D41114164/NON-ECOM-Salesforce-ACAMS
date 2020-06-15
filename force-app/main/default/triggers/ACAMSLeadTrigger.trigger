trigger ACAMSLeadTrigger on Lead (after update) {
    (new ACAMSLeadTriggerHandler()).run();
}