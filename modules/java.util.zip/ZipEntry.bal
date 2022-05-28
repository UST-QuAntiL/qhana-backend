import ballerina/jballerina.java;
import ballerina/jballerina.java.arrays as jarrays;
import qhana_backend.java.lang as javalang;
import qhana_backend.java.time as javatime;
import qhana_backend.java.nio.file.attribute as javaniofileattribute;

# Ballerina class mapping for the Java `java.util.zip.ZipEntry` class.
@java:Binding {'class: "java.util.zip.ZipEntry"}
public distinct class ZipEntry {

    *java:JObject;
    *javalang:Object;

    # The `handle` field that stores the reference to the `java.util.zip.ZipEntry` object.
    public handle jObj;

    # The init function of the Ballerina class mapping the `java.util.zip.ZipEntry` Java class.
    #
    # + obj - The `handle` value containing the Java reference of the object.
    public function init(handle obj) {
        self.jObj = obj;
    }

    # The function to retrieve the string representation of the Ballerina class mapping the `java.util.zip.ZipEntry` Java class.
    #
    # + return - The `string` form of the Java object instance.
    public function toString() returns string {
        return java:toString(self.jObj) ?: "null";
    }
    # The function that maps to the `clone` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `javalang:Object` value returning from the Java mapping.
    public function clone() returns javalang:Object {
        handle externalObj = java_util_zip_ZipEntry_clone(self.jObj);
        javalang:Object newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `equals` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `javalang:Object` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function 'equals(javalang:Object arg0) returns boolean {
        return java_util_zip_ZipEntry_equals(self.jObj, arg0.jObj);
    }

    # The function that maps to the `getClass` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `javalang:Class` value returning from the Java mapping.
    public function getClass() returns javalang:Class {
        handle externalObj = java_util_zip_ZipEntry_getClass(self.jObj);
        javalang:Class newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getComment` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `string` value returning from the Java mapping.
    public function getComment() returns string? {
        return java:toString(java_util_zip_ZipEntry_getComment(self.jObj));
    }

    # The function that maps to the `getCompressedSize` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getCompressedSize() returns int {
        return java_util_zip_ZipEntry_getCompressedSize(self.jObj);
    }

    # The function that maps to the `getCrc` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getCrc() returns int {
        return java_util_zip_ZipEntry_getCrc(self.jObj);
    }

    # The function that maps to the `getCreationTime` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `javaniofileattribute:FileTime` value returning from the Java mapping.
    public function getCreationTime() returns javaniofileattribute:FileTime {
        handle externalObj = java_util_zip_ZipEntry_getCreationTime(self.jObj);
        javaniofileattribute:FileTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getExtra` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `byte[]` value returning from the Java mapping.
    public function getExtra() returns byte[]|error {
        handle externalObj = java_util_zip_ZipEntry_getExtra(self.jObj);
        return <byte[]>check jarrays:fromHandle(externalObj, "byte");
    }

    # The function that maps to the `getLastAccessTime` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `javaniofileattribute:FileTime` value returning from the Java mapping.
    public function getLastAccessTime() returns javaniofileattribute:FileTime {
        handle externalObj = java_util_zip_ZipEntry_getLastAccessTime(self.jObj);
        javaniofileattribute:FileTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getLastModifiedTime` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `javaniofileattribute:FileTime` value returning from the Java mapping.
    public function getLastModifiedTime() returns javaniofileattribute:FileTime {
        handle externalObj = java_util_zip_ZipEntry_getLastModifiedTime(self.jObj);
        javaniofileattribute:FileTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getMethod` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getMethod() returns int {
        return java_util_zip_ZipEntry_getMethod(self.jObj);
    }

    # The function that maps to the `getName` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `string` value returning from the Java mapping.
    public function getName() returns string? {
        return java:toString(java_util_zip_ZipEntry_getName(self.jObj));
    }

    # The function that maps to the `getSize` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getSize() returns int {
        return java_util_zip_ZipEntry_getSize(self.jObj);
    }

    # The function that maps to the `getTime` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getTime() returns int {
        return java_util_zip_ZipEntry_getTime(self.jObj);
    }

    # The function that maps to the `getTimeLocal` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `javatime:LocalDateTime` value returning from the Java mapping.
    public function getTimeLocal() returns javatime:LocalDateTime {
        handle externalObj = java_util_zip_ZipEntry_getTimeLocal(self.jObj);
        javatime:LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `hashCode` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function hashCode() returns int {
        return java_util_zip_ZipEntry_hashCode(self.jObj);
    }

    # The function that maps to the `isDirectory` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `boolean` value returning from the Java mapping.
    public function isDirectory() returns boolean {
        return java_util_zip_ZipEntry_isDirectory(self.jObj);
    }

    # The function that maps to the `notify` method of `java.util.zip.ZipEntry`.
    public function notify() {
        java_util_zip_ZipEntry_notify(self.jObj);
    }

    # The function that maps to the `notifyAll` method of `java.util.zip.ZipEntry`.
    public function notifyAll() {
        java_util_zip_ZipEntry_notifyAll(self.jObj);
    }

    # The function that maps to the `setComment` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `string` value required to map with the Java method parameter.
    public function setComment(string arg0) {
        java_util_zip_ZipEntry_setComment(self.jObj, java:fromString(arg0));
    }

    # The function that maps to the `setCompressedSize` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    public function setCompressedSize(int arg0) {
        java_util_zip_ZipEntry_setCompressedSize(self.jObj, arg0);
    }

    # The function that maps to the `setCrc` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    public function setCrc(int arg0) {
        java_util_zip_ZipEntry_setCrc(self.jObj, arg0);
    }

    # The function that maps to the `setCreationTime` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `javaniofileattribute:FileTime` value required to map with the Java method parameter.
    # + return - The `ZipEntry` value returning from the Java mapping.
    public function setCreationTime(javaniofileattribute:FileTime arg0) returns ZipEntry {
        handle externalObj = java_util_zip_ZipEntry_setCreationTime(self.jObj, arg0.jObj);
        ZipEntry newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `setExtra` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `byte[]` value required to map with the Java method parameter.
    # + return - The `error?` value returning from the Java mapping.
    public function setExtra(byte[] arg0) returns error? {
        java_util_zip_ZipEntry_setExtra(self.jObj, check jarrays:toHandle(arg0, "byte"));
    }

    # The function that maps to the `setLastAccessTime` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `javaniofileattribute:FileTime` value required to map with the Java method parameter.
    # + return - The `ZipEntry` value returning from the Java mapping.
    public function setLastAccessTime(javaniofileattribute:FileTime arg0) returns ZipEntry {
        handle externalObj = java_util_zip_ZipEntry_setLastAccessTime(self.jObj, arg0.jObj);
        ZipEntry newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `setLastModifiedTime` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `javaniofileattribute:FileTime` value required to map with the Java method parameter.
    # + return - The `ZipEntry` value returning from the Java mapping.
    public function setLastModifiedTime(javaniofileattribute:FileTime arg0) returns ZipEntry {
        handle externalObj = java_util_zip_ZipEntry_setLastModifiedTime(self.jObj, arg0.jObj);
        ZipEntry newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `setMethod` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    public function setMethod(int arg0) {
        java_util_zip_ZipEntry_setMethod(self.jObj, arg0);
    }

    # The function that maps to the `setSize` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    public function setSize(int arg0) {
        java_util_zip_ZipEntry_setSize(self.jObj, arg0);
    }

    # The function that maps to the `setTime` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    public function setTime(int arg0) {
        java_util_zip_ZipEntry_setTime(self.jObj, arg0);
    }

    # The function that maps to the `setTimeLocal` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `javatime:LocalDateTime` value required to map with the Java method parameter.
    public function setTimeLocal(javatime:LocalDateTime arg0) {
        java_util_zip_ZipEntry_setTimeLocal(self.jObj, arg0.jObj);
    }

    # The function that maps to the `wait` method of `java.util.zip.ZipEntry`.
    #
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function 'wait() returns javalang:InterruptedException? {
        error|() externalObj = java_util_zip_ZipEntry_wait(self.jObj);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait2(int arg0) returns javalang:InterruptedException? {
        error|() externalObj = java_util_zip_ZipEntry_wait2(self.jObj, arg0);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.util.zip.ZipEntry`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait3(int arg0, int arg1) returns javalang:InterruptedException? {
        error|() externalObj = java_util_zip_ZipEntry_wait3(self.jObj, arg0, arg1);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

}

# The constructor function to generate an object of `java.util.zip.ZipEntry`.
#
# + arg0 - The `string` value required to map with the Java constructor parameter.
# + return - The new `ZipEntry` class generated.
public function newZipEntry1(string arg0) returns ZipEntry {
    handle externalObj = java_util_zip_ZipEntry_newZipEntry1(java:fromString(arg0));
    ZipEntry newObj = new (externalObj);
    return newObj;
}

# The constructor function to generate an object of `java.util.zip.ZipEntry`.
#
# + arg0 - The `ZipEntry` value required to map with the Java constructor parameter.
# + return - The new `ZipEntry` class generated.
public function newZipEntry2(ZipEntry arg0) returns ZipEntry {
    handle externalObj = java_util_zip_ZipEntry_newZipEntry2(arg0.jObj);
    ZipEntry newObj = new (externalObj);
    return newObj;
}

# The function that retrieves the value of the public field `STORED`.
#
# + return - The `int` value of the field.
public function ZipEntry_getSTORED() returns int {
    return java_util_zip_ZipEntry_getSTORED();
}

# The function that retrieves the value of the public field `DEFLATED`.
#
# + return - The `int` value of the field.
public function ZipEntry_getDEFLATED() returns int {
    return java_util_zip_ZipEntry_getDEFLATED();
}

# The function that retrieves the value of the public field `LOCSIG`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCSIG() returns int {
    return java_util_zip_ZipEntry_getLOCSIG();
}

# The function that retrieves the value of the public field `EXTSIG`.
#
# + return - The `int` value of the field.
public function ZipEntry_getEXTSIG() returns int {
    return java_util_zip_ZipEntry_getEXTSIG();
}

# The function that retrieves the value of the public field `CENSIG`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENSIG() returns int {
    return java_util_zip_ZipEntry_getCENSIG();
}

# The function that retrieves the value of the public field `ENDSIG`.
#
# + return - The `int` value of the field.
public function ZipEntry_getENDSIG() returns int {
    return java_util_zip_ZipEntry_getENDSIG();
}

# The function that retrieves the value of the public field `LOCHDR`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCHDR() returns int {
    return java_util_zip_ZipEntry_getLOCHDR();
}

# The function that retrieves the value of the public field `EXTHDR`.
#
# + return - The `int` value of the field.
public function ZipEntry_getEXTHDR() returns int {
    return java_util_zip_ZipEntry_getEXTHDR();
}

# The function that retrieves the value of the public field `CENHDR`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENHDR() returns int {
    return java_util_zip_ZipEntry_getCENHDR();
}

# The function that retrieves the value of the public field `ENDHDR`.
#
# + return - The `int` value of the field.
public function ZipEntry_getENDHDR() returns int {
    return java_util_zip_ZipEntry_getENDHDR();
}

# The function that retrieves the value of the public field `LOCVER`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCVER() returns int {
    return java_util_zip_ZipEntry_getLOCVER();
}

# The function that retrieves the value of the public field `LOCFLG`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCFLG() returns int {
    return java_util_zip_ZipEntry_getLOCFLG();
}

# The function that retrieves the value of the public field `LOCHOW`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCHOW() returns int {
    return java_util_zip_ZipEntry_getLOCHOW();
}

# The function that retrieves the value of the public field `LOCTIM`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCTIM() returns int {
    return java_util_zip_ZipEntry_getLOCTIM();
}

# The function that retrieves the value of the public field `LOCCRC`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCCRC() returns int {
    return java_util_zip_ZipEntry_getLOCCRC();
}

# The function that retrieves the value of the public field `LOCSIZ`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCSIZ() returns int {
    return java_util_zip_ZipEntry_getLOCSIZ();
}

# The function that retrieves the value of the public field `LOCLEN`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCLEN() returns int {
    return java_util_zip_ZipEntry_getLOCLEN();
}

# The function that retrieves the value of the public field `LOCNAM`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCNAM() returns int {
    return java_util_zip_ZipEntry_getLOCNAM();
}

# The function that retrieves the value of the public field `LOCEXT`.
#
# + return - The `int` value of the field.
public function ZipEntry_getLOCEXT() returns int {
    return java_util_zip_ZipEntry_getLOCEXT();
}

# The function that retrieves the value of the public field `EXTCRC`.
#
# + return - The `int` value of the field.
public function ZipEntry_getEXTCRC() returns int {
    return java_util_zip_ZipEntry_getEXTCRC();
}

# The function that retrieves the value of the public field `EXTSIZ`.
#
# + return - The `int` value of the field.
public function ZipEntry_getEXTSIZ() returns int {
    return java_util_zip_ZipEntry_getEXTSIZ();
}

# The function that retrieves the value of the public field `EXTLEN`.
#
# + return - The `int` value of the field.
public function ZipEntry_getEXTLEN() returns int {
    return java_util_zip_ZipEntry_getEXTLEN();
}

# The function that retrieves the value of the public field `CENVEM`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENVEM() returns int {
    return java_util_zip_ZipEntry_getCENVEM();
}

# The function that retrieves the value of the public field `CENVER`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENVER() returns int {
    return java_util_zip_ZipEntry_getCENVER();
}

# The function that retrieves the value of the public field `CENFLG`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENFLG() returns int {
    return java_util_zip_ZipEntry_getCENFLG();
}

# The function that retrieves the value of the public field `CENHOW`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENHOW() returns int {
    return java_util_zip_ZipEntry_getCENHOW();
}

# The function that retrieves the value of the public field `CENTIM`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENTIM() returns int {
    return java_util_zip_ZipEntry_getCENTIM();
}

# The function that retrieves the value of the public field `CENCRC`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENCRC() returns int {
    return java_util_zip_ZipEntry_getCENCRC();
}

# The function that retrieves the value of the public field `CENSIZ`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENSIZ() returns int {
    return java_util_zip_ZipEntry_getCENSIZ();
}

# The function that retrieves the value of the public field `CENLEN`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENLEN() returns int {
    return java_util_zip_ZipEntry_getCENLEN();
}

# The function that retrieves the value of the public field `CENNAM`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENNAM() returns int {
    return java_util_zip_ZipEntry_getCENNAM();
}

# The function that retrieves the value of the public field `CENEXT`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENEXT() returns int {
    return java_util_zip_ZipEntry_getCENEXT();
}

# The function that retrieves the value of the public field `CENCOM`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENCOM() returns int {
    return java_util_zip_ZipEntry_getCENCOM();
}

# The function that retrieves the value of the public field `CENDSK`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENDSK() returns int {
    return java_util_zip_ZipEntry_getCENDSK();
}

# The function that retrieves the value of the public field `CENATT`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENATT() returns int {
    return java_util_zip_ZipEntry_getCENATT();
}

# The function that retrieves the value of the public field `CENATX`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENATX() returns int {
    return java_util_zip_ZipEntry_getCENATX();
}

# The function that retrieves the value of the public field `CENOFF`.
#
# + return - The `int` value of the field.
public function ZipEntry_getCENOFF() returns int {
    return java_util_zip_ZipEntry_getCENOFF();
}

# The function that retrieves the value of the public field `ENDSUB`.
#
# + return - The `int` value of the field.
public function ZipEntry_getENDSUB() returns int {
    return java_util_zip_ZipEntry_getENDSUB();
}

# The function that retrieves the value of the public field `ENDTOT`.
#
# + return - The `int` value of the field.
public function ZipEntry_getENDTOT() returns int {
    return java_util_zip_ZipEntry_getENDTOT();
}

# The function that retrieves the value of the public field `ENDSIZ`.
#
# + return - The `int` value of the field.
public function ZipEntry_getENDSIZ() returns int {
    return java_util_zip_ZipEntry_getENDSIZ();
}

# The function that retrieves the value of the public field `ENDOFF`.
#
# + return - The `int` value of the field.
public function ZipEntry_getENDOFF() returns int {
    return java_util_zip_ZipEntry_getENDOFF();
}

# The function that retrieves the value of the public field `ENDCOM`.
#
# + return - The `int` value of the field.
public function ZipEntry_getENDCOM() returns int {
    return java_util_zip_ZipEntry_getENDCOM();
}

function java_util_zip_ZipEntry_clone(handle receiver) returns handle = @java:Method {
    name: "clone",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_equals(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "equals",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["java.lang.Object"]
} external;

function java_util_zip_ZipEntry_getClass(handle receiver) returns handle = @java:Method {
    name: "getClass",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getComment(handle receiver) returns handle = @java:Method {
    name: "getComment",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getCompressedSize(handle receiver) returns int = @java:Method {
    name: "getCompressedSize",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getCrc(handle receiver) returns int = @java:Method {
    name: "getCrc",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getCreationTime(handle receiver) returns handle = @java:Method {
    name: "getCreationTime",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getExtra(handle receiver) returns handle = @java:Method {
    name: "getExtra",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getLastAccessTime(handle receiver) returns handle = @java:Method {
    name: "getLastAccessTime",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getLastModifiedTime(handle receiver) returns handle = @java:Method {
    name: "getLastModifiedTime",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getMethod(handle receiver) returns int = @java:Method {
    name: "getMethod",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getName(handle receiver) returns handle = @java:Method {
    name: "getName",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getSize(handle receiver) returns int = @java:Method {
    name: "getSize",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getTime(handle receiver) returns int = @java:Method {
    name: "getTime",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_getTimeLocal(handle receiver) returns handle = @java:Method {
    name: "getTimeLocal",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_hashCode(handle receiver) returns int = @java:Method {
    name: "hashCode",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_isDirectory(handle receiver) returns boolean = @java:Method {
    name: "isDirectory",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_notify(handle receiver) = @java:Method {
    name: "notify",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_notifyAll(handle receiver) = @java:Method {
    name: "notifyAll",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_setComment(handle receiver, handle arg0) = @java:Method {
    name: "setComment",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["java.lang.String"]
} external;

function java_util_zip_ZipEntry_setCompressedSize(handle receiver, int arg0) = @java:Method {
    name: "setCompressedSize",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["long"]
} external;

function java_util_zip_ZipEntry_setCrc(handle receiver, int arg0) = @java:Method {
    name: "setCrc",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["long"]
} external;

function java_util_zip_ZipEntry_setCreationTime(handle receiver, handle arg0) returns handle = @java:Method {
    name: "setCreationTime",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["java.nio.file.attribute.FileTime"]
} external;

function java_util_zip_ZipEntry_setExtra(handle receiver, handle arg0) = @java:Method {
    name: "setExtra",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["[B"]
} external;

function java_util_zip_ZipEntry_setLastAccessTime(handle receiver, handle arg0) returns handle = @java:Method {
    name: "setLastAccessTime",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["java.nio.file.attribute.FileTime"]
} external;

function java_util_zip_ZipEntry_setLastModifiedTime(handle receiver, handle arg0) returns handle = @java:Method {
    name: "setLastModifiedTime",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["java.nio.file.attribute.FileTime"]
} external;

function java_util_zip_ZipEntry_setMethod(handle receiver, int arg0) = @java:Method {
    name: "setMethod",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["int"]
} external;

function java_util_zip_ZipEntry_setSize(handle receiver, int arg0) = @java:Method {
    name: "setSize",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["long"]
} external;

function java_util_zip_ZipEntry_setTime(handle receiver, int arg0) = @java:Method {
    name: "setTime",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["long"]
} external;

function java_util_zip_ZipEntry_setTimeLocal(handle receiver, handle arg0) = @java:Method {
    name: "setTimeLocal",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["java.time.LocalDateTime"]
} external;

function java_util_zip_ZipEntry_wait(handle receiver) returns error? = @java:Method {
    name: "wait",
    'class: "java.util.zip.ZipEntry",
    paramTypes: []
} external;

function java_util_zip_ZipEntry_wait2(handle receiver, int arg0) returns error? = @java:Method {
    name: "wait",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["long"]
} external;

function java_util_zip_ZipEntry_wait3(handle receiver, int arg0, int arg1) returns error? = @java:Method {
    name: "wait",
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["long", "int"]
} external;

function java_util_zip_ZipEntry_getSTORED() returns int = @java:FieldGet {
    name: "STORED",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getDEFLATED() returns int = @java:FieldGet {
    name: "DEFLATED",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCSIG() returns int = @java:FieldGet {
    name: "LOCSIG",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getEXTSIG() returns int = @java:FieldGet {
    name: "EXTSIG",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENSIG() returns int = @java:FieldGet {
    name: "CENSIG",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getENDSIG() returns int = @java:FieldGet {
    name: "ENDSIG",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCHDR() returns int = @java:FieldGet {
    name: "LOCHDR",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getEXTHDR() returns int = @java:FieldGet {
    name: "EXTHDR",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENHDR() returns int = @java:FieldGet {
    name: "CENHDR",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getENDHDR() returns int = @java:FieldGet {
    name: "ENDHDR",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCVER() returns int = @java:FieldGet {
    name: "LOCVER",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCFLG() returns int = @java:FieldGet {
    name: "LOCFLG",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCHOW() returns int = @java:FieldGet {
    name: "LOCHOW",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCTIM() returns int = @java:FieldGet {
    name: "LOCTIM",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCCRC() returns int = @java:FieldGet {
    name: "LOCCRC",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCSIZ() returns int = @java:FieldGet {
    name: "LOCSIZ",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCLEN() returns int = @java:FieldGet {
    name: "LOCLEN",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCNAM() returns int = @java:FieldGet {
    name: "LOCNAM",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getLOCEXT() returns int = @java:FieldGet {
    name: "LOCEXT",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getEXTCRC() returns int = @java:FieldGet {
    name: "EXTCRC",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getEXTSIZ() returns int = @java:FieldGet {
    name: "EXTSIZ",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getEXTLEN() returns int = @java:FieldGet {
    name: "EXTLEN",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENVEM() returns int = @java:FieldGet {
    name: "CENVEM",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENVER() returns int = @java:FieldGet {
    name: "CENVER",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENFLG() returns int = @java:FieldGet {
    name: "CENFLG",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENHOW() returns int = @java:FieldGet {
    name: "CENHOW",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENTIM() returns int = @java:FieldGet {
    name: "CENTIM",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENCRC() returns int = @java:FieldGet {
    name: "CENCRC",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENSIZ() returns int = @java:FieldGet {
    name: "CENSIZ",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENLEN() returns int = @java:FieldGet {
    name: "CENLEN",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENNAM() returns int = @java:FieldGet {
    name: "CENNAM",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENEXT() returns int = @java:FieldGet {
    name: "CENEXT",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENCOM() returns int = @java:FieldGet {
    name: "CENCOM",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENDSK() returns int = @java:FieldGet {
    name: "CENDSK",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENATT() returns int = @java:FieldGet {
    name: "CENATT",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENATX() returns int = @java:FieldGet {
    name: "CENATX",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getCENOFF() returns int = @java:FieldGet {
    name: "CENOFF",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getENDSUB() returns int = @java:FieldGet {
    name: "ENDSUB",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getENDTOT() returns int = @java:FieldGet {
    name: "ENDTOT",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getENDSIZ() returns int = @java:FieldGet {
    name: "ENDSIZ",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getENDOFF() returns int = @java:FieldGet {
    name: "ENDOFF",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_getENDCOM() returns int = @java:FieldGet {
    name: "ENDCOM",
    'class: "java.util.zip.ZipEntry"
} external;

function java_util_zip_ZipEntry_newZipEntry1(handle arg0) returns handle = @java:Constructor {
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["java.lang.String"]
} external;

function java_util_zip_ZipEntry_newZipEntry2(handle arg0) returns handle = @java:Constructor {
    'class: "java.util.zip.ZipEntry",
    paramTypes: ["java.util.zip.ZipEntry"]
} external;

