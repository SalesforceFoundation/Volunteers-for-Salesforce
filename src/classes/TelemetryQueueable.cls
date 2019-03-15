public without sharing class TelemetryQueueable implements System.Queueable {
    private List<Telemetry> telemetries;

    public void enqueue(List<Telemetry> telemetries) {
        this.telemetries = telemetries;
        System.enqueueJob(this);
    }

    public void execute(QueueableContext qc) {
        if (telemetries == null) {
            return;
        }

        try {
            for (Telemetry telemetry : telemetries) {
                send(telemetry.getDeveloperName(), telemetry.getValue());
            }

        } catch (Exception ex) {
            throw new TelemetryException(System.Label.TelemetryException);
        }
    }

    @TestVisible
    private void send(String developerName, Object val) {
        if (val instanceof Integer) {
            FeatureManagement.setPackageIntegerValue(developerName, (Integer) val);

        } else {
            throw new TelemetryException(System.Label.TelemetryParamException);
        }
    }

    public class TelemetryException extends Exception {}


    //////////////////// -------------------- ////////////////////

    public class Stub implements System.StubProvider {
        public Integer enqueueCount = 0;

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ){
            switch on stubbedMethodName {
                when 'enqueue' {
                    enqueueCount++;
                    return null;

                } when else {
                    return null;
                }
            }
        }
    }
}