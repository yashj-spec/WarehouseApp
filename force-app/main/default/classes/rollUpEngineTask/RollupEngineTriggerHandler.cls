public with sharing class RollupEngineTriggerHandler {

    // entry point for all child object triggers
    public static void handleRollup(
        List<SObject> newRecords,
        List<SObject> oldRecords
    ) {

        // determine the child object API name
        String childObjectApiName;

        if (newRecords != null && !newRecords.isEmpty()) {
            childObjectApiName = newRecords[0].getSObjectType().getDescribe().getName();
        } else if (oldRecords != null && !oldRecords.isEmpty()) {
            childObjectApiName = oldRecords[0].getSObjectType().getDescribe().getName();
        } else {
            return;
        }

        // fetch active roll-up configurations
        List<Rollup_Config__mdt> rollupConfigs = RollupEngineMetadataService.getRollupConfigurations(childObjectApiName);

        if (rollupConfigs.isEmpty()) {
            return;
        }

        // process each metadata configuration
        for (Rollup_Config__mdt config : rollupConfigs) {

            // skip unsupported aggregate functions
            if (!RollupEngineUtility.isValidAggregateFunction(config.Aggregate_Function__c)) {
                continue;
            }

            // collect impacted parent Ids
            Set<Id> parentIds = RollupEngineUtility.getParentIds(
                newRecords,
                oldRecords,
                config.Relationship_Field__c
            );

            if (parentIds.isEmpty()) {
                continue;
            }

            // perform the roll-up
            RollupEngineService.performRollup(
                config,
                parentIds
            );
        }
    }
}
