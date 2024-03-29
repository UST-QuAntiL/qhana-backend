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

# Prepare dir and make sure that the folder exists.
#
# + path - directory path
# + return - the folder to store experiment data in
public isolated function ensureDirExists(string path) returns string|error {
    var normalizedPath = check file:normalizePath(path, file:CLEAN);
    var abspath = check file:getAbsolutePath(normalizedPath);
    if !(check file:test(abspath, file:EXISTS)) {
        check file:createDir(abspath, file:RECURSIVE);
    }
    return abspath;
}

# Prepare the storage location and make sure that the folder exists.
#
# + experimentId - the id of the experiment to create a folder for
# + storageLocation - location of the storage
# + return - the folder to store experiment data in
public isolated function prepareStorageLocation(int experimentId, string storageLocation) returns string|error {
    var path = check file:joinPath(storageLocation, string `${experimentId}`);
    return ensureDirExists(path);
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
    os:Process|os:Error result;
    string syntax = "windows";
    if os.includes("windows") {
        result = check os:exec({value: "powershell", arguments: ["Expand-Archive", "-DestinationPath", targetDir, zipPath]});
    } else {
        syntax = "linux";
        result = check os:exec({value: "unzip", arguments: [zipPath, "-d", targetDir]});
    }
    if result is os:Error {
            log:printError("Unsupported os type (" + os + ") for file system manipulation (zipExperiment). Using " + syntax + " syntax was unsuccessful...");
            return result;
    } else {
        _ = check result.waitForExit();
    }
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
        log:printDebug("Creating dir " + path + "unsuccessful. Continue anyways...");
    }
}

# Extract filename from path (last segment of path)
#
# + path - path to file
# + return - filename or error
public isolated function extractFilename(string path) returns string|error {
    int? index = path.lastIndexOf("/");
    if index is () {
        index = path.lastIndexOf("\\");
    }
    if index is () {
        return path; // assume that path is filename
    } else {
        return path.substring(index + 1, path.length());
    }
}

# Get temporary dir 
#
# + os - configured os
# + return - tmp dir
public isolated function getTmpDir(string os) returns string {
    if os.includes("windows") {
        var tmpBase = os:getEnv("LocalAppData");
        var tmpDir = file:joinPath(tmpBase, "Temp");
        if tmpDir is error {
            log:printError("Could not access windows tmp directory... create local tmp dir instead.");
            return "tmp";
        } else {
            return tmpDir;
        }
    } else {
        if !os.includes("linux") {
            log:printError("Unsupported os type (" + os + ") for file system manipulation (getTmpDir). Attempt to use linux syntax...");
        }
        return "/tmp";
    }
}
