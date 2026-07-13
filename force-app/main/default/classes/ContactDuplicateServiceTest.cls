@isTest
private class ContactDuplicateServiceTest {

    // Scenario 1 : Single new Contact, no existing match at all.
    // Nothing should be renamed - name stays exactly as entered.

    @isTest
    static void testNoDuplicate_SingleContactStaysUnchanged() {

        Test.startTest();
        insert new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        Test.stopTest();

        List<Contact> result = [SELECT FirstName, LastName FROM Contact];

        System.assertEquals(1, result.size(), 'Only one Contact should exist');
        System.assertEquals('Holmes', result[0].LastName, 'A Contact with no duplicate should keep its original LastName');
    }

    // Scenario 2 : One existing Contact (no suffix) already has this name. Inserting a new one with the same name should push the OLD one to "_1" and let the NEW one keep the plain name.

    @isTest
    static void testExistingUnsuffixedOriginal_GetsRenamedTo_1() {
        Contact original = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        insert original;

        Test.startTest();
        Contact newOne = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        insert newOne;
        Test.stopTest();

        Contact oldReloaded = [SELECT LastName FROM Contact WHERE Id = :original.Id];
        Contact newReloaded = [SELECT LastName FROM Contact WHERE Id = :newOne.Id];

        System.assertEquals('Holmes_1', oldReloaded.LastName, 'The pre-existing Contact should be pushed to _1');
        System.assertEquals('Holmes', newReloaded.LastName, 'The newly inserted Contact should keep the original, unsuffixed name');
    }

    // Scenario 3: Matches the example from the requirements doc.
    // Existing: Holmes, Holmes_1, Holmes_2
    // Insert:   Holmes (new)
    // Expected: old "Holmes" -> "Holmes_3", "Holmes_1" and "Holmes_2"
    // stay as-is, new Contact keeps "Holmes".

    @isTest
    static void testExistingSuffixedSequence_ContinuesCorrectly() {
        Contact original = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        Contact suffixOne = new Contact(FirstName = 'Sherlock', LastName = 'Holmes_1');
        Contact suffixTwo = new Contact(FirstName = 'Sherlock', LastName = 'Holmes_2');
        insert new List<Contact>{ original, suffixOne, suffixTwo };

        Test.startTest();
        Contact newOne = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        insert newOne;
        Test.stopTest();

        Map<Id, Contact> reloaded = new Map<Id, Contact>([
            SELECT LastName FROM Contact
            WHERE Id IN :new List<Id>{ original.Id, suffixOne.Id, suffixTwo.Id, newOne.Id }
        ]);

        System.assertEquals('Holmes_3', reloaded.get(original.Id).LastName, 'The unsuffixed original should be pushed to the next available number (_3)');
        System.assertEquals('Holmes_1', reloaded.get(suffixOne.Id).LastName, 'Existing _1 record should not be touched');
        System.assertEquals('Holmes_2', reloaded.get(suffixTwo.Id).LastName, 'Existing _2 record should not be touched');
        System.assertEquals('Holmes', reloaded.get(newOne.Id).LastName, 'The newly inserted Contact should keep the original, unsuffixed name');
    }

    // Scenario 5: No pre-existing record at all, but the SAME insert
    // batch contains two Contacts with the same name. Since they
    // arrive together, existingOriginal is null, but incomingList
    // has 2 entries - this is the batch-internal duplicate path.

    @isTest
    static void testDuplicatesWithinSameBatch_OnlyLastKeepsOriginalName() {

        Contact first  = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        Contact second = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');

        Test.startTest();
        insert new List<Contact>{ first, second };
        Test.stopTest();

        Map<Id, Contact> reloaded = new Map<Id, Contact>([
            SELECT LastName FROM Contact
            WHERE Id IN :new List<Id>{ first.Id, second.Id }
        ]);

        System.assertEquals('Holmes_1', reloaded.get(first.Id).LastName,
            'The first Contact in the batch should be suffixed');
        System.assertEquals('Holmes', reloaded.get(second.Id).LastName,
            'The last Contact in the batch should keep the original name');
    }

    // Scenario 5: Mixed case - an existing unsuffixed original AND
    // multiple new duplicates in the same batch, all at once.
    // Existing: Holmes, Holmes_1
    // Insert:   Holmes, Holmes, Holmes  (3 new, same batch)
    // Expected: old "Holmes" -> "Holmes_2"
    // new ones -> "Holmes_3", "Holmes_4", and the LAST
    // new one keeps plain "Holmes"

    @isTest
    static void testMixedExistingAndBatchDuplicates() {

        Contact original = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        Contact suffixOne = new Contact(FirstName = 'Sherlock', LastName = 'Holmes_1');
        insert new List<Contact>{ original, suffixOne };

        Contact newA = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        Contact newB = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        Contact newC = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');

        Test.startTest();
        insert new List<Contact>{ newA, newB, newC };
        Test.stopTest();

        Map<Id, Contact> reloaded = new Map<Id, Contact>([
            SELECT LastName FROM Contact
            WHERE Id IN :new List<Id>{ original.Id, suffixOne.Id, newA.Id, newB.Id, newC.Id }
        ]);

        System.assertEquals('Holmes_2', reloaded.get(original.Id).LastName,
            'Old unsuffixed original should be pushed past the existing _1');
        System.assertEquals('Holmes_1', reloaded.get(suffixOne.Id).LastName,
            'Existing _1 record should remain untouched');
        System.assertEquals('Holmes_3', reloaded.get(newA.Id).LastName,
            'First new duplicate should continue the sequence at _3');
        System.assertEquals('Holmes_4', reloaded.get(newB.Id).LastName,
            'Second new duplicate should continue the sequence at _4');
        System.assertEquals('Holmes', reloaded.get(newC.Id).LastName,
            'The last new Contact in the batch should keep the original name');
    }

    // Scenario 6: Contacts with a blank/null FirstName should still
    // be matched against each other correctly (tests the
    // "FirstName = null" OR-branch in the SOQL query).

    @isTest
    static void testBlankFirstName_StillDetectsDuplicates() {

        Contact original = new Contact(FirstName = null, LastName = 'Watson');
        insert original;

        Test.startTest();
        Contact newOne = new Contact(FirstName = null, LastName = 'Watson');
        insert newOne;
        Test.stopTest();

        Contact oldReloaded = [SELECT LastName FROM Contact WHERE Id = :original.Id];
        Contact newReloaded = [SELECT LastName FROM Contact WHERE Id = :newOne.Id];

        System.assertEquals('Watson_1', oldReloaded.LastName,
            'Existing blank-FirstName Contact should still be detected as a duplicate and renamed');
        System.assertEquals('Watson', newReloaded.LastName,
            'New Contact should keep the original name');
    }

    // Scenario 7: Two different names inserted together should never
    // interfere with each other - only the actual duplicate pair
    // should be touched.

    @isTest
    static void testDifferentNames_NoCrossContamination() {

        Contact holmes = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        insert holmes;

        Test.startTest();
        Contact newHolmes = new Contact(FirstName = 'Sherlock', LastName = 'Holmes');
        Contact watson    = new Contact(FirstName = 'John', LastName = 'Watson');
        insert new List<Contact>{ newHolmes, watson };
        Test.stopTest();

        Map<Id, Contact> reloaded = new Map<Id, Contact>([
            SELECT LastName FROM Contact
            WHERE Id IN :new List<Id>{ holmes.Id, newHolmes.Id, watson.Id }
        ]);

        System.assertEquals('Holmes_1', reloaded.get(holmes.Id).LastName,
            'Existing Holmes should be renamed due to the real duplicate');
        System.assertEquals('Holmes', reloaded.get(newHolmes.Id).LastName,
            'New Holmes should keep the original name');
        System.assertEquals('Watson', reloaded.get(watson.Id).LastName,
            'Unrelated Watson record should be completely untouched');
    }

    // Scenario 8: Bulk insert - 200 Contacts in one DML, all sharing
    // the same name, with no pre-existing records. Confirms the
    // trigger stays within governor limits (no SOQL/DML in a loop)
    // and that exactly one record ends up unsuffixed.

    @isTest
    static void testBulkInsert_200RecordsSameName() {

        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            bulkContacts.add(new Contact(FirstName = 'Sherlock', LastName = 'Holmes'));
        }

        Test.startTest();
        insert bulkContacts;
        Test.stopTest();

        List<Contact> reloaded = [
            SELECT LastName FROM Contact
            WHERE FirstName = 'Sherlock' AND LastName LIKE 'Holmes%'
        ];

        System.assertEquals(200, reloaded.size(), 'All 200 records should exist');

        Integer unsuffixedCount = 0;
        Set<String> lastNamesSeen = new Set<String>();

        for (Contact c : reloaded) {
            if (c.LastName == 'Holmes') {
                unsuffixedCount++;
            }
            System.assert(!lastNamesSeen.contains(c.LastName),
                'Every LastName in the sequence should be unique: duplicate found for ' + c.LastName);
            lastNamesSeen.add(c.LastName);
        }

        System.assertEquals(1, unsuffixedCount,
            'Exactly one Contact should end up with the unsuffixed name after a 200-record bulk insert');
    }

    // Scenario 9: Bulk insert mixing several distinct duplicate
    // groups in one batch, to confirm keys don't bleed into each
    // other under bulk conditions.

    @isTest
    static void testBulkInsert_MultipleDistinctDuplicateGroups() {

        List<Contact> bulkContacts = new List<Contact>();

        // 3 "Sherlock Holmes"
        for (Integer i = 0; i < 3; i++) {
            bulkContacts.add(new Contact(FirstName = 'Sherlock', LastName = 'Holmes'));
        }
        // 2 "John Watson"
        for (Integer i = 0; i < 2; i++) {
            bulkContacts.add(new Contact(FirstName = 'John', LastName = 'Watson'));
        }
        // 1 unique "Irene Adler" - should never be touched
        bulkContacts.add(new Contact(FirstName = 'Irene', LastName = 'Adler'));

        Test.startTest();
        insert bulkContacts;
        Test.stopTest();

        List<Contact> holmesGroup = [
            SELECT LastName FROM Contact WHERE FirstName = 'Sherlock'
        ];
        List<Contact> watsonGroup = [
            SELECT LastName FROM Contact WHERE FirstName = 'John'
        ];
        List<Contact> adlerGroup = [
            SELECT LastName FROM Contact WHERE FirstName = 'Irene'
        ];

        System.assertEquals(1, countUnsuffixed(holmesGroup, 'Holmes'),
            'Exactly one unsuffixed Holmes should remain');
        System.assertEquals(1, countUnsuffixed(watsonGroup, 'Watson'),
            'Exactly one unsuffixed Watson should remain');
        System.assertEquals('Adler', adlerGroup[0].LastName,
            'Unique Adler record should be completely unaffected');
    }

    // Scenario 10: test for case-insensitive insertions

    @isTest
    static void testCaseInsensitiveMatching_TreatsDifferentCasingAsSameName() {
        Contact original = new Contact(FirstName = 'Yash', LastName = 'Patel');
        insert original;

        Test.startTest();
        Contact newOne = new Contact(FirstName = 'YAsh', LastName = 'PATEL');
        insert newOne;
        Test.stopTest();

        Contact oldReloaded = [SELECT LastName FROM Contact WHERE Id = :original.Id];
        Contact newReloaded = [SELECT LastName FROM Contact WHERE Id = :newOne.Id];

        System.assertEquals('Patel_1', oldReloaded.LastName,
            'Existing "Yash Patel" should be detected as a duplicate of "YAsh PATEL" and renamed');
        System.assertEquals('PATEL', newReloaded.LastName,
            'New Contact should keep its original casing since it is unsuffixed');
    }

    // small helper used only by the bulk cross-group test above
    private static Integer countUnsuffixed(List<Contact> contacts, String baseName) {
        Integer count = 0;
        for (Contact c : contacts) {
            if (c.LastName == baseName) {
                count++;
            }
        }
        return count;
    }
}
