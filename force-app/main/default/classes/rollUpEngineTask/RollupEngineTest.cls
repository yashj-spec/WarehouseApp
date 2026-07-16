@IsTest
public with sharing class RollupEngineTest {

    @TestSetup
    static void setup(){

        // creates 10 Accounts
        RollupEngineTestDataFactory.createAccounts(10);
    }

    @IsTest
    static void testBulkInsert() {

        List<Account> accounts = [
            SELECT Id
            FROM Account
            ORDER BY Name
        ];

        Test.startTest();

        RollupEngineTestDataFactory.createBulkInvoices(
            accounts,
            20,
            100,
            true
        );

        Test.stopTest();

        accounts = [
            SELECT Id, Total_Amount__c
            FROM Account
            ORDER BY Name
        ];

        for (Account account : accounts) {
            System.assertEquals(2000, account.Total_Amount__c);
        }
    }

    @IsTest
    static void testUpdate() {

        Account account = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        List<Invoice__c> invoices = RollupEngineTestDataFactory.createInvoices(
            account.Id, 2, 100, true
        );

        for (Invoice__c invoice : invoices) {
            invoice.Amount__c = 200;
        }

        Test.startTest();
        update invoices;
        Test.stopTest();

        account = [
            SELECT Total_Amount__c
            FROM Account
            WHERE Id = :account.Id
        ];

        System.assertEquals(400, account.Total_Amount__c);
    }

    @IsTest
    static void testDelete() {

        Account account = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        List<Invoice__c> invoices = RollupEngineTestDataFactory.createInvoices(
            account.Id, 2, 100, true
        );

        Test.startTest();
        delete invoices;
        Test.stopTest();

        account = [
            SELECT Total_Amount__c
            FROM Account
            WHERE Id = :account.Id
        ];

        System.assertEquals(0, account.Total_Amount__c);
    }

    @IsTest
    static void testUndelete() {

        Account account = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        List<Invoice__c> invoices = RollupEngineTestDataFactory.createInvoices(
            account.Id, 2, 100, true
        );

        delete invoices;

        Test.startTest();
        undelete invoices;
        Test.stopTest();

        account = [
            SELECT Total_Amount__c
            FROM Account
            WHERE Id = :account.Id
        ];

        System.assertEquals(200, account.Total_Amount__c);
    }
}
