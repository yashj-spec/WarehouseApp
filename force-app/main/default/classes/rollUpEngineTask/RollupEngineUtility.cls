public with sharing class RollupEngineUtility {

    // it will collect parentIds from Trigger.new/Trigger.old records
    // handles insert, update, delete and undelete
    public static Set<Id> getParentIds(
        List<SObject> newRecords,
        List<SObject> oldRecords,
        String relationshipField
    ) {
        Set<Id> parentIds = new Set<Id>();

        if (newRecords != null) {
            for (SObject record : newRecords) {
                Id parentId = (Id) record.get(relationshipField);

                if (parentId != null) {
                    parentIds.add(parentId);
                }
            }
        }

        if (oldRecords != null) {
            for (SObject record : oldRecords) {
                Id parentId = (Id) record.get(relationshipField);

                if (parentId != null) {
                    parentIds.add(parentId);
                }
            }
        }

        return parentIds;
    }

    // returns true if the aggregate function is supported by the engine
    public static Boolean isValidAggregateFunction(String aggregateFunction) {

        if (String.isBlank(aggregateFunction)) {
            return false;
        }

        aggregateFunction = aggregateFunction.trim().toUpperCase();

        return aggregateFunction == RollupEngineConstants.SUM_FUNCTION
            || aggregateFunction == RollupEngineConstants.AVG_FUNCTION
            || aggregateFunction == RollupEngineConstants.MIN_FUNCTION
            || aggregateFunction == RollupEngineConstants.MAX_FUNCTION
            || aggregateFunction == RollupEngineConstants.COUNT_FUNCTION;
    }

    // returns the value from AggregateResult
    public static Object getAggregateValue(AggregateResult result) {

        if (result == null) {
            return null;
        }

        return result.get(RollupEngineConstants.AGGREGATE_ALIAS);
    }

    // checks whether a field exists on an object
    public static Boolean isFieldValid(
        Schema.SObjectType objectType,
        String fieldApiName
    ) {

        return objectType.getDescribe()
                         .fields.getMap()
                         .containsKey(fieldApiName);
    }

    // checks whether an object exists in the org
    public static Boolean isObjectValid(String objectApiName) {

        return Schema.getGlobalDescribe().containsKey(objectApiName);
    }
}
