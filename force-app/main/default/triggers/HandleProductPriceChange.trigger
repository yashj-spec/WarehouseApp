// synchronous test
trigger HandleProductPriceChange on Merchandise__c (after update) {
	
    List<Line_Item__c> openLineItems = [
        SELECT 
        	Id,
        	Unit_Price__c, 
        	Merchandise__r.Price__c 
        FROM Line_Item__c 
		WHERE Invoice_Statement__r.Status__c = 'Negotiating' 
		AND Merchandise__c IN :Trigger.new 
    ];
    
	List<Line_Item__c> updates = new List<Line_Item__c>();
    
    for (Line_Item__c li : openLineItems) {
        
        if (li.Merchandise__r.Price__c < li.Unit_Price__c) {
			
            updates.add(
            	new Line_Item__c(
                	Id = li.Id,
                    Unit_Price__c = li.Merchandise__r.Price__c
                )
            );
        }
    }

    if (!updates.isEmpty()) {
        update updates;
    }
}