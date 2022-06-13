import ballerina/jballerina.java;
import ballerina/jballerina.java.arrays as jarrays;
import qhana_backend.java.lang as javalang;
import qhana_backend.java.nio.channels as javaniochannels;

# Ballerina class mapping for the Java `java.io.FileOutputStream` class.
@java:Binding {'class: "java.io.FileOutputStream"}
public distinct class FileOutputStream {

    *java:JObject;
    *OutputStream;

    # The `handle` field that stores the reference to the `java.io.FileOutputStream` object.
    public handle jObj;

    # The init function of the Ballerina class mapping the `java.io.FileOutputStream` Java class.
    #
    # + obj - The `handle` value containing the Java reference of the object.
    public function init(handle obj) {
        self.jObj = obj;
    }

    # The function to retrieve the string representation of the Ballerina class mapping the `java.io.FileOutputStream` Java class.
    #
    # + return - The `string` form of the Java object instance.
    public function toString() returns string {
        return java:toString(self.jObj) ?: "null";
    }
    # The function that maps to the `close` method of `java.io.FileOutputStream`.
    #
    # + return - The `IOException` value returning from the Java mapping.
    public function close() returns IOException? {
        error|() externalObj = java_io_FileOutputStream_close(self.jObj);
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `equals` method of `java.io.FileOutputStream`.
    #
    # + arg0 - The `javalang:Object` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function 'equals(javalang:Object arg0) returns boolean {
        return java_io_FileOutputStream_equals(self.jObj, arg0.jObj);
    }

    # The function that maps to the `flush` method of `java.io.FileOutputStream`.
    #
    # + return - The `IOException` value returning from the Java mapping.
    public function 'flush() returns IOException? {
        error|() externalObj = java_io_FileOutputStream_flush(self.jObj);
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `getChannel` method of `java.io.FileOutputStream`.
    #
    # + return - The `javaniochannels:FileChannel` value returning from the Java mapping.
    public function getChannel() returns javaniochannels:FileChannel {
        handle externalObj = java_io_FileOutputStream_getChannel(self.jObj);
        javaniochannels:FileChannel newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getClass` method of `java.io.FileOutputStream`.
    #
    # + return - The `javalang:Class` value returning from the Java mapping.
    public function getClass() returns javalang:Class {
        handle externalObj = java_io_FileOutputStream_getClass(self.jObj);
        javalang:Class newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getFD` method of `java.io.FileOutputStream`.
    #
    # + return - The `FileDescriptor` or the `IOException` value returning from the Java mapping.
    public function getFD() returns FileDescriptor|IOException {
        handle|error externalObj = java_io_FileOutputStream_getFD(self.jObj);
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        } else {
            FileDescriptor newObj = new (externalObj);
            return newObj;
        }
    }

    # The function that maps to the `hashCode` method of `java.io.FileOutputStream`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function hashCode() returns int {
        return java_io_FileOutputStream_hashCode(self.jObj);
    }

    # The function that maps to the `notify` method of `java.io.FileOutputStream`.
    public function notify() {
        java_io_FileOutputStream_notify(self.jObj);
    }

    # The function that maps to the `notifyAll` method of `java.io.FileOutputStream`.
    public function notifyAll() {
        java_io_FileOutputStream_notifyAll(self.jObj);
    }

    # The function that maps to the `wait` method of `java.io.FileOutputStream`.
    #
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function 'wait() returns javalang:InterruptedException? {
        error|() externalObj = java_io_FileOutputStream_wait(self.jObj);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.io.FileOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait2(int arg0) returns javalang:InterruptedException? {
        error|() externalObj = java_io_FileOutputStream_wait2(self.jObj, arg0);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.io.FileOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait3(int arg0, int arg1) returns javalang:InterruptedException? {
        error|() externalObj = java_io_FileOutputStream_wait3(self.jObj, arg0, arg1);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.io.FileOutputStream`.
    #
    # + arg0 - The `byte[]` value required to map with the Java method parameter.
    # + return - The `IOException` value returning from the Java mapping.
    public function write(byte[] arg0) returns IOException?|error? {
        error|() externalObj = java_io_FileOutputStream_write(self.jObj, check jarrays:toHandle(arg0, "byte"));
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.io.FileOutputStream`.
    #
    # + arg0 - The `byte[]` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + arg2 - The `int` value required to map with the Java method parameter.
    # + return - The `IOException` value returning from the Java mapping.
    public function write2(byte[] arg0, int arg1, int arg2) returns IOException?|error? {
        error|() externalObj = java_io_FileOutputStream_write2(self.jObj, check jarrays:toHandle(arg0, "byte"), arg1, arg2);
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.io.FileOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `IOException` value returning from the Java mapping.
    public function write3(int arg0) returns IOException? {
        error|() externalObj = java_io_FileOutputStream_write3(self.jObj, arg0);
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

}

# The constructor function to generate an object of `java.io.FileOutputStream`.
#
# + arg0 - The `File` value required to map with the Java constructor parameter.
# + return - The new `FileOutputStream` class or `FileNotFoundException` error generated.
public function newFileOutputStream1(File arg0) returns FileOutputStream|FileNotFoundException {
    handle|error externalObj = java_io_FileOutputStream_newFileOutputStream1(arg0.jObj);
    if (externalObj is error) {
        FileNotFoundException e = error FileNotFoundException(FILENOTFOUNDEXCEPTION, externalObj, message = externalObj.message());
        return e;
    } else {
        FileOutputStream newObj = new (externalObj);
        return newObj;
    }
}

# The constructor function to generate an object of `java.io.FileOutputStream`.
#
# + arg0 - The `File` value required to map with the Java constructor parameter.
# + arg1 - The `boolean` value required to map with the Java constructor parameter.
# + return - The new `FileOutputStream` class or `FileNotFoundException` error generated.
public function newFileOutputStream2(File arg0, boolean arg1) returns FileOutputStream|FileNotFoundException {
    handle|error externalObj = java_io_FileOutputStream_newFileOutputStream2(arg0.jObj, arg1);
    if (externalObj is error) {
        FileNotFoundException e = error FileNotFoundException(FILENOTFOUNDEXCEPTION, externalObj, message = externalObj.message());
        return e;
    } else {
        FileOutputStream newObj = new (externalObj);
        return newObj;
    }
}

# The constructor function to generate an object of `java.io.FileOutputStream`.
#
# + arg0 - The `FileDescriptor` value required to map with the Java constructor parameter.
# + return - The new `FileOutputStream` class generated.
public function newFileOutputStream3(FileDescriptor arg0) returns FileOutputStream {
    handle externalObj = java_io_FileOutputStream_newFileOutputStream3(arg0.jObj);
    FileOutputStream newObj = new (externalObj);
    return newObj;
}

# The constructor function to generate an object of `java.io.FileOutputStream`.
#
# + arg0 - The `string` value required to map with the Java constructor parameter.
# + return - The new `FileOutputStream` class or `FileNotFoundException` error generated.
public function newFileOutputStream4(string arg0) returns FileOutputStream|FileNotFoundException {
    handle|error externalObj = java_io_FileOutputStream_newFileOutputStream4(java:fromString(arg0));
    if (externalObj is error) {
        FileNotFoundException e = error FileNotFoundException(FILENOTFOUNDEXCEPTION, externalObj, message = externalObj.message());
        return e;
    } else {
        FileOutputStream newObj = new (externalObj);
        return newObj;
    }
}

# The constructor function to generate an object of `java.io.FileOutputStream`.
#
# + arg0 - The `string` value required to map with the Java constructor parameter.
# + arg1 - The `boolean` value required to map with the Java constructor parameter.
# + return - The new `FileOutputStream` class or `FileNotFoundException` error generated.
public function newFileOutputStream5(string arg0, boolean arg1) returns FileOutputStream|FileNotFoundException {
    handle|error externalObj = java_io_FileOutputStream_newFileOutputStream5(java:fromString(arg0), arg1);
    if (externalObj is error) {
        FileNotFoundException e = error FileNotFoundException(FILENOTFOUNDEXCEPTION, externalObj, message = externalObj.message());
        return e;
    } else {
        FileOutputStream newObj = new (externalObj);
        return newObj;
    }
}

# The function that maps to the `nullOutputStream` method of `java.io.FileOutputStream`.
#
# + return - The `OutputStream` value returning from the Java mapping.
public function FileOutputStream_nullOutputStream() returns OutputStream {
    handle externalObj = java_io_FileOutputStream_nullOutputStream();
    OutputStream newObj = new (externalObj);
    return newObj;
}

function java_io_FileOutputStream_close(handle receiver) returns error? = @java:Method {
    name: "close",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_equals(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "equals",
    'class: "java.io.FileOutputStream",
    paramTypes: ["java.lang.Object"]
} external;

function java_io_FileOutputStream_flush(handle receiver) returns error? = @java:Method {
    name: "flush",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_getChannel(handle receiver) returns handle = @java:Method {
    name: "getChannel",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_getClass(handle receiver) returns handle = @java:Method {
    name: "getClass",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_getFD(handle receiver) returns handle|error = @java:Method {
    name: "getFD",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_hashCode(handle receiver) returns int = @java:Method {
    name: "hashCode",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_notify(handle receiver) = @java:Method {
    name: "notify",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_notifyAll(handle receiver) = @java:Method {
    name: "notifyAll",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_nullOutputStream() returns handle = @java:Method {
    name: "nullOutputStream",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_wait(handle receiver) returns error? = @java:Method {
    name: "wait",
    'class: "java.io.FileOutputStream",
    paramTypes: []
} external;

function java_io_FileOutputStream_wait2(handle receiver, int arg0) returns error? = @java:Method {
    name: "wait",
    'class: "java.io.FileOutputStream",
    paramTypes: ["long"]
} external;

function java_io_FileOutputStream_wait3(handle receiver, int arg0, int arg1) returns error? = @java:Method {
    name: "wait",
    'class: "java.io.FileOutputStream",
    paramTypes: ["long", "int"]
} external;

function java_io_FileOutputStream_write(handle receiver, handle arg0) returns error? = @java:Method {
    name: "write",
    'class: "java.io.FileOutputStream",
    paramTypes: ["[B"]
} external;

function java_io_FileOutputStream_write2(handle receiver, handle arg0, int arg1, int arg2) returns error? = @java:Method {
    name: "write",
    'class: "java.io.FileOutputStream",
    paramTypes: ["[B", "int", "int"]
} external;

function java_io_FileOutputStream_write3(handle receiver, int arg0) returns error? = @java:Method {
    name: "write",
    'class: "java.io.FileOutputStream",
    paramTypes: ["int"]
} external;

function java_io_FileOutputStream_newFileOutputStream1(handle arg0) returns handle|error = @java:Constructor {
    'class: "java.io.FileOutputStream",
    paramTypes: ["java.io.File"]
} external;

function java_io_FileOutputStream_newFileOutputStream2(handle arg0, boolean arg1) returns handle|error = @java:Constructor {
    'class: "java.io.FileOutputStream",
    paramTypes: ["java.io.File", "boolean"]
} external;

function java_io_FileOutputStream_newFileOutputStream3(handle arg0) returns handle = @java:Constructor {
    'class: "java.io.FileOutputStream",
    paramTypes: ["java.io.FileDescriptor"]
} external;

function java_io_FileOutputStream_newFileOutputStream4(handle arg0) returns handle|error = @java:Constructor {
    'class: "java.io.FileOutputStream",
    paramTypes: ["java.lang.String"]
} external;

function java_io_FileOutputStream_newFileOutputStream5(handle arg0, boolean arg1) returns handle|error = @java:Constructor {
    'class: "java.io.FileOutputStream",
    paramTypes: ["java.lang.String", "boolean"]
} external;

