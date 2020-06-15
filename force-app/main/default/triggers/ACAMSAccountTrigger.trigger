trigger ACAMSAccountTrigger on Account (before insert, after insert, before update, after update) {
    (new ACAMSAccountTriggerHandler()).run();
}