public with sharing class FeatureParam {
    private String developerName;
    private Telemetry telemetry;

    public FeatureParam(String developerName) {
        this.developerName = developerName;
    }

    public FeatureParam withRecordCount(SObjectType sObjType, String criteria) {
        telemetry = new Telemetry(sObjType, criteria).withRecordCount();

        return this;
    }

    public FeatureParam withCustomFieldCount(SObjectType sObjType) {
        telemetry = new Telemetry(sObjType);

        return this;
    }

    public void send() {
        Object val = telemetry.getValue();

        if (val instanceof Boolean) {
            FeatureManagement.setPackageBooleanValue(developerName, (Boolean) val);

        } else if (val instanceof Date) {
            FeatureManagement.setPackageDateValue(developerName, (Date) val);

        } else if (val instanceof Integer) {
            FeatureManagement.setPackageIntegerValue(developerName, (Integer) val);

        } else {
            // sorry this is not the telemetry you are looking for
        }
    }

    private class Telemetry {
        private Boolean isRecordCount;
        private Object val;
        private SObjectType sObjType;
        private String criteria;

        private Telemetry(SObjectType sObjType) {
            this.sObjType = sObjType;
        }

        private Telemetry(SObjectType sObjType, String criteria) {
            this.sObjType = sObjType;
            this.criteria = criteria;
        }

        public Telemetry withRecordCount() {
            isRecordCount = true;

            return this;
        }

        public Object getValue() {
            if (isRecordCount) {
                return getRecordCount();
            } else {
                return getCustomFieldCount();
            }
        }

        private Object getRecordCount() {
            String query = 'SELECT count() FROM {0}';
            if (String.isNotBlank(criteria)) {
                query += ' WHERE ' + criteria;
            }

            return Database.countQuery(query);
        }

        private Object getCustomFieldCount() {
            Schema.DescribeSObjectResult sObjDescribe = sObjType.getDescribe();

            Integer customFieldCount = 0;
            for (String fieldName : sObjDescribe.fields.getMap().keySet()) {
                if (isCustomField(fieldName)) {
                    customFieldCount++;
                }
            }

            return customFieldCount;
        }

        private Boolean isCustomField(String fieldName) {
            final String namespace = String.valueOf(this).substringBefore('.');

            if (String.isNotBlank(namespace) && fieldName.containsIgnoreCase(namespace)) {
                return false;
            }

            if (fieldName.endsWith('__c')) {
                return true;
            }

            return false;
        }
    }

}
