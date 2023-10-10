@IsTest
public with sharing class VOL_Captcha_TEST {

    @IsTest
    private static void testCaptchaResponseSuccess() {   
        UTIL_UnitTest.setupCaptchaSettings(true);
        
        PageReference lookupPage = Page.PersonalSiteContactLookup;
        Test.setCurrentPage(lookupPage);
        System.currentPageReference().getParameters().put('g-recaptcha-response', '1234567890');

        HttpMockFactory mock = new HttpMockFactory(200, 'OK', '{"success":true}', new Map<String,String>());        

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Boolean response = VOL_Captcha.getInstance().verifyCaptcha();
        Test.stopTest();
        
        System.assertEquals(true, response);
    }

    @IsTest
    private static void testCaptchaResponseFailure() {
        UTIL_UnitTest.setupCaptchaSettings(true);
        
        PageReference lookupPage = Page.PersonalSiteContactLookup;
        Test.setCurrentPage(lookupPage);
        System.currentPageReference().getParameters().put('g-recaptcha-response', '1234567890');

        HttpMockFactory mock = new HttpMockFactory(200, 'OK', '{"success":false}', new Map<String,String>());        
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Boolean response = VOL_Captcha.getInstance().verifyCaptcha();
        Test.stopTest();
        
        System.assertEquals(false, response);
    }

    @IsTest
    private static void testCaptchaUnexpectedResponseFromEndpoint() {
        UTIL_UnitTest.setupCaptchaSettings(true);
        
        PageReference lookupPage = Page.PersonalSiteContactLookup;
        Test.setCurrentPage(lookupPage);
        System.currentPageReference().getParameters().put('g-recaptcha-response', '1234567890');

        HttpMockFactory mock = new HttpMockFactory(404, '', '', new Map<String,String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Boolean response = VOL_Captcha.getInstance().verifyCaptcha();
        Test.stopTest();
        
        System.assertEquals(false, response);
    }

    @IsTest
    private static void captchaShouldSucceedIfDisabled() {
        UTIL_UnitTest.setupCaptchaSettings(false);

        PageReference lookupPage = Page.PersonalSiteContactLookup;
        Test.setCurrentPage(lookupPage);        

        Test.startTest();
        Boolean response = VOL_Captcha.getInstance().verifyCaptcha();
        Test.stopTest();

        System.assertEquals(true, response);
    }

    @IsTest
    private static void captchaShouldFailIfNoTokenReceived() {
        UTIL_UnitTest.setupCaptchaSettings(true);

        PageReference lookupPage = Page.PersonalSiteContactLookup;
        Test.setCurrentPage(lookupPage);
        
        HttpMockFactory mock = new HttpMockFactory(200, 'OK', '{"success":false}', new Map<String,String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Boolean response = VOL_Captcha.getInstance().verifyCaptcha();
        Test.stopTest();
        
        System.assertEquals(false, response);
    }
}
