// Copyright 2022 University of Stuttgart
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

import ballerina/file;
import ballerina/os;
import ballerina/log;

# Prepare the storage location and make sure that the folder exists.
#
# + experimentId - the id of the experiment to create a folder for
# + storageLocation - location of the storage
# + return - the folder to store experiment data in
public isolated function prepareStorageLocation(int experimentId, string storageLocation) returns string|error {
    // TODO: check, joinPath messes up paths in docker
    // var relPath = check file:joinPath(storageLocation, string `${experimentId}`);
    // var normalizedPath = check file:normalizePath(relPath, file:CLEAN);
    // var abspath = check file:getAbsolutePath(normalizedPath);
    var abspath = check file:getAbsolutePath(storageLocation + "/" + string `${experimentId}`);
    if !(check file:test(abspath, file:EXISTS)) {
        check file:createDir(abspath, file:RECURSIVE);
    }
    return abspath;
}

# Unzip file
#
# TODO: remove once ballerina supports unzipping 
#
# + zipPath - path of zip file
# + targetDir - target directory for unzipping
# + os - os type to determine appropriate exec command
# + return - error 
public isolated function unzipFile(string zipPath, string targetDir, string os) returns error? {
    os:Process result;
    if os.toLowerAscii().includes("linux") {
        result = check os:exec({value: "unzip", arguments: [zipPath, "-d", targetDir]});
    } else if os.toLowerAscii().includes("windows") {
        result = check os:exec({value: "powershell", arguments: ["Expand-Archive", "-DestinationPath", targetDir, zipPath]});
    } else {
        return error("Unsupported operating system! At the moment, we support 'linux' and 'windows' for importing/exporting experiments. Please make sure to properly specify the os env var or config entry.");
    }
    _ = check result.waitForExit();
}

# Wipe and recreate directory if exists
#
# + path - path of directory to be wiped
# + return - error
public isolated function wipeDir(string path) returns error? {
    if check file:test(path, file:EXISTS) {
        check file:remove(path, file:RECURSIVE);
    }
    var x = file:createDir(path);
    if x is error {
        log:printDebug("Creating dir unsuccessful. Continue anyways...");
    }
}
