public class DuplicateContactTriggerHandler {

    public static void afterInsert(List<Contact> newContacts) {

        if (DuplicateContactTriggerControl.isRunning) {
            return;
        }

        DuplicateContactTriggerControl.isRunning = true;

        DuplicateContactService.handleDuplicateContacts(newContacts);

        DuplicateContactTriggerControl.isRunning = false;
    }
}
