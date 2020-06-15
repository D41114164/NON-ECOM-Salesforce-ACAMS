trigger ACAMSEcomAssetTrigger on Asset (before insert, after insert, before update, after update) {
    new ACAMSEcomAssetTriggerHandler().run();
}