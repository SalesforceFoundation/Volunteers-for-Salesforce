/*
    Copyright (c) 2020 Salesforce.org
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
/**
* @author Salesforce.org
* @date 2020
* @group Utilities
* @description Unit tests for UTIL_HtmlOutput class
*/
@isTest(IsParallel=true)
public with sharing class UTIL_HtmlOutput_TEST {
    /*******************************************************************************************************
    * @description Verifies a string with allowlisted tag with extra space is returned without escaping
    */
    @isTest
    private static void shouldReturnOriginalTagWithSpace() {
        String html = '<b> Bold is allowed </ b>';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = false;

        System.assertEquals(html, controller.getSafeHtml(),'Expected the bold tags with a space to be allowed.');
    }

    /*******************************************************************************************************
    * @description Verifies a string with allowlisted tag is returned without escaping
    */
    @isTest
    private static void shouldReturnOriginalTag() {
        String html = '<b> Bold is allowed </b>';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = false;

        System.assertEquals(html, controller.getSafeHtml(), 'Expected the bold tags to be allowed.');
    }

    /*******************************************************************************************************
    * @description Verifies a string with a tag that is not allowlisted is returned escaped
    */
    @isTest
    private static void shouldReturnEscapedTag() {
        String html = '<img src=x onerror=alert(document.domain)>';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = false;
        String actualHtml = controller.getSafeHtml();

        System.assert(actualHtml.startsWith('&lt;'), 'Expected the img tag to be escaped.');
        System.assertNotEquals(html, actualHtml, 'Expected the html to have been escaped.');
    }

    /*******************************************************************************************************
    * @description Verifies a string with allowlisted url is returned without escaping
    */
    @isTest
    private static void shouldReturnOriginalUrl() {
        String html = '<a href="/ui/setup/apex/batch/ScheduleBatchApexPage">';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;

        System.assertEquals(html, controller.getSafeHtml(), 'Expected the url to be allowed.');
    }

    /*******************************************************************************************************
    * @description Verifies a string with allowlisted url with extra space is returned without the space
    */
    @isTest
    private static void shouldRemoveWhiteSpaceFromUrl() {
        String html = '<a href="/ui/setup/apex/batch/ScheduleBatchApexPage" >';
        String expectedHtml = '<a href="/ui/setup/apex/batch/ScheduleBatchApexPage">';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;

        System.assertEquals(expectedHtml, controller.getSafeHtml(), 'Expected only the space to be removed from the url.');
    }

    /*******************************************************************************************************
    * @description Verifies a string with a url that is not allowlisted is returned escaped
    */
    @isTest
    private static void shouldReturnEscapedUrl() {
        String html = '<a href="www.google.com">';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;
        String actualHtml = controller.getSafeHtml();

        System.assert(actualHtml.startsWith('&lt;'), 'Expected the url to be escaped.');
        System.assertNotEquals(html, actualHtml, 'Expected the html to be espaced.');
    }
    
    /*******************************************************************************************************
    * @description Verifies unallowed attributes within the url are removed
    */
    @isTest
    private static void shouldReturnCleanUrl() {
        String html = '<a href="/ui/setup/apex/batch/ScheduleBatchApexPage" ONMOUSEOVER=alert(document.domain)>';
        String expectedHtml = '<a href="/ui/setup/apex/batch/ScheduleBatchApexPage">';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;
        String actualHtml = controller.getSafeHtml();

        System.assertEquals(expectedHtml, controller.getSafeHtml(), 'Expected the unallowed attributes to be removed from the url.');
    }

    /*******************************************************************************************************
    * @description Verifies target remains in url.
    */
    @isTest
    private static void shouldAllowTargetInUrl() {
        String html = '<a href="/ui/setup/apex/batch/ScheduleBatchApexPage" target="_blank">';
        String expectedHtml = '<a href="/ui/setup/apex/batch/ScheduleBatchApexPage" target="_blank">';
        UTIL_HtmlOutput_CTRL controller = new UTIL_HtmlOutput_CTRL();

        controller.unsafeHtml = html;
        controller.hasUrl = true;
        String actualHtml = controller.getSafeHtml();

        System.assertEquals(expectedHtml, controller.getSafeHtml(), 'Expected the target to remain in the url.');
    }
}
