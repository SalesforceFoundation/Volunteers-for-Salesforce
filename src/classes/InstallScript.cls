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
public without sharing class InstallScript implements InstallHandler {
    private static final String EMAIL_REPLY_TO = 'donotreply@salesforce.org';
    private static final String EMAIL_TO = 'errors@salesforcefoundation.org';
    private static final String EMAIL_SUBJECT = 'V4S Install Errors';
    private static final String EMAIL_SENDER = 'V4S Install Script';
    private static final String EMAIL_MESSAGE = 'Org ID {0} encountered this error: {1}';
    private InstallContext context;

    @TestVisible
    private TelemetryService telemetryService {
        get {
            if (telemetryService == null) {
                telemetryService = new TelemetryService();
            }

            return telemetryService;
        }
        set;
    }

    public void onInstall(InstallContext context) {
        this.context = context;

        insertPackageSettings();

        if (isUpgrade()) {
            sendUsageMetrics();
        }

    }

    private Boolean isUpgrade() {
        return context.isUpgrade() || context.isPush();
    }

    @TestVisible
    private void insertPackageSettings() {
        PackageSettings__c packageSettings = PackageSettings__c.getOrgDefaults();

        if (packageSettings.Id != null) {
          return;
        }

        packageSettings.NamespacePrefix__c = VOL_SharedCode.StrTokenNSPrefix('');
        insert packageSettings;
    }

    @TestVisible
    private void sendUsageMetrics() {
        try {
            telemetryService.sendUsageMetrics();

        } catch (Exception ex) {
            // Email error and allow the install to continue.
            sendError(
                String.format(
                    EMAIL_MESSAGE,
                    new List<String>{ context.organizationId(), ex.getMessage() }
                )
            );
        }
    }

    private void sendError(String message) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setUseSignature(false);
            mail.setReplyTo(EMAIL_REPLY_TO);
            mail.setSenderDisplayName(EMAIL_SENDER);
            mail.setSubject(EMAIL_SUBJECT);
            mail.setToAddresses(new List<String> { EMAIL_TO });
            mail.setPlainTextBody(message);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception ex) {
            // We do not want to block install when the email cannot be sent, allow the install to continue.
        }

    }
}