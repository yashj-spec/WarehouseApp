trigger OrderTrackingTrigger on Order (
    after insert,
    after update,
    after delete
) {

    if (Trigger.isAfter) {

        if (Trigger.isInsert || Trigger.isUpdate) {

            OrderTrackingTriggerHandler.updateAccountPurchase(Trigger.new);
        }

        if (Trigger.isDelete) {

            OrderTrackingTriggerHandler.updateAccountPurchase(Trigger.old);
        }
    }
}
