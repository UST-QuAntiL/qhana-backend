import ballerina/jballerina.java;
import ballerina/jballerina.java.arrays as jarrays;
import qhana_backend.java.lang as javalang;
import qhana_backend.java.io as javaio;

# Ballerina class mapping for the Java `java.util.zip.DeflaterOutputStream` class.
@java:Binding {'class: "java.util.zip.DeflaterOutputStream"}
public distinct class DeflaterOutputStream {

    *java:JObject;
    *javaio:FilterOutputStream;

    # The `handle` field that stores the reference to the `java.util.zip.DeflaterOutputStream` object.
    public handle jObj;

    # The init function of the Ballerina class mapping the `java.util.zip.DeflaterOutputStream` Java class.
    #
    # + obj - The `handle` value containing the Java reference of the object.
    public function init(handle obj) {
        self.jObj = obj;
    }

    # The function to retrieve the string representation of the Ballerina class mapping the `java.util.zip.DeflaterOutputStream` Java class.
    #
    # + return - The `string` form of the Java object instance.
    public function toString() returns string {
        return java:toString(self.jObj) ?: "null";
    }
    # The function that maps to the `close` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function close() returns javaio:IOException? {
        error|() externalObj = java_util_zip_DeflaterOutputStream_close(self.jObj);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `equals` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + arg0 - The `javalang:Object` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function 'equals(javalang:Object arg0) returns boolean {
        return java_util_zip_DeflaterOutputStream_equals(self.jObj, arg0.jObj);
    }

    # The function that maps to the `finish` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function finish() returns javaio:IOException? {
        error|() externalObj = java_util_zip_DeflaterOutputStream_finish(self.jObj);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `flush` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function 'flush() returns javaio:IOException? {
        error|() externalObj = java_util_zip_DeflaterOutputStream_flush(self.jObj);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `getClass` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + return - The `javalang:Class` value returning from the Java mapping.
    public function getClass() returns javalang:Class {
        handle externalObj = java_util_zip_DeflaterOutputStream_getClass(self.jObj);
        javalang:Class newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `hashCode` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function hashCode() returns int {
        return java_util_zip_DeflaterOutputStream_hashCode(self.jObj);
    }

    # The function that maps to the `notify` method of `java.util.zip.DeflaterOutputStream`.
    public function notify() {
        java_util_zip_DeflaterOutputStream_notify(self.jObj);
    }

    # The function that maps to the `notifyAll` method of `java.util.zip.DeflaterOutputStream`.
    public function notifyAll() {
        java_util_zip_DeflaterOutputStream_notifyAll(self.jObj);
    }

    # The function that maps to the `wait` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function 'wait() returns javalang:InterruptedException? {
        error|() externalObj = java_util_zip_DeflaterOutputStream_wait(self.jObj);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait2(int arg0) returns javalang:InterruptedException? {
        error|() externalObj = java_util_zip_DeflaterOutputStream_wait2(self.jObj, arg0);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait3(int arg0, int arg1) returns javalang:InterruptedException? {
        error|() externalObj = java_util_zip_DeflaterOutputStream_wait3(self.jObj, arg0, arg1);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + arg0 - The `byte[]` value required to map with the Java method parameter.
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function write(byte[] arg0) returns javaio:IOException?|error? {
        error|() externalObj = java_util_zip_DeflaterOutputStream_write(self.jObj, check jarrays:toHandle(arg0, "byte"));
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + arg0 - The `byte[]` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + arg2 - The `int` value required to map with the Java method parameter.
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function write2(byte[] arg0, int arg1, int arg2) returns javaio:IOException?|error? {
        error|() externalObj = java_util_zip_DeflaterOutputStream_write2(self.jObj, check jarrays:toHandle(arg0, "byte"), arg1, arg2);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.util.zip.DeflaterOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function write3(int arg0) returns javaio:IOException? {
        error|() externalObj = java_util_zip_DeflaterOutputStream_write3(self.jObj, arg0);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

}

# The constructor function to generate an object of `java.util.zip.DeflaterOutputStream`.
#
# + arg0 - The `javaio:OutputStream` value required to map with the Java constructor parameter.
# + return - The new `DeflaterOutputStream` class generated.
public function newDeflaterOutputStream1(javaio:OutputStream arg0) returns DeflaterOutputStream {
    handle externalObj = java_util_zip_DeflaterOutputStream_newDeflaterOutputStream1(arg0.jObj);
    DeflaterOutputStream newObj = new (externalObj);
    return newObj;
}

# The constructor function to generate an object of `java.util.zip.DeflaterOutputStream`.
#
# + arg0 - The `javaio:OutputStream` value required to map with the Java constructor parameter.
# + arg1 - The `boolean` value required to map with the Java constructor parameter.
# + return - The new `DeflaterOutputStream` class generated.
public function newDeflaterOutputStream2(javaio:OutputStream arg0, boolean arg1) returns DeflaterOutputStream {
    handle externalObj = java_util_zip_DeflaterOutputStream_newDeflaterOutputStream2(arg0.jObj, arg1);
    DeflaterOutputStream newObj = new (externalObj);
    return newObj;
}

# The constructor function to generate an object of `java.util.zip.DeflaterOutputStream`.
#
# + arg0 - The `javaio:OutputStream` value required to map with the Java constructor parameter.
# + arg1 - The `Deflater` value required to map with the Java constructor parameter.
# + return - The new `DeflaterOutputStream` class generated.
public function newDeflaterOutputStream3(javaio:OutputStream arg0, Deflater arg1) returns DeflaterOutputStream {
    handle externalObj = java_util_zip_DeflaterOutputStream_newDeflaterOutputStream3(arg0.jObj, arg1.jObj);
    DeflaterOutputStream newObj = new (externalObj);
    return newObj;
}

# The constructor function to generate an object of `java.util.zip.DeflaterOutputStream`.
#
# + arg0 - The `javaio:OutputStream` value required to map with the Java constructor parameter.
# + arg1 - The `Deflater` value required to map with the Java constructor parameter.
# + arg2 - The `boolean` value required to map with the Java constructor parameter.
# + return - The new `DeflaterOutputStream` class generated.
public function newDeflaterOutputStream4(javaio:OutputStream arg0, Deflater arg1, boolean arg2) returns DeflaterOutputStream {
    handle externalObj = java_util_zip_DeflaterOutputStream_newDeflaterOutputStream4(arg0.jObj, arg1.jObj, arg2);
    DeflaterOutputStream newObj = new (externalObj);
    return newObj;
}

# The constructor function to generate an object of `java.util.zip.DeflaterOutputStream`.
#
# + arg0 - The `javaio:OutputStream` value required to map with the Java constructor parameter.
# + arg1 - The `Deflater` value required to map with the Java constructor parameter.
# + arg2 - The `int` value required to map with the Java constructor parameter.
# + return - The new `DeflaterOutputStream` class generated.
public function newDeflaterOutputStream5(javaio:OutputStream arg0, Deflater arg1, int arg2) returns DeflaterOutputStream {
    handle externalObj = java_util_zip_DeflaterOutputStream_newDeflaterOutputStream5(arg0.jObj, arg1.jObj, arg2);
    DeflaterOutputStream newObj = new (externalObj);
    return newObj;
}

# The constructor function to generate an object of `java.util.zip.DeflaterOutputStream`.
#
# + arg0 - The `javaio:OutputStream` value required to map with the Java constructor parameter.
# + arg1 - The `Deflater` value required to map with the Java constructor parameter.
# + arg2 - The `int` value required to map with the Java constructor parameter.
# + arg3 - The `boolean` value required to map with the Java constructor parameter.
# + return - The new `DeflaterOutputStream` class generated.
public function newDeflaterOutputStream6(javaio:OutputStream arg0, Deflater arg1, int arg2, boolean arg3) returns DeflaterOutputStream {
    handle externalObj = java_util_zip_DeflaterOutputStream_newDeflaterOutputStream6(arg0.jObj, arg1.jObj, arg2, arg3);
    DeflaterOutputStream newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `nullOutputStream` method of `java.util.zip.DeflaterOutputStream`.
#
# + return - The `javaio:OutputStream` value returning from the Java mapping.
public function DeflaterOutputStream_nullOutputStream() returns javaio:OutputStream {
    handle externalObj = java_util_zip_DeflaterOutputStream_nullOutputStream();
    javaio:OutputStream newObj = new (externalObj);
    return newObj;
}

function java_util_zip_DeflaterOutputStream_close(handle receiver) returns error? = @java:Method {
    name: "close",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: []
} external;

function java_util_zip_DeflaterOutputStream_equals(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "equals",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["java.lang.Object"]
} external;

function java_util_zip_DeflaterOutputStream_finish(handle receiver) returns error? = @java:Method {
    name: "finish",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: []
} external;

function java_util_zip_DeflaterOutputStream_flush(handle receiver) returns error? = @java:Method {
    name: "flush",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: []
} external;

function java_util_zip_DeflaterOutputStream_getClass(handle receiver) returns handle = @java:Method {
    name: "getClass",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: []
} external;

function java_util_zip_DeflaterOutputStream_hashCode(handle receiver) returns int = @java:Method {
    name: "hashCode",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: []
} external;

function java_util_zip_DeflaterOutputStream_notify(handle receiver) = @java:Method {
    name: "notify",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: []
} external;

function java_util_zip_DeflaterOutputStream_notifyAll(handle receiver) = @java:Method {
    name: "notifyAll",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: []
} external;

function java_util_zip_DeflaterOutputStream_nullOutputStream() returns handle = @java:Method {
    name: "nullOutputStream",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: []
} external;

function java_util_zip_DeflaterOutputStream_wait(handle receiver) returns error? = @java:Method {
    name: "wait",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: []
} external;

function java_util_zip_DeflaterOutputStream_wait2(handle receiver, int arg0) returns error? = @java:Method {
    name: "wait",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["long"]
} external;

function java_util_zip_DeflaterOutputStream_wait3(handle receiver, int arg0, int arg1) returns error? = @java:Method {
    name: "wait",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["long", "int"]
} external;

function java_util_zip_DeflaterOutputStream_write(handle receiver, handle arg0) returns error? = @java:Method {
    name: "write",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["[B"]
} external;

function java_util_zip_DeflaterOutputStream_write2(handle receiver, handle arg0, int arg1, int arg2) returns error? = @java:Method {
    name: "write",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["[B", "int", "int"]
} external;

function java_util_zip_DeflaterOutputStream_write3(handle receiver, int arg0) returns error? = @java:Method {
    name: "write",
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["int"]
} external;

function java_util_zip_DeflaterOutputStream_newDeflaterOutputStream1(handle arg0) returns handle = @java:Constructor {
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["java.io.OutputStream"]
} external;

function java_util_zip_DeflaterOutputStream_newDeflaterOutputStream2(handle arg0, boolean arg1) returns handle = @java:Constructor {
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["java.io.OutputStream", "boolean"]
} external;

function java_util_zip_DeflaterOutputStream_newDeflaterOutputStream3(handle arg0, handle arg1) returns handle = @java:Constructor {
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["java.io.OutputStream", "java.util.zip.Deflater"]
} external;

function java_util_zip_DeflaterOutputStream_newDeflaterOutputStream4(handle arg0, handle arg1, boolean arg2) returns handle = @java:Constructor {
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["java.io.OutputStream", "java.util.zip.Deflater", "boolean"]
} external;

function java_util_zip_DeflaterOutputStream_newDeflaterOutputStream5(handle arg0, handle arg1, int arg2) returns handle = @java:Constructor {
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["java.io.OutputStream", "java.util.zip.Deflater", "int"]
} external;

function java_util_zip_DeflaterOutputStream_newDeflaterOutputStream6(handle arg0, handle arg1, int arg2, boolean arg3) returns handle = @java:Constructor {
    'class: "java.util.zip.DeflaterOutputStream",
    paramTypes: ["java.io.OutputStream", "java.util.zip.Deflater", "int", "boolean"]
} external;

