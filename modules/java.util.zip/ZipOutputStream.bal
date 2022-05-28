import ballerina/jballerina.java;
import ballerina/jballerina.java.arrays as jarrays;
import qhana_backend.java.lang as javalang;
import qhana_backend.java.io as javaio;
import qhana_backend.java.nio.charset as javaniocharset;

# Ballerina class mapping for the Java `java.util.zip.ZipOutputStream` class.
@java:Binding {'class: "java.util.zip.ZipOutputStream"}
public distinct class ZipOutputStream {

    *java:JObject;
    *DeflaterOutputStream;

    # The `handle` field that stores the reference to the `java.util.zip.ZipOutputStream` object.
    public handle jObj;

    # The init function of the Ballerina class mapping the `java.util.zip.ZipOutputStream` Java class.
    #
    # + obj - The `handle` value containing the Java reference of the object.
    public function init(handle obj) {
        self.jObj = obj;
    }

    # The function to retrieve the string representation of the Ballerina class mapping the `java.util.zip.ZipOutputStream` Java class.
    #
    # + return - The `string` form of the Java object instance.
    public function toString() returns string {
        return java:toString(self.jObj) ?: "null";
    }
    # The function that maps to the `close` method of `java.util.zip.ZipOutputStream`.
    #
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function close() returns javaio:IOException? {
        error|() externalObj = java_util_zip_ZipOutputStream_close(self.jObj);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `closeEntry` method of `java.util.zip.ZipOutputStream`.
    #
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function closeEntry() returns javaio:IOException? {
        error|() externalObj = java_util_zip_ZipOutputStream_closeEntry(self.jObj);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `equals` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `javalang:Object` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function 'equals(javalang:Object arg0) returns boolean {
        return java_util_zip_ZipOutputStream_equals(self.jObj, arg0.jObj);
    }

    # The function that maps to the `finish` method of `java.util.zip.ZipOutputStream`.
    #
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function finish() returns javaio:IOException? {
        error|() externalObj = java_util_zip_ZipOutputStream_finish(self.jObj);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `flush` method of `java.util.zip.ZipOutputStream`.
    #
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function 'flush() returns javaio:IOException? {
        error|() externalObj = java_util_zip_ZipOutputStream_flush(self.jObj);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `getClass` method of `java.util.zip.ZipOutputStream`.
    #
    # + return - The `javalang:Class` value returning from the Java mapping.
    public function getClass() returns javalang:Class {
        handle externalObj = java_util_zip_ZipOutputStream_getClass(self.jObj);
        javalang:Class newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `hashCode` method of `java.util.zip.ZipOutputStream`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function hashCode() returns int {
        return java_util_zip_ZipOutputStream_hashCode(self.jObj);
    }

    # The function that maps to the `notify` method of `java.util.zip.ZipOutputStream`.
    public function notify() {
        java_util_zip_ZipOutputStream_notify(self.jObj);
    }

    # The function that maps to the `notifyAll` method of `java.util.zip.ZipOutputStream`.
    public function notifyAll() {
        java_util_zip_ZipOutputStream_notifyAll(self.jObj);
    }

    # The function that maps to the `putNextEntry` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `ZipEntry` value required to map with the Java method parameter.
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function putNextEntry(ZipEntry arg0) returns javaio:IOException? {
        error|() externalObj = java_util_zip_ZipOutputStream_putNextEntry(self.jObj, arg0.jObj);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `setComment` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `string` value required to map with the Java method parameter.
    public function setComment(string arg0) {
        java_util_zip_ZipOutputStream_setComment(self.jObj, java:fromString(arg0));
    }

    # The function that maps to the `setLevel` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    public function setLevel(int arg0) {
        java_util_zip_ZipOutputStream_setLevel(self.jObj, arg0);
    }

    # The function that maps to the `setMethod` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    public function setMethod(int arg0) {
        java_util_zip_ZipOutputStream_setMethod(self.jObj, arg0);
    }

    # The function that maps to the `wait` method of `java.util.zip.ZipOutputStream`.
    #
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function 'wait() returns javalang:InterruptedException? {
        error|() externalObj = java_util_zip_ZipOutputStream_wait(self.jObj);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait2(int arg0) returns javalang:InterruptedException? {
        error|() externalObj = java_util_zip_ZipOutputStream_wait2(self.jObj, arg0);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait3(int arg0, int arg1) returns javalang:InterruptedException? {
        error|() externalObj = java_util_zip_ZipOutputStream_wait3(self.jObj, arg0, arg1);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `byte[]` value required to map with the Java method parameter.
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function write(byte[] arg0) returns javaio:IOException?|error? {
        error|() externalObj = java_util_zip_ZipOutputStream_write(self.jObj, check jarrays:toHandle(arg0, "byte"));
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `byte[]` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + arg2 - The `int` value required to map with the Java method parameter.
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function write2(byte[] arg0, int arg1, int arg2) returns javaio:IOException?|error? {
        error|() externalObj = java_util_zip_ZipOutputStream_write2(self.jObj, check jarrays:toHandle(arg0, "byte"), arg1, arg2);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `write` method of `java.util.zip.ZipOutputStream`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `javaio:IOException` value returning from the Java mapping.
    public function write3(int arg0) returns javaio:IOException? {
        error|() externalObj = java_util_zip_ZipOutputStream_write3(self.jObj, arg0);
        if (externalObj is error) {
            javaio:IOException e = error javaio:IOException(javaio:IOEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

}

# The constructor function to generate an object of `java.util.zip.ZipOutputStream`.
#
# + arg0 - The `javaio:OutputStream` value required to map with the Java constructor parameter.
# + return - The new `ZipOutputStream` class generated.
public function newZipOutputStream1(javaio:OutputStream arg0) returns ZipOutputStream {
    handle externalObj = java_util_zip_ZipOutputStream_newZipOutputStream1(arg0.jObj);
    ZipOutputStream newObj = new (externalObj);
    return newObj;
}

# The constructor function to generate an object of `java.util.zip.ZipOutputStream`.
#
# + arg0 - The `javaio:OutputStream` value required to map with the Java constructor parameter.
# + arg1 - The `javaniocharset:Charset` value required to map with the Java constructor parameter.
# + return - The new `ZipOutputStream` class generated.
public function newZipOutputStream2(javaio:OutputStream arg0, javaniocharset:Charset arg1) returns ZipOutputStream {
    handle externalObj = java_util_zip_ZipOutputStream_newZipOutputStream2(arg0.jObj, arg1.jObj);
    ZipOutputStream newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `nullOutputStream` method of `java.util.zip.ZipOutputStream`.
#
# + return - The `javaio:OutputStream` value returning from the Java mapping.
public function ZipOutputStream_nullOutputStream() returns javaio:OutputStream {
    handle externalObj = java_util_zip_ZipOutputStream_nullOutputStream();
    javaio:OutputStream newObj = new (externalObj);
    return newObj;
}

# The function that retrieves the value of the public field `STORED`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getSTORED() returns int {
    return java_util_zip_ZipOutputStream_getSTORED();
}

# The function that retrieves the value of the public field `DEFLATED`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getDEFLATED() returns int {
    return java_util_zip_ZipOutputStream_getDEFLATED();
}

# The function that retrieves the value of the public field `LOCSIG`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCSIG() returns int {
    return java_util_zip_ZipOutputStream_getLOCSIG();
}

# The function that retrieves the value of the public field `EXTSIG`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getEXTSIG() returns int {
    return java_util_zip_ZipOutputStream_getEXTSIG();
}

# The function that retrieves the value of the public field `CENSIG`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENSIG() returns int {
    return java_util_zip_ZipOutputStream_getCENSIG();
}

# The function that retrieves the value of the public field `ENDSIG`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getENDSIG() returns int {
    return java_util_zip_ZipOutputStream_getENDSIG();
}

# The function that retrieves the value of the public field `LOCHDR`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCHDR() returns int {
    return java_util_zip_ZipOutputStream_getLOCHDR();
}

# The function that retrieves the value of the public field `EXTHDR`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getEXTHDR() returns int {
    return java_util_zip_ZipOutputStream_getEXTHDR();
}

# The function that retrieves the value of the public field `CENHDR`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENHDR() returns int {
    return java_util_zip_ZipOutputStream_getCENHDR();
}

# The function that retrieves the value of the public field `ENDHDR`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getENDHDR() returns int {
    return java_util_zip_ZipOutputStream_getENDHDR();
}

# The function that retrieves the value of the public field `LOCVER`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCVER() returns int {
    return java_util_zip_ZipOutputStream_getLOCVER();
}

# The function that retrieves the value of the public field `LOCFLG`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCFLG() returns int {
    return java_util_zip_ZipOutputStream_getLOCFLG();
}

# The function that retrieves the value of the public field `LOCHOW`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCHOW() returns int {
    return java_util_zip_ZipOutputStream_getLOCHOW();
}

# The function that retrieves the value of the public field `LOCTIM`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCTIM() returns int {
    return java_util_zip_ZipOutputStream_getLOCTIM();
}

# The function that retrieves the value of the public field `LOCCRC`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCCRC() returns int {
    return java_util_zip_ZipOutputStream_getLOCCRC();
}

# The function that retrieves the value of the public field `LOCSIZ`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCSIZ() returns int {
    return java_util_zip_ZipOutputStream_getLOCSIZ();
}

# The function that retrieves the value of the public field `LOCLEN`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCLEN() returns int {
    return java_util_zip_ZipOutputStream_getLOCLEN();
}

# The function that retrieves the value of the public field `LOCNAM`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCNAM() returns int {
    return java_util_zip_ZipOutputStream_getLOCNAM();
}

# The function that retrieves the value of the public field `LOCEXT`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getLOCEXT() returns int {
    return java_util_zip_ZipOutputStream_getLOCEXT();
}

# The function that retrieves the value of the public field `EXTCRC`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getEXTCRC() returns int {
    return java_util_zip_ZipOutputStream_getEXTCRC();
}

# The function that retrieves the value of the public field `EXTSIZ`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getEXTSIZ() returns int {
    return java_util_zip_ZipOutputStream_getEXTSIZ();
}

# The function that retrieves the value of the public field `EXTLEN`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getEXTLEN() returns int {
    return java_util_zip_ZipOutputStream_getEXTLEN();
}

# The function that retrieves the value of the public field `CENVEM`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENVEM() returns int {
    return java_util_zip_ZipOutputStream_getCENVEM();
}

# The function that retrieves the value of the public field `CENVER`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENVER() returns int {
    return java_util_zip_ZipOutputStream_getCENVER();
}

# The function that retrieves the value of the public field `CENFLG`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENFLG() returns int {
    return java_util_zip_ZipOutputStream_getCENFLG();
}

# The function that retrieves the value of the public field `CENHOW`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENHOW() returns int {
    return java_util_zip_ZipOutputStream_getCENHOW();
}

# The function that retrieves the value of the public field `CENTIM`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENTIM() returns int {
    return java_util_zip_ZipOutputStream_getCENTIM();
}

# The function that retrieves the value of the public field `CENCRC`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENCRC() returns int {
    return java_util_zip_ZipOutputStream_getCENCRC();
}

# The function that retrieves the value of the public field `CENSIZ`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENSIZ() returns int {
    return java_util_zip_ZipOutputStream_getCENSIZ();
}

# The function that retrieves the value of the public field `CENLEN`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENLEN() returns int {
    return java_util_zip_ZipOutputStream_getCENLEN();
}

# The function that retrieves the value of the public field `CENNAM`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENNAM() returns int {
    return java_util_zip_ZipOutputStream_getCENNAM();
}

# The function that retrieves the value of the public field `CENEXT`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENEXT() returns int {
    return java_util_zip_ZipOutputStream_getCENEXT();
}

# The function that retrieves the value of the public field `CENCOM`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENCOM() returns int {
    return java_util_zip_ZipOutputStream_getCENCOM();
}

# The function that retrieves the value of the public field `CENDSK`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENDSK() returns int {
    return java_util_zip_ZipOutputStream_getCENDSK();
}

# The function that retrieves the value of the public field `CENATT`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENATT() returns int {
    return java_util_zip_ZipOutputStream_getCENATT();
}

# The function that retrieves the value of the public field `CENATX`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENATX() returns int {
    return java_util_zip_ZipOutputStream_getCENATX();
}

# The function that retrieves the value of the public field `CENOFF`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getCENOFF() returns int {
    return java_util_zip_ZipOutputStream_getCENOFF();
}

# The function that retrieves the value of the public field `ENDSUB`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getENDSUB() returns int {
    return java_util_zip_ZipOutputStream_getENDSUB();
}

# The function that retrieves the value of the public field `ENDTOT`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getENDTOT() returns int {
    return java_util_zip_ZipOutputStream_getENDTOT();
}

# The function that retrieves the value of the public field `ENDSIZ`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getENDSIZ() returns int {
    return java_util_zip_ZipOutputStream_getENDSIZ();
}

# The function that retrieves the value of the public field `ENDOFF`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getENDOFF() returns int {
    return java_util_zip_ZipOutputStream_getENDOFF();
}

# The function that retrieves the value of the public field `ENDCOM`.
#
# + return - The `int` value of the field.
public function ZipOutputStream_getENDCOM() returns int {
    return java_util_zip_ZipOutputStream_getENDCOM();
}

function java_util_zip_ZipOutputStream_close(handle receiver) returns error? = @java:Method {
    name: "close",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_closeEntry(handle receiver) returns error? = @java:Method {
    name: "closeEntry",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_equals(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "equals",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["java.lang.Object"]
} external;

function java_util_zip_ZipOutputStream_finish(handle receiver) returns error? = @java:Method {
    name: "finish",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_flush(handle receiver) returns error? = @java:Method {
    name: "flush",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_getClass(handle receiver) returns handle = @java:Method {
    name: "getClass",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_hashCode(handle receiver) returns int = @java:Method {
    name: "hashCode",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_notify(handle receiver) = @java:Method {
    name: "notify",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_notifyAll(handle receiver) = @java:Method {
    name: "notifyAll",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_nullOutputStream() returns handle = @java:Method {
    name: "nullOutputStream",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_putNextEntry(handle receiver, handle arg0) returns error? = @java:Method {
    name: "putNextEntry",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["java.util.zip.ZipEntry"]
} external;

function java_util_zip_ZipOutputStream_setComment(handle receiver, handle arg0) = @java:Method {
    name: "setComment",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["java.lang.String"]
} external;

function java_util_zip_ZipOutputStream_setLevel(handle receiver, int arg0) = @java:Method {
    name: "setLevel",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["int"]
} external;

function java_util_zip_ZipOutputStream_setMethod(handle receiver, int arg0) = @java:Method {
    name: "setMethod",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["int"]
} external;

function java_util_zip_ZipOutputStream_wait(handle receiver) returns error? = @java:Method {
    name: "wait",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: []
} external;

function java_util_zip_ZipOutputStream_wait2(handle receiver, int arg0) returns error? = @java:Method {
    name: "wait",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["long"]
} external;

function java_util_zip_ZipOutputStream_wait3(handle receiver, int arg0, int arg1) returns error? = @java:Method {
    name: "wait",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["long", "int"]
} external;

function java_util_zip_ZipOutputStream_write(handle receiver, handle arg0) returns error? = @java:Method {
    name: "write",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["[B"]
} external;

function java_util_zip_ZipOutputStream_write2(handle receiver, handle arg0, int arg1, int arg2) returns error? = @java:Method {
    name: "write",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["[B", "int", "int"]
} external;

function java_util_zip_ZipOutputStream_write3(handle receiver, int arg0) returns error? = @java:Method {
    name: "write",
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["int"]
} external;

function java_util_zip_ZipOutputStream_getSTORED() returns int = @java:FieldGet {
    name: "STORED",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getDEFLATED() returns int = @java:FieldGet {
    name: "DEFLATED",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCSIG() returns int = @java:FieldGet {
    name: "LOCSIG",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getEXTSIG() returns int = @java:FieldGet {
    name: "EXTSIG",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENSIG() returns int = @java:FieldGet {
    name: "CENSIG",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getENDSIG() returns int = @java:FieldGet {
    name: "ENDSIG",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCHDR() returns int = @java:FieldGet {
    name: "LOCHDR",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getEXTHDR() returns int = @java:FieldGet {
    name: "EXTHDR",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENHDR() returns int = @java:FieldGet {
    name: "CENHDR",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getENDHDR() returns int = @java:FieldGet {
    name: "ENDHDR",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCVER() returns int = @java:FieldGet {
    name: "LOCVER",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCFLG() returns int = @java:FieldGet {
    name: "LOCFLG",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCHOW() returns int = @java:FieldGet {
    name: "LOCHOW",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCTIM() returns int = @java:FieldGet {
    name: "LOCTIM",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCCRC() returns int = @java:FieldGet {
    name: "LOCCRC",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCSIZ() returns int = @java:FieldGet {
    name: "LOCSIZ",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCLEN() returns int = @java:FieldGet {
    name: "LOCLEN",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCNAM() returns int = @java:FieldGet {
    name: "LOCNAM",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getLOCEXT() returns int = @java:FieldGet {
    name: "LOCEXT",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getEXTCRC() returns int = @java:FieldGet {
    name: "EXTCRC",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getEXTSIZ() returns int = @java:FieldGet {
    name: "EXTSIZ",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getEXTLEN() returns int = @java:FieldGet {
    name: "EXTLEN",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENVEM() returns int = @java:FieldGet {
    name: "CENVEM",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENVER() returns int = @java:FieldGet {
    name: "CENVER",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENFLG() returns int = @java:FieldGet {
    name: "CENFLG",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENHOW() returns int = @java:FieldGet {
    name: "CENHOW",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENTIM() returns int = @java:FieldGet {
    name: "CENTIM",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENCRC() returns int = @java:FieldGet {
    name: "CENCRC",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENSIZ() returns int = @java:FieldGet {
    name: "CENSIZ",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENLEN() returns int = @java:FieldGet {
    name: "CENLEN",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENNAM() returns int = @java:FieldGet {
    name: "CENNAM",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENEXT() returns int = @java:FieldGet {
    name: "CENEXT",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENCOM() returns int = @java:FieldGet {
    name: "CENCOM",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENDSK() returns int = @java:FieldGet {
    name: "CENDSK",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENATT() returns int = @java:FieldGet {
    name: "CENATT",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENATX() returns int = @java:FieldGet {
    name: "CENATX",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getCENOFF() returns int = @java:FieldGet {
    name: "CENOFF",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getENDSUB() returns int = @java:FieldGet {
    name: "ENDSUB",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getENDTOT() returns int = @java:FieldGet {
    name: "ENDTOT",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getENDSIZ() returns int = @java:FieldGet {
    name: "ENDSIZ",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getENDOFF() returns int = @java:FieldGet {
    name: "ENDOFF",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_getENDCOM() returns int = @java:FieldGet {
    name: "ENDCOM",
    'class: "java.util.zip.ZipOutputStream"
} external;

function java_util_zip_ZipOutputStream_newZipOutputStream1(handle arg0) returns handle = @java:Constructor {
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["java.io.OutputStream"]
} external;

function java_util_zip_ZipOutputStream_newZipOutputStream2(handle arg0, handle arg1) returns handle = @java:Constructor {
    'class: "java.util.zip.ZipOutputStream",
    paramTypes: ["java.io.OutputStream", "java.nio.charset.Charset"]
} external;

