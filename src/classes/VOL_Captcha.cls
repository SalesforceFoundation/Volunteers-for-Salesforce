public with sharing class VOL_Captcha {
    private VOL_Captcha() {}

    @TestVisible 
    private static VOL_Captcha instance = null;

    public static VOL_Captcha getInstance() {
        if (instance == null) {
            instance = new VOL_Captcha();
        }
        return instance;
    }

    /*******************************************************************************************************
    * @description If captcha is enabled, verifies that the token received is valid
    * Return the Boolean verification of the captcha token (or return true if captcha is disabled)
    * @return Boolean value for captcha check
    ********************************************************************************************************/
    private Boolean isEnabled() {
        return VOL_SharedCode.VolunteersSettings.Enable_Site_Captcha__c &&
                !String.isEmpty(VOL_SharedCode.VolunteersSettings.Google_reCaptcha_Site_Key__c) &&
                !String.isEmpty(VOL_SharedCode.VolunteersSettings.Google_reCaptcha_Secret_Key__c) &&
                !String.isEmpty(VOL_SharedCode.VolunteersSettings.Google_reCaptcha_Endpoint__c);
    }    

    /*******************************************************************************************************
    * @description If captcha is enabled, verifies that the token received is valid
    * Return the Boolean verification of the captcha token (or return true if captcha is disabled)
    * @return Boolean value for captcha check
    ********************************************************************************************************/
    public Boolean verifyCaptcha() {
        // If captcha is disabled, pass the check
        if(!isEnabled()){
            return true;
        }
        
        String captchaSecretToken = VOL_SharedCode.VolunteersSettings.Google_reCaptcha_Secret_Key__c;
        String captchaResponse = ApexPages.currentPage().getParameters().get('g-recaptcha-response');        
        Boolean responseSuccess = false;

        // If captcha parameter is missing, fail the check
        if (String.isEmpty(captchaResponse)) {
            return false;
        }

        try {
            // Callout to reCaptcha with response token
            HttpResponse response = VOL_SharedCode.makeHttpCallout(VOL_SharedCode.VolunteersSettings.Google_reCaptcha_Endpoint__c,
                                                    'POST', 
                                                    'secret=' + captchaSecretToken + '&response='+ captchaResponse);
            if(response == null) {
                return responseSuccess;
            }

            JSONParser parser = JSON.createParser(response.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'success')) {
                    parser.nextToken();
                    responseSuccess = parser.getBooleanValue();
                    break;
                }
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        return responseSuccess;
    }    
}