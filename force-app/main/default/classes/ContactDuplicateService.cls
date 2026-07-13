public class ContactDuplicateService {

    // it is static (compiled only once)
    // reused for every match instead of recompiling per call
    private static final Pattern SUFFIX_PATTERN = Pattern.compile('^(.*)_(\\d+)$');

    public static void handleDuplicateContacts(List<Contact> newContacts) {

        // Step 1 : first collect all incoming contacts by FirstName|LastName key, while preserving the insertion order
        Map<String, List<Contact>> incomingByKey = new Map<String, List<Contact>>();
        Set<String> incomingFirstNames = new Set<String>();

        for (Contact contact : newContacts) {

            String firstName = contact.FirstName == null ? '' : contact.FirstName.trim();
            String lastName = contact.LastName == null ? '' : contact.LastName.trim();

            String key = buildKey(firstName, lastName);

            if (!incomingByKey.containsKey(key)) {
                incomingByKey.put(key, new List<Contact>());
            }

            incomingByKey.get(key).add(contact);

            incomingFirstNames.add(firstName);
        }

        Set<Id> newContactIds = new Map<Id, Contact>(newContacts).keySet();

        // Step 2: run the query for only existing Contacts that could possibly collide with this batch,
        // narrowed by FirstName instead of pulling the whole table
        List<Contact> existingContacts;

        if (incomingFirstNames.contains('')) {
            existingContacts = [
                SELECT Id, FirstName, LastName
                FROM Contact
                WHERE (
                    FirstName IN :incomingFirstNames
                    OR FirstName = null
                )
                AND Id NOT IN :newContactIds
            ];
        } else {
            existingContacts = [
                SELECT Id, FirstName, LastName
                FROM Contact
                WHERE FirstName IN :incomingFirstNames
                AND Id NOT IN :newContactIds
            ];
        }

        // Step 3: group existing contacts by their BASE key (suffix stripped),
        // keeping only keys relevant to this batch

        Map<String, List<Contact>> existingByKey = new Map<String, List<Contact>>();

        for (Contact contact : existingContacts) {

            String firstName = contact.FirstName == null ? '' : contact.FirstName.trim();

            String baseLastName = getBaseLastName(contact.LastName == null ? '' : contact.LastName.trim());

            String key = buildKey(firstName, baseLastName);

            if (!incomingByKey.containsKey(key)) {
                continue;
            }

            if (!existingByKey.containsKey(key)) {
                existingByKey.put(key, new List<Contact>());
            }

            existingByKey.get(key).add(contact);
        }

        // Step 4 : reconcile every key - handles duplicates already in the DB
        // AND duplicated arriving in the same batch
        List<Contact> contactsToUpdate = new List<Contact>();

        for (String key : incomingByKey.keySet()) {

            List<Contact> incomingList = incomingByKey.get(key);
            List<Contact> existingList = existingByKey.get(key);

            Integer maxSuffix = 0;
            Contact existingOriginal;

            if (existingList != null) {
                for (Contact existingContact : existingList) {

                    Integer suffixNumber = getSuffixNumber(existingContact.LastName);

                    if (suffixNumber == null) {
                        existingOriginal = existingContact;
                    } else if (suffixNumber > maxSuffix) {
                        maxSuffix = suffixNumber;
                    }
                }
            }

            Boolean hasDuplicateSituation = (existingOriginal != null) || (incomingList.size() > 1);

            if (!hasDuplicateSituation) {
                continue;
            }

            // push the existing unsuffixed original into the sequence
            if (existingOriginal != null) {
                maxSuffix++;
                contactsToUpdate.add(new Contact(
                    Id = existingOriginal.Id,
                    LastName = getBaseLastName(existingOriginal.LastName) + '_' + maxSuffix
                ));
            }

            // if several new Contacts share this name, keep only the LAST one unsuffixed;
            // suffix the rest, continuing the sequence
            for (Integer i = 0; i < incomingList.size() - 1; i++) {
                Contact duplicate = incomingList[i];
                maxSuffix++;
                String baseLastName = getBaseLastName(duplicate.LastName == null ? '' : duplicate.LastName.trim());

                contactsToUpdate.add(new Contact(
                    Id = duplicate.Id,
                    LastName = baseLastName + '_' + maxSuffix
                ));
            }
        }

        // Step 5: single DML, partial-failure safe
        if (!contactsToUpdate.isEmpty()) {
            Database.update(contactsToUpdate, false);
        }
    }

    private static String getBaseLastName(String lastName) {

        if (String.isBlank(lastName)) {
            return lastName;
        }

        Matcher match = SUFFIX_PATTERN.matcher(lastName);
        return match.matches() ? match.group(1) : lastName;
    }

    private static Integer getSuffixNumber(String lastName) {

        if(String.isBlank(lastName)) {
            return null;
        }

        Matcher match = SUFFIX_PATTERN.matcher(lastName);
        return match.matches() ? Integer.valueOf(match.group(2)) : null;
    }

    // Builds a case-insensitive grouping key so "Yash Patel" and "YASH PATEL"
    // (or any mix of casing) are treated as the same person.
    private static String buildKey(String firstName, String lastName) {
        String fn = firstName == null ? '' : firstName.trim().toLowerCase();
        String ln = lastName == null ? '' : lastName.trim().toLowerCase();
        return fn + '|' + ln;
    }
}
