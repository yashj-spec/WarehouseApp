@IsTest
public with sharing class RollupEngineTestDataFactory {

    // creates and inserts the specified number of Accounts
    public static List<Account> createAccounts(Integer count) {

        List<Account> accounts = new List<Account>();

        for (Integer i = 1; i <= count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i
            ));
        }

        insert accounts;

        return accounts;
    }

    // creates Invoice__c records for the given Account
    // if doInsert is true, then the records are inserted
    public static List<Invoice__c> createInvoices(
        Id accountId,
        Integer count,
        Decimal amount,
        Boolean doInsert
    ) {

        List<Invoice__c> invoices = new List<Invoice__c>();

        for (Integer i = 1; i <= count; i++) {

            invoices.add(new Invoice__c(
                Name = 'Invoice ' + i,
                Account__c = accountId,
                Amount__c = amount
            ));
        }

        if (doInsert) {
            insert invoices;
        }

        return invoices;
    }

    // creates bulk invoices distributed across multiple Accounts
    public static List<Invoice__c> createBulkInvoices(
        List<Account> accounts,
        Integer invoicesPerAccount,
        Decimal amount,
        Boolean doInsert
    ) {

        List<Invoice__c> invoices = new List<Invoice__c>();

        Integer invoiceNumber = 1;

        for (Account account : accounts) {

            for (Integer i = 0; i < invoicesPerAccount; i++) {

                invoices.add(new Invoice__c(
                    Name = 'Invoice ' + invoiceNumber++,
                    Account__c = account.Id,
                    Amount__c = amount
                ));
            }
        }

        if (doInsert) {
            insert invoices;
        }

        return invoices;
    }
}
