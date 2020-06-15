trigger ACAMSCaseTrigger on Case (before insert, before update) {
    (new ACAMSCaseTriggerHandler()).run();
}