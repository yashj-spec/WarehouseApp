public with sharing class RollupEngineService {

    // performs the roll-up operation for a single metadata configuration
    public static void performRollup(
        Rollup_Config__mdt config,
        Set<Id> parentIds
    ) {

        if (config == null || parentIds == null || parentIds.isEmpty()) {
            return;
        }

        // build the aggregate SOQL QUERY
        String query = RollupEngineQueryBuilder.buildAggregateQuery(config, parentIds);

        // execute the aggregate QUERY
        List<AggregateResult> aggregateResults = Database.query(query);

        // parentId -> aggregateValue
        Map<Id, Object> aggregateMap = new Map<Id, Object>();

        for (AggregateResult result : aggregateResults) {

            Id parentId = (Id) result.get(config.Relationship_Field__c);

            Object aggregateValue = RollupEngineUtility.getAggregateValue(result);

            aggregateMap.put(parentId, aggregateValue);
        }

        // parent object describe
        Schema.SObjectType parentType = Schema.getGlobalDescribe().get(config.Parent_Object__c);

        List<SObject> parentsToUpdate = new List<SObject>();

        for (Id parentId : parentIds) {

            SObject parentRecord = parentType.newSObject(parentId);

            Object value = aggregateMap.get(parentId);

            String aggregateFunction =
                config.Aggregate_Function__c.trim().toUpperCase();

            // if no child records exist after delete, reset the roll-up field
            if (value == null) {

                if (aggregateFunction == RollupEngineConstants.SUM_FUNCTION ||
                    aggregateFunction == RollupEngineConstants.COUNT_FUNCTION) {

                    value = 0;
                } else {
                    value = null;
                }
            }

            // determine the parent field's data type
            Map<String, Schema.SObjectField> fieldMap =
                parentType.getDescribe().fields.getMap();

            Schema.DescribeFieldResult fieldDescribe =
                fieldMap.get(config.Parent_Field__c).getDescribe();

            Schema.DisplayType fieldType = fieldDescribe.getType();

            // convert the aggregate value to the appropriate type
            switch on fieldType {

                when INTEGER {
                    parentRecord.put(
                        config.Parent_Field__c,
                        value == null
                               ? null
                               : Integer.valueOf(String.valueOf(value))
                    );
                }

                when DOUBLE, CURRENCY, PERCENT {
                    parentRecord.put(
                        config.Parent_Field__c,
                        value == null
                               ? null
                               : Decimal.valueOf(String.valueOf(value))
                    );
                }

                when else {
                    parentRecord.put(
                        config.Parent_Field__c,
                        value
                    );
                }
            }

            parentsToUpdate.add(parentRecord);
        }

        if (!parentsToUpdate.isEmpty()) {
            update parentsToUpdate;
        }
    }
}
