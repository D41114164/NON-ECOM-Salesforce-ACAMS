trigger ACAMSQuoteTrigger on Quote (
    before insert,
    after insert,
    before update,
    after update,
    before delete,
    after delete,
    after undelete
) {
    (new ACAMSQuoteTriggerHandler()).run();
}