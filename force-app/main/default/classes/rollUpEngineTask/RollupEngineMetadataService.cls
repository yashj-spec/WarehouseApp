public with sharing class RollupEngineMetadataService {

    // reuturns all active roll-up configurations for the specified child object

    public static List<Rollup_Config__mdt> getRollupConfigurations(String childObjectApiName) {

        if (String.isBlank(childObjectApiName)) {
            return new List<Rollup_Config__mdt>();
        }

        return [
            SELECT Parent_Object__c,
                   Parent_Field__c,
                   Child_Object__c,
                   Child_Field__c,
                   Relationship_Field__c,
                   Aggregate_Function__c,
                   Active__c
            FROM Rollup_Config__mdt
            WHERE Child_Object__c = :childObjectApiName
            AND Active__c = true
        ];
    }
}
