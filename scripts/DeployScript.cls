/**
 * @description Runs the insert package setting method that is normally called by the Install Script during
 * V4S package install.
 */
private void insertPackageSettings() {
    %%%NAMESPACE%%%PackageSettings__c packageSettings = PackageSettings__c.getOrgDefaults();

    if (packageSettings.Id != null) {
        return;
    }

    packageSettings.%%%NAMESPACE%%%NamespacePrefix__c = %%%NAMESPACE%%%VOL_SharedCode.StrTokenNSPrefix('');
    insert packageSettings;
}