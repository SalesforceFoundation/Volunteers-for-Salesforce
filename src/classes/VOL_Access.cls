public with sharing virtual class VOL_Access {
    protected VOL_Access() {}

    @TestVisible private static VOL_Access instance = null;

    public static VOL_Access getInstance() {
        if (instance == null) {
            instance = new VOL_Access();
        }
        return instance;
    }

    /*******************************************************************************************************
    * @description Calls UserInfo to determine whether the current user is the Sites Guest User
    * @return boolean value indicating whether current user is a guest user
    ********************************************************************************************************/
    @TestVisible
    private Boolean isGuestUser {
        get {
            if (isGuestUser == null) {
                isGuestUser = UserInfo.getUserType() == 'Guest';
            }
            return isGuestUser;
        }
        private set;
    }

    /**
     * @description Custom setting that determines whether or not V4S should grant guest user update access
     * based on their create access.
     */
    @TestVisible
    private Boolean elevateGuestUserAccessSetting {
        get {
            if (elevateGuestUserAccessSetting == null) {
                elevateGuestUserAccessSetting = VOL_SharedCode.VolunteersSettings.Grant_Guest_Users_Update_Access__c;
            }
            return elevateGuestUserAccessSetting;
        }
        set;
    }

    /**
     * @description Determines whether the users update access should match their create access and
     * allows dml to be elevated to system context
     */
    private Boolean isElevated {
        get {
            if (isElevated == null) {
                isElevated = isGuestUser && elevateGuestUserAccessSetting;
            }
            return isElevated;
        }
        private set;
    }

    /**
     * @description Calls the update check to verify the users create access
     */
    public void checkCreateAccess(String objectName, Set<String> fieldNames) {
        UTIL_Describe.checkCreateAccess(objectName, fieldNames);
    }

    /**
     * @description Elevates update to create access checks for elevated users
     */
    public void checkUpdateAccess(String objectName, Set<String> fieldNames) {
        if (isElevated) {
            UTIL_Describe.checkCreateAccess(objectName, fieldNames);
            return;
        }

        UTIL_Describe.checkUpdateAccess(objectName, fieldNames);
    }

    /*******************************************************************************************************
    * @description Routes the DML to the DatabaseDml class for elevated users
    * @param List of SObjects to update
    ********************************************************************************************************/
    public void updateRecords(List<SObject> sObjects) {
        if (isElevated) {
            DatabaseDml.getInstance().updateRecords(sObjects);
            return;
        }

        update sObjects;
    }

    /*******************************************************************************************************
    * @description Routes the DML to the DatabaseDml class for elevated users
    * @param List of SObjects to update
    * @param DML Options for handling duplicates
    ********************************************************************************************************/
    public void updateRecords(List<SObject> sObjects, Database.DMLOptions dmlDuplicateOptions) {
        if (isElevated) {
            DatabaseDml.getInstance().updateRecords(sObjects, dmlDuplicateOptions);
            return;
        }

        Database.update(sObjects, dmlDuplicateOptions);
    }

    /*******************************************************************************************************
    * @description Routes the DML to the DatabaseDml class for elevated users
    * @param List of SObjects to insert
    ********************************************************************************************************/
    public void insertRecords(List<SObject> sObjects) {
        if (isElevated) {
            DatabaseDml.getInstance().insertRecords(sObjects);
            return;
        }

        insert sObjects;
    }

    /*******************************************************************************************************
    * @description Routes the DML to the DatabaseDml class for elevated users
    * @param List of SObjects to insert
    * @param DML Options for handling duplicates
    ********************************************************************************************************/
    public void insertRecords(List<SObject> sObjects, Database.DMLOptions dmlDuplicateOptions) {
        if (isElevated) {
            DatabaseDml.getInstance().insertRecords(sObjects, dmlDuplicateOptions);
            return;
        }

        Database.insert(sObjects, dmlDuplicateOptions);
    }
}
