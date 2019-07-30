public without sharing class DatabaseDml {

    private DatabaseDml() {}

    private static DatabaseDml instance = null;

    public static DatabaseDml getInstance() {
        if (instance == null) {
            instance = new DatabaseDml();
        }
        return instance;
    }

    /*******************************************************************************************************
    * @description Commits a list of updated SObjects
    * @param List of SObjects to update
    ********************************************************************************************************/
    public void updateRecords(List<SObject> sObjects) {
        update sObjects;
    }

    /*******************************************************************************************************
    * @description Commits a list of updated SObjects
    * @param List of SObjects to update
    * @param DML Options for handling duplicates
    ********************************************************************************************************/
    public void updateRecords(List<SObject> sObjects, Database.DMLOptions dmlDuplicateOptions) {
        Database.update(sObjects, dmlDuplicateOptions);
    }

    /*******************************************************************************************************
    * @description Commits a list of SObjects
    * @param List of SObjects to insert
    ********************************************************************************************************/
    public void insertRecords(List<SObject> sObjects) {
        insert sObjects;
    }

    /*******************************************************************************************************
    * @description Commits a list of SObjects
    * @param List of SObjects to insert
    * @param DML Options for handling duplicates
    ********************************************************************************************************/
    public void insertRecords(List<SObject> sObjects, Database.DMLOptions dmlDuplicateOptions) {
        Database.insert(sObjects, dmlDuplicateOptions);
    }
}