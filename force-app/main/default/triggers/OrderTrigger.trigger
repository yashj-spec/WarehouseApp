trigger OrderTrigger on Order (after insert, after update) {
    
    if (Trigger.isAfter) {
        
        if (Trigger.isInsert || Trigger.isUpdate) {
            
            OrderTriggerHandler.updateAccountPurchase(Trigger.new);
        }
    }
}