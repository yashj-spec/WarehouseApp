trigger DuplicateContactTrigger on Contact (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        DuplicateContactTriggerHandler.afterInsert(Trigger.new);
    }
}
