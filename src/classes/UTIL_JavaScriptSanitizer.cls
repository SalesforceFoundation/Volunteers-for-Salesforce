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
 * @description A utility class that sanitizes strings used to dynamically create JavaScript objects and arrays
 */

public with sharing class UTIL_JavaScriptSanitizer {
    private static final String SPLIT_DELIMITER = '&split&';

    /********************************************************************************************************
    * @description Converts a custom label that is being used to store comma separated values into a valid JSON string.
    * Assumes values are in quotes (single or double) and separated by commas
    * For Example, the following is stored as a custom label:
        "MediumBlue","Green","DarkRed", "Purple", "DarkSlateGray", "MidnightBlue"
    * To prevent XSS issues, instead of evaluating that as JavaScript in Visualforce, converting this to a
    * valid JSON string so that it can be JS ENCODED and parsed on the front end.
    * @param toParse string that contains key/value pairs
    * @return String as a serialized object
    ********************************************************************************************************/
    public String buildSerializedList(String toParse) {
        List<String> parsedList = new List<String>();
        for (String listItem : toParse.split(',')) {
            parsedList.add(trimStartAndEndQuotes(listItem));
        }
        return JSON.serialize(parsedList).escapeEcmaScript();
    }

    /********************************************************************************************************
    * @description Converts a custom label that is being used to store comma separated key/value pairs
    * into valid JSON. Assumes key values pairs are separated with commas and that values encapsulated in quotes
    * For Example, the following is stored as a custom label
        prev:     '&nbsp;&#9668;&nbsp;',
        next:     '&nbsp;&#9658;&nbsp;',
        prevYear: '&nbsp;&lt;&lt;&nbsp;',
        nextYear: '&nbsp;&gt;&gt;&nbsp;',
        today:    'today',
        month:    'month',
        week:     'week',
        day:      'day'
    * To prevent XSS issues, instead of evaluating that as JavaScript in Visualforce, converting this to
    * a valid JSON string instead to be parsed on the front end.
    * @param toParse string that contains key/value pairs
    * @return String as a JS escaped serialized object
    ********************************************************************************************************/
    public String buildSerializedObject(String toParse) {
        Map<String, String> keyPairings = new Map<String, String>();
        toParse = replaceCommasWithSplitMarkers(toParse);
        List<String> pairings = toParse.split(SPLIT_DELIMITER);
        for (String s : pairings) {
            List<String> keyValue = s.split(':', 2);
            keyPairings.put(
                trimStartAndEndQuotes(keyValue[0]),
                trimStartAndEndQuotes(keyValue[1])
            );
        }

        return JSON.serialize(keyPairings).escapeEcmaScript();
    }

    /********************************************************************************************************
    * @description Replaces commas that separate the values within a custom label (that are also not
    * within the quotes of a value) with a delimiter that can be use to split on
    * @param toParse string to replace commas in
    * @return String with commas replaced with a more distinct delimiter
    ********************************************************************************************************/
    private String replaceCommasWithSplitMarkers(String toParse) {
        Boolean inQuotes = false;
        String openQuoteChar;
        String substitutedValue = '';
        for (Integer i = 0; i < toParse.length(); i++) {
            String currentChar = toParse.substring(i, i + 1);
            //Hit a quote - determine if it's an open or closed quote
            if (currentChar == '\'' || currentChar == '"') {
                if (!inQuotes) {
                    inQuotes = true;
                    openQuoteChar = currentChar;
                } else {
                    inQuotes = false;
                    openQuoteChar = null;
                }
            }

            if (currentChar == ',' && !inQuotes) {
                substitutedValue += SPLIT_DELIMITER;
            } else {
                substitutedValue += currentChar;
            }
        }

        return substitutedValue;
    }

    /********************************************************************************************************
    * @description Removes start and end quotes from a string so they are not included as the value of the string
    * @param toTrim string to remove start and end quotes from
    * @return String with start and end quotes removed
    ********************************************************************************************************/
    private String trimStartAndEndQuotes(String toTrim) {
        toTrim = toTrim.trim();
        //Trim single or double quote from beginning
        if (toTrim.indexOf('\'') == 0) {
            toTrim = toTrim.removeStart('\'');
        } else if (toTrim.indexOf('"') == 0) {
            toTrim = toTrim.removeStart('"');
        }

        //Trim single or double quote from end
        if (toTrim.indexOf('\'') == toTrim.length() - 1) {
            toTrim = toTrim.removeEnd('\'');
        } else if (toTrim.indexOf('"') == toTrim.length() -1) {
            toTrim = toTrim.removeEnd('"');
        }

        return toTrim;
    }
}