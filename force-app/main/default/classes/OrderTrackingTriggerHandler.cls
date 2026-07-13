public class OrderTrackingTriggerHandler {

    public static void updateAccountPurchase(List<Order> orderList) {

		Set<Id> accountIds = new Set<Id>();

        for (Order order : orderList) {

            if (order.AccountId != null) {

                accountIds.add(order.AccountId);
            }
        }

        List<Order> allOrders = [
            SELECT Id, AccountId, TotalAmount
            FROM Order
            WHERE AccountId IN :accountIds
        ];

        Map<Id, Decimal> accountTotals = new Map<Id, Decimal>();

        for (Order order : allOrders) {

            Decimal amount = order.TotalAmount == null ? 0 : order.TotalAmount;

            if (accountTotals.containsKey(order.AccountId)) {

                accountTotals.put(order.AccountId, accountTotals.get(order.AccountId) + amount);
            }
            else {
                accountTotals.put(order.AccountId, amount);
            }
        }

        List<Account> accounts = [
        	SELECT Id, Total_Purchase_Amount__c, Customer_Tier__c
            FROM Account
			WHERE Id IN :accountIds
        ];

        for (Account account : accounts) {
        	Decimal total = accountTotals.get(account.Id);
            account.Total_Purchase_Amount__c = total;

            if (total <= 100000) {
            	account.Customer_Tier__c = 'Bronze';
            }
            else if (total <= 500000) {
            	account.Customer_Tier__c = 'Silver';
            }
            else {
            	account.Customer_Tier__c = 'Gold';
            }
        }

        update accounts;
    }
}
