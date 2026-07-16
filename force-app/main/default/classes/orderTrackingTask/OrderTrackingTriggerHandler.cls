public class OrderTrackingTriggerHandler {

    public static void updateAccountPurchase(List<Order> orderList) {

		Set<Id> accountIds = new Set<Id>();

        for (Order order : orderList) {

            if (order.AccountId != null) {

                accountIds.add(order.AccountId);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        List<Order> allOrders = [
            SELECT Id, AccountId, TotalAmount
            FROM Order
            WHERE AccountId IN :accountIds
        ];

        Map<Id, Decimal> accountTotals = new Map<Id, Decimal>();
        Map<Id, Integer> accountOrderCounts = new Map<Id, Integer>();

        for (Order order : allOrders) {

            Decimal amount = order.TotalAmount == null ? 0 : order.TotalAmount;

            if (!accountTotals.containsKey(order.AccountId)) {

                accountTotals.put(order.AccountId, 0);
                accountOrderCounts.put(order.AccountId, 0);
            }

            accountTotals.put(
                order.AccountId,
                accountTotals.get(order.AccountId) + amount
            );

            accountOrderCounts.put(
                order.AccountId,
                accountOrderCounts.get(order.AccountId) + 1
            );
        }

        List<Account> accounts = [
        	SELECT Id,
                   Total_Purchase_Amount__c,
                   Customer_Tier__c,
                   Total_Order_Amount__c,
                   Total_Orders_Count__c,
                   Customer_Status__c
            FROM Account
			WHERE Id IN :accountIds
        ];

        for (Account account : accounts) {

        	Decimal totalAmount = accountTotals.containsKey(account.Id)
                                ? accountTotals.get(account.Id)
                                : 0;

            Integer totalOrders = accountOrderCounts.containsKey(account.Id)
                                ? accountOrderCounts.get(account.Id)
                                : 0;

            // Task 1: Trigger task
            // find the Customer_Tier from the Total_Purchase_Amount of the Orders

            account.Total_Purchase_Amount__c = totalAmount;

            if (totalAmount <= 100000) {
            	account.Customer_Tier__c = 'Bronze';
            }
            else if (totalAmount <= 500000) {
            	account.Customer_Tier__c = 'Silver';
            }
            else {
            	account.Customer_Tier__c = 'Gold';
            }

            // Task 2: Customer Order Tracking
            // find the Customer_Status from the Total_Order_Amount of the Orders

            account.Total_Order_Amount__c = totalAmount;
            account.Total_Orders_Count__c = totalOrders;

            if (totalAmount == 0 || totalOrders == 0) {
            	account.Customer_Status__c = 'Prospect';
            }
            else if (totalAmount <= 500000) {
            	account.Customer_Status__c = 'Customer';
            }
            else {
            	account.Customer_Status__c = 'Premium Customer';
            }
        }

        update accounts;
    }
}
