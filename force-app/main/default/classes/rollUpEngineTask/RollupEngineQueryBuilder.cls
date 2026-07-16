public with sharing class RollupEngineQueryBuilder {

    // build the aggregate SOQL query based on the roll-up configuration and impacted parent Ids

    public static String buildAggregateQuery (
        Rollup_Config__mdt config,
        Set<Id> parentIds
    ) {

        if (config == null) {
            throw new IllegalArgumentException('Roll-up configuration cannot be null.');
        }

        if (parentIds == null || parentIds.isEmpty()) {
            throw new IllegalArgumentException('Parent Id set cannot be null or empty.');
        }

        String aggregateFunction = config.Aggregate_Function__c.trim().toUpperCase();
        String aggregateExpression;

        if (aggregateFunction == RollupEngineConstants.COUNT_FUNCTION) {

            aggregateExpression = RollupEngineConstants.COUNT_FUNCTION +
                                  '(Id)' +
                                  RollupEngineConstants.AGGREGATE_ALIAS;
        } else {

            aggregateExpression = aggregateFunction +
                                  '(' +
                                  config.Child_Field__c +
                                  ')' +
                                  RollupEngineConstants.AGGREGATE_ALIAS;
        }

        String query = 'SELECT ' +
                       config.Relationship_Field__c +
                       ', ' +
                       aggregateExpression +
                       ' FROM ' +
                       config.Child_Object__c +
                       ' WHERE ' +
                       config.Relationship_Field__c +
                       ' IN :parentIds ' +
                       ' GROUP BY ' +
                       config.Relationship_Field__c;

        return query;
    }
}
