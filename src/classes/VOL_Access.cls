/*
    Copyright (c) 2022, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/*
    This class checks to see if the current user is a guest site user and
    whether or not the admin has elevated the guest site user access. All
    permission checks are expected to be done by the caller.
*/
/* sfca-disable ApexFlsViolationRule */
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
     * @description Calls the create check to verify the users create access
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

        Database.insert(sObjects);
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
