trigger InvoiceTrigger on Invoice__c (
    after insert,
    after update,
    after delete,
    after undelete
) {
    RollupEngineTriggerHandler.handleRollup(
        Trigger.isDelete ? null : Trigger.new,
        Trigger.isInsert || Trigger.isUndelete ? null : Trigger.old
    );
}
