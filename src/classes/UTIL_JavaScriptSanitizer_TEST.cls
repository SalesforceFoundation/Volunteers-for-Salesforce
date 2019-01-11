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
/**
 * @author Salesforce.org
 * @date 2019
 * @group Volunteers for Salesforce (V4S)
 * @description Tests for UTIL_JavaScriptSanitizer
 */

@isTest
private with sharing class UTIL_JavaScriptSanitizer_TEST {
    @isTest
    private static void shouldSanitizeAListOfStrings() {
        UTIL_JavaScriptSanitizer sanitizer = new UTIL_JavaScriptSanitizer();

        String colorsListWithDoubleQuotes = '"MediumBlue","Green","DarkRed", "Purple", "DarkSlateGray", "MidnightBlue"';
        String unescapedString = sanitizer.buildSerializedList(colorsListWithDoubleQuotes).replace('\\', '');
        List<Object> colors = (List<Object>) JSON.deserializeUntyped(unescapedString);

        System.assertEquals(6, colors.size(), 'All of the colors should be parsed out of the string');
        System.assertEquals('MediumBlue', String.valueOf(colors[0]),
            'The colors should be parsed out in the correct order');
        System.assertEquals('Green', String.valueOf(colors[1]),
            'The colors should be parsed out in the correct order');
        System.assertEquals('DarkRed', String.valueOf(colors[2]),
            'The colors should be parsed out in the correct order');
        System.assertEquals('Purple', String.valueOf(colors[3]),
            'The colors should be parsed out in the correct order');
        System.assertEquals('DarkSlateGray', String.valueOf(colors[4]),
            'The colors should be parsed out in the correct order');
        System.assertEquals('MidnightBlue', String.valueOf(colors[5]),
            'The colors should be parsed out in the correct order');

        String monthListWithSingleQuotes = '\'Jan\', \'Feb\', \'Mar\', \'Apr\', \'May\', \'Jun\', \'Jul\', \'Aug\', \'Sep\', \'Oct\', \'Nov\', \'Dec\'';
        unescapedString = sanitizer.buildSerializedList(monthListWithSingleQuotes).replace('\\', '');
        List<Object> months = (List<Object>) JSON.deserializeUntyped(unescapedString);

        System.assertEquals(12, months.size(), 'All of the months should be parsed out of the string');
        System.assertEquals('Jan', String.valueOf(months[0]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('Feb', String.valueOf(months[1]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('Mar', String.valueOf(months[2]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('Apr', String.valueOf(months[3]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('May', String.valueOf(months[4]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('Jun', String.valueOf(months[5]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('Jul', String.valueOf(months[6]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('Aug', String.valueOf(months[7]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('Sep', String.valueOf(months[8]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('Oct', String.valueOf(months[9]),
            'All of the months should be parsed out in the correct order');
        System.assertEquals('Nov', String.valueOf(months[10]),
             'All of the months should be parsed out in the correct order');
        System.assertEquals('Dec', String.valueOf(months[11]),
             'All of the months should be parsed out in the correct order');

        String injectedJavaScript = '\'+alert(document.domain)+\'';
        String expectedEscapedString = '[\\"+alert(document.domain)+\\"]';
        System.assertEquals(expectedEscapedString, sanitizer.buildSerializedList(injectedJavaScript),
            'Injected JavaScript should be escaped properly');
    }

    @isTest
    private static void shouldSanitizeKeyValuesPairs() {
        String timeFormat = 'month: \'MMMM yyyy\', week: "MMM d[ yyyy]{ \'&#8212;\'[ MMM] d yyyy}", day: \'dddd, MMM d, yyyy\'';

        UTIL_JavaScriptSanitizer sanitizer = new UTIL_JavaScriptSanitizer();

        String unescapedString = sanitizer.buildSerializedObject(timeFormat).replace('\\', '');
        Map<String, Object> timeFormatByTime =
            (Map<String, Object>) JSON.deserializeUntyped(unescapedString);

        System.assert(timeFormatByTime.containsKey('month'), 'Time format object should contain the "month" key');
        System.assertEquals('MMMM yyyy', String.valueOf(timeFormatByTime.get('month')),
            'The correct value should be mapped to the"month" key');

        System.assert(timeFormatByTime.containsKey('week'), 'Time format object should contain the "week" key');
        System.assertEquals('MMM d[ yyyy]{ \'&#8212;\'[ MMM] d yyyy}', String.valueOf(timeFormatByTime.get('week')),
            'The correct value should be mapped to the"week" key');

        System.assert(timeFormatByTime.containsKey('day'), 'Time format object should contain the "day" key');
        System.assertEquals('dddd, MMM d, yyyy', String.valueOf(timeFormatByTime.get('day')),
            'The correct value should be mapped to the"day" key');


        String buttonLabels =
          'prev:     \'&nbsp;&#9668;&nbsp;\','
        + 'next:     \'&nbsp;&#9658;&nbsp;\','
        + 'prevYear: \'&nbsp;&lt;&lt;&nbsp;\','
        + 'nextYear: \'&nbsp;&gt;&gt;&nbsp;\','
        + 'today:    \'today\','
        + 'month:    \'month\','
        + 'week:     \'week\','
        + 'day:      \'day\'';

        unescapedString = sanitizer.buildSerializedObject(buttonLabels).replace('\\', '');
        Map<String, Object> buttonLabelByButtonType =
            (Map<String, Object>) JSON.deserializeUntyped(unescapedString);

        System.assert(buttonLabelByButtonType.containsKey('prev'),
            'The button label object should contain the "prev" key');
        System.assertEquals('&nbsp;&#9668;&nbsp;', String.valueOf(buttonLabelByButtonType.get('prev')),
            'The correct value should be mapped to the "prev" key');

        System.assert(buttonLabelByButtonType.containsKey('next'),
            'The button label object should contain the "next" key');
        System.assertEquals('&nbsp;&#9658;&nbsp;', String.valueOf(buttonLabelByButtonType.get('next')),
            'The correct value should be mapped to the "next" key');

        System.assert(buttonLabelByButtonType.containsKey('prevYear'),
            'The button label object should contain the "prevYear" key');
        System.assertEquals('&nbsp;&lt;&lt;&nbsp;', String.valueOf(buttonLabelByButtonType.get('prevYear')),
            'The correct value should be mapped to the "prevYear" key');

        System.assert(buttonLabelByButtonType.containsKey('nextYear'),
            'The button label object should contain the "nextYear" key');
        System.assertEquals('&nbsp;&gt;&gt;&nbsp;', String.valueOf(buttonLabelByButtonType.get('nextYear')),
            'The correct value should be mapped to the "nextYear" key');

        System.assert(buttonLabelByButtonType.containsKey('today'),
            'The button label object should contain the "today" key');
        System.assertEquals('today', String.valueOf(buttonLabelByButtonType.get('today')),
            'The correct value should be mapped to the "today" key');

        System.assert(buttonLabelByButtonType.containsKey('month'),
            'The button label object should contain the "month" key');
        System.assertEquals('month', String.valueOf(buttonLabelByButtonType.get('month')),
            'The correct value should be mapped to the "month" key');

        System.assert(buttonLabelByButtonType.containsKey('week'),
            'The button label object should contain the "week" key');
        System.assertEquals('week', String.valueOf(buttonLabelByButtonType.get('week')),
            'The correct value should be mapped to the "week" key');

        System.assert(buttonLabelByButtonType.containsKey('day'),
            'The button label object should contain the "day" key');
        System.assertEquals('day', String.valueOf(buttonLabelByButtonType.get('day')),
            'The correct value should be mapped to the "day" key');

        String injectedJavaScript = 'prev:     \'+alert(document.domain)+\'';
        String expectedEscapedString = '{\\"prev\\":\\"+alert(document.domain)+\\"}';

        System.assertEquals(expectedEscapedString, sanitizer.buildSerializedObject(injectedJavaScript),
            'Injected JavaScript should be escaped properly');
    }
}