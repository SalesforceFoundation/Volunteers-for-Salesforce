/*
    Copyright (c) 2019, Salesforce.org
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
public without sharing virtual class DatabaseDml {

    protected DatabaseDml() {}

    @TestVisible private static DatabaseDml instance = null;

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