// Copyright 2021 University of Stuttgart
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ballerina/sql;


isolated function checkValue(any|error value) returns sql:Value | error {
    if (value is sql:Value) {
        return value;
    }
    if value is error {
        return error("Template insertion failed with an error!", value);
    } else {
        return error(string`Cannot use inserion ${value.toString()} of type ${(typeof value).toString()} in an sql query!`);
    }
}

isolated function checkAllValues((any|error)[] values) returns sql:Value[] | error {
    sql:Value[] result = [];
    foreach var val in values {
        result.push(check checkValue(val));
    }
    return result;
}


# Custom class that allows concatenating raw templates to dynamically build sql queries
public class ConcatQuery {
    *sql:ParameterizedQuery;

    isolated function init(object:RawTemplate... templates) returns error? {
        if (templates.length() == 0) {
            return error("Must provide at least one raw template!");
        } else if (templates.length() == 1) {
            // only one template, just copy values
            self.strings = templates[0].strings;
            self.insertions = check checkAllValues(templates[0].insertions);
        } else {
            // multiple templates, concatenate values
            string[] strings = [];
            sql:Value[] insertions = [];
            string? nextToConcat = ();
            foreach var template in templates {
                foreach var i in 0..<template.strings.length() {
                    // process strings (resulting string array must be exacty one larger than insertions array!)
                    if (i == 0 && nextToConcat != ()) {
                        // if first string check if it must be concatenated with last string of last template
                        if (template.strings.length() == 1) {
                            // template only contains one string (and no insertions)
                            nextToConcat = nextToConcat + template.strings[i];
                        } else {
                            // template contains more strings (and at least one insertion)
                            strings.push(nextToConcat + template.strings[i]);
                            nextToConcat = ();
                        }
                        // string already handled, go to next
                        continue;
                    }
                    if (i == (template.strings.length() - 1)) {
                        // last item is saved in nextToConcat temporarily
                        nextToConcat = template.strings[i];
                    } else {
                        // push middle items directly to array
                        strings.push(template.strings[i]);
                    }
                }
                foreach var inserion in template.insertions {
                    // process template insertions
                    insertions.push(check checkValue(inserion));
                }
            }
            // add last item to strings array (should always exist)
            if (nextToConcat != ()) {
                strings.push(nextToConcat);
            }
            // set values
            self.strings = strings.cloneReadOnly();
            self.insertions = insertions;
        }
    }
}
