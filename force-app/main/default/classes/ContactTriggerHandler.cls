public class ContactTriggerHandler {

    public static void afterInsert(List<Contact> newContacts) {

        if (TriggerControl.isRunning) {
            return;
        }

        TriggerControl.isRunning = true;

        ContactDuplicateService.handleDuplicateContacts(newContacts);

        TriggerControl.isRunning = false;
    }
}
