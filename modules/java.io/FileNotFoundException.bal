// Ballerina error type for `java.io.FileNotFoundException`.

public const FILENOTFOUNDEXCEPTION = "FileNotFoundException";

type FileNotFoundExceptionData record {
    string message;
};

public type FileNotFoundException distinct error<FileNotFoundExceptionData>;

