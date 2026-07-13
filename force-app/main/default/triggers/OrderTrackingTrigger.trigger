trigger OrderTrackingTrigger on Order (after insert, after update) {

    if (Trigger.isAfter) {

        if (Trigger.isInsert || Trigger.isUpdate) {

            OrderTrackingTriggerHandler.updateAccountPurchase(Trigger.new);
        }
    }
}
