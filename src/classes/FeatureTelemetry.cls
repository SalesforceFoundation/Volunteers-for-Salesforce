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
public without sharing class FeatureTelemetry {
    private SObjectType sObjType;
    @TestVisible
    private String developerName;
    private String criteria;

    @TestVisible
    private FeatureParam param {
        get {
            if (param == null) {
                param = createParam();
            }

            return param;
        }
        set;
    }

    @TestVisible
    private QueryBuilder queryBuilder {
        get {
            if (queryBuilder == null) {
                return new QueryBuilder(sObjType);
            }

            return queryBuilder;
        }
        set;
    }

    public FeatureTelemetry(SObjectType sObjType, String developerName) {
        this.sObjType = sObjType;
        this.developerName = developerName;
    }

    public FeatureTelemetry(SObjectType sObjType, String developerName, String criteria) {
        this.sObjType = sObjType;
        this.developerName = developerName;
        this.criteria = criteria;
    }

    public void send() {
        if (sObjType == null || String.isBlank(developerName)) {
            return;
        }

        param.send();
    }

    private FeatureParam createParam() {
        return new FeatureParam(developerName, getRecordCount());
    }

    @TestVisible
    private Integer getRecordCount() {
        queryBuilder.withCondition(criteria);
        return Database.countQuery(queryBuilder.buildCount());
    }


    //////////////////// -------------------- ////////////////////

    public class Stub implements System.StubProvider {
        public Integer sendCount = 0;
        private FeatureParam param;

        public Stub returnParam(FeatureParam param) {
            this.param = param;
            return this;
        }

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            switch on stubbedMethodName {
                when 'send' {
                    sendCount++;
                    return null;

                } when 'createParam' {
                    return param;

                } when else {
                    return null;
                }
            }
        }
    }

}