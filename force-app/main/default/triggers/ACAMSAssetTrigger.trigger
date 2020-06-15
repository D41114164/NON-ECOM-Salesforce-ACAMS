trigger ACAMSAssetTrigger on Asset (after insert, after update) {
    (new ACAMSAssetTriggerHandler()).run();
}