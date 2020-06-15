trigger ACAMSUserTrigger on User (after insert, after update) {
    new ACAMSUserTriggerHandler().run();
}