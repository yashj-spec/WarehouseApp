@isTest
private class TestHandleProductPriceChange {
	
    static testMethod void testPriceChange() {
        
        Invoice_Statement__c invoice = 
        	new Invoice_Statement__c(
            	Status__c = 'Negotiating'
            );
        
        insert invoice;
        
        Merchandise__c[] products = new Merchandise__c[]{
            new Merchandise__c(
				Name = 'Item 1',
                Description__c = 'Test Product 1',
                Price__c = 10,
                Total_Inventory__c = 10
            ),

			new Merchandise__c(
				Name = 'Item 2',
                Description__c = 'Test Product 2',
                Price__c = 11,
                Total_Inventory__c = 10
            )
        };
        
        insert products;
        
        Line_Item__c[] lineItems = new Line_Item__c[]{
            new Line_Item__c(
				Invoice_Statement__c = invoice.Id,
                Merchandise__c = products[0].Id,
                Unit_Price__c = 10,
                Units_Sold__c = 3
            ),

			new Line_Item__c(
				Invoice_Statement__c = invoice.Id,
                Merchandise__c = products[1].Id,
                Unit_Price__c = 11,
                Units_Sold__c = 6
            )
        };
           
        insert lineItems;
        
        Test.startTest();
        
        products[0].Price__c = 12; 
        products[1].Price__c = 8;
        
        update products;
        
        Test.stopTest();
        
        lineItems = [
            SELECT Unit_Price__c
            FROM Line_Item__c
            ORDER BY Unit_Price__c
        ];
        
        System.assertEquals(
        	8,
            lineItems[0].Unit_Price__c
        );
        
        System.assertEquals(
        	10,
            lineItems[1].Unit_Price__c
        );
    }
	
    static testMethod void testPriceChangeForApprovedInvoice() {

        Invoice_Statement__c invoice = new Invoice_Statement__c(
            Status__c = 'Closed'
        );
        insert invoice;
    
        Merchandise__c product = new Merchandise__c(
            Name = 'Test Product',
            Description__c = 'Test Product',
            Price__c = 10,
            Total_Inventory__c = 10
        );
        insert product;
    
        Line_Item__c lineItem = new Line_Item__c(
            Invoice_Statement__c = invoice.Id,
            Merchandise__c = product.Id,
            Unit_Price__c = 10,
            Units_Sold__c = 2
        );
        insert lineItem;
    
        Test.startTest();
    
        product.Price__c = 5;
        update product;
    
        Test.stopTest();
    
        lineItem = [
            SELECT Unit_Price__c
            FROM Line_Item__c
            WHERE Id = :lineItem.Id
        ];
    
        System.assertEquals(
            10,
            lineItem.Unit_Price__c
        );
    
    }
}