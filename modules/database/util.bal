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

# Helper function to check the types in a raw query at runtime.
#
# + value - the value to check
# + return - the cast value or an error
isolated function checkValue(any|error value) returns sql:Value|error {
    if (value is sql:Value) {
        return value;
    }
    if value is error {
        return error("Template insertion failed with an error!", value);
    } else {
        return error(string `Cannot use inserion ${value.toString()} of type ${(typeof value).toString()} in an sql query!`);
    }
}

# Helper function to check and cast all values in an array.
#
# + values - the values to check
# + return - the cast values or an error
isolated function checkAllValues((any|error)[] values) returns sql:Value[]|error {
    sql:Value[] result = [];
    foreach var val in values {
        result.push(check checkValue(val));
    }
    return result;
}
