trigger ACAMSContactTrigger on Contact (after insert) {
    (new ACAMSContactTriggerHandler()).run();
}