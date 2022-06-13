import ballerina/jballerina.java;
import ballerina/jballerina.java.arrays as jarrays;
import qhana_backend.java.lang as javalang;

# Ballerina class mapping for the Java `java.io.FilterOutputStream` class.
@java:Binding {'class: "java.io.FilterOutputStream"}
public distinct class FilterOutputStream {

    *java:JObject;
    *OutputStream;

    # The `handle` field that stores the reference to the `java.io.FilterOutputStream` object.
    public handle jObj;

    # The init function of the Ballerina class mapping the `java.io.FilterOutputStream` Java class.
    #
    # + obj - The `handle` value containing the Java reference of the object.
    public function init(handle obj) {
        self.jObj = obj;
    }

    # The function to retrieve the string representation of the Ballerina class mapping the `java.io.FilterOutputStream` Java class.
    #
    # + return - The `string` form of the Java object instance.
    public function toString() returns string {
        return java:toString(self.jObj) ?: "null";
    }
    # The function that maps to the `close` method of `java.io.FilterOutputStream`.
    #
    # + return - The `IOException` value returning from the Java mapping.
    public function close() returns IOException? {
        error|() externalObj = java_io_FilterOutputStream_close(self.jObj);
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `equals` method of `java.io.FilterOutputStream`.
    #
    # + arg0 - The `javalang:Object` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function 'equals(javalang:Object arg0) returns boolean {
        return java_io_FilterOutputStream_equals(self.jObj, arg0.jObj);
    }

    # The function that maps to the `flush` method of `java.io.FilterOutputStream`.
    #
    # + return - The `IOException` value returning from the Java mapping.
    public function 'flush() returns IOException? {
        error|() externalObj = java_io_FilterOutputStream_flush(self.jObj);
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `getClass` method of `java.io.FilterOutputStream`.
    #
    # + return - The `javalang:Class` value returning from the Java mapping.
    public function getClass() returns javalang:Class {
        handle externalObj = java_io_FilterOutputStream_getClass(self.jObj);
        javalang:Class newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `hashCode` method of `java.io.FilterOutputStream`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function hashCode() returns int {
        return java_io_FilterOutputStream_hashCode(self.jObj);
    }

    # The function that maps to the `notify` method of `java.io.FilterOutputStream`.
    public function notify() {
        java_io_FilterOutputStream_notify(self.jObj);
    }

    # The function that maps to the `notifyAll` method of `java.io.FilterOutputStream`.
    public function notifyAll() {
        java_io_FilterOutputStream_notifyAll(self.jObj);
    }

    # The function that maps to the `wait` method of `java.io.FilterOutputStream`.
    #
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function 'wait() returns javalang:InterruptedException? {
        error|() externalObj = java_io_FilterOutputStream_wait(self.jObj);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.io.FilterOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait2(int arg0) returns javalang:InterruptedException? {
        error|() externalObj = java_io_FilterOutputStream_wait2(self.jObj, arg0);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.io.FilterOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait3(int arg0, int arg1) returns javalang:InterruptedException? {
        error|() externalObj = java_io_FilterOutputStream_wait3(self.jObj, arg0, arg1);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.io.FilterOutputStream`.
    #
    # + arg0 - The `byte[]` value required to map with the Java method parameter.
    # + return - The `IOException` value returning from the Java mapping.
    public function write(byte[] arg0) returns IOException?|error? {
        error|() externalObj = java_io_FilterOutputStream_write(self.jObj, check jarrays:toHandle(arg0, "byte"));
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.io.FilterOutputStream`.
    #
    # + arg0 - The `byte[]` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + arg2 - The `int` value required to map with the Java method parameter.
    # + return - The `IOException` value returning from the Java mapping.
    public function write2(byte[] arg0, int arg1, int arg2) returns IOException?|error? {
        error|() externalObj = java_io_FilterOutputStream_write2(self.jObj, check jarrays:toHandle(arg0, "byte"), arg1, arg2);
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.io.FilterOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `IOException` value returning from the Java mapping.
    public function write3(int arg0) returns IOException? {
        error|() externalObj = java_io_FilterOutputStream_write3(self.jObj, arg0);
        if (externalObj is error) {
            IOException e = error IOException(IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

}

# The constructor function to generate an object of `java.io.FilterOutputStream`.
#
# + arg0 - The `OutputStream` value required to map with the Java constructor parameter.
# + return - The new `FilterOutputStream` class generated.
public function newFilterOutputStream1(OutputStream arg0) returns FilterOutputStream {
    handle externalObj = java_io_FilterOutputStream_newFilterOutputStream1(arg0.jObj);
    FilterOutputStream newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `nullOutputStream` method of `java.io.FilterOutputStream`.
#
# + return - The `OutputStream` value returning from the Java mapping.
public function FilterOutputStream_nullOutputStream() returns OutputStream {
    handle externalObj = java_io_FilterOutputStream_nullOutputStream();
    OutputStream newObj = new (externalObj);
    return newObj;
}

function java_io_FilterOutputStream_close(handle receiver) returns error? = @java:Method {
    name: "close",
    'class: "java.io.FilterOutputStream",
    paramTypes: []
} external;

function java_io_FilterOutputStream_equals(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "equals",
    'class: "java.io.FilterOutputStream",
    paramTypes: ["java.lang.Object"]
} external;

function java_io_FilterOutputStream_flush(handle receiver) returns error? = @java:Method {
    name: "flush",
    'class: "java.io.FilterOutputStream",
    paramTypes: []
} external;

function java_io_FilterOutputStream_getClass(handle receiver) returns handle = @java:Method {
    name: "getClass",
    'class: "java.io.FilterOutputStream",
    paramTypes: []
} external;

function java_io_FilterOutputStream_hashCode(handle receiver) returns int = @java:Method {
    name: "hashCode",
    'class: "java.io.FilterOutputStream",
    paramTypes: []
} external;

function java_io_FilterOutputStream_notify(handle receiver) = @java:Method {
    name: "notify",
    'class: "java.io.FilterOutputStream",
    paramTypes: []
} external;

function java_io_FilterOutputStream_notifyAll(handle receiver) = @java:Method {
    name: "notifyAll",
    'class: "java.io.FilterOutputStream",
    paramTypes: []
} external;

function java_io_FilterOutputStream_nullOutputStream() returns handle = @java:Method {
    name: "nullOutputStream",
    'class: "java.io.FilterOutputStream",
    paramTypes: []
} external;

function java_io_FilterOutputStream_wait(handle receiver) returns error? = @java:Method {
    name: "wait",
    'class: "java.io.FilterOutputStream",
    paramTypes: []
} external;

function java_io_FilterOutputStream_wait2(handle receiver, int arg0) returns error? = @java:Method {
    name: "wait",
    'class: "java.io.FilterOutputStream",
    paramTypes: ["long"]
} external;

function java_io_FilterOutputStream_wait3(handle receiver, int arg0, int arg1) returns error? = @java:Method {
    name: "wait",
    'class: "java.io.FilterOutputStream",
    paramTypes: ["long", "int"]
} external;

function java_io_FilterOutputStream_write(handle receiver, handle arg0) returns error? = @java:Method {
    name: "write",
    'class: "java.io.FilterOutputStream",
    paramTypes: ["[B"]
} external;

function java_io_FilterOutputStream_write2(handle receiver, handle arg0, int arg1, int arg2) returns error? = @java:Method {
    name: "write",
    'class: "java.io.FilterOutputStream",
    paramTypes: ["[B", "int", "int"]
} external;

function java_io_FilterOutputStream_write3(handle receiver, int arg0) returns error? = @java:Method {
    name: "write",
    'class: "java.io.FilterOutputStream",
    paramTypes: ["int"]
} external;

function java_io_FilterOutputStream_newFilterOutputStream1(handle arg0) returns handle = @java:Constructor {
    'class: "java.io.FilterOutputStream",
    paramTypes: ["java.io.OutputStream"]
} external;

