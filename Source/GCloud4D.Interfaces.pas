unit GCloud4D.Interfaces;

interface

uses
  System.SysUtils, System.JSON;

type
  IGCloud4DAuth = interface
    ['{71CEA100-EFD4-48AE-9E8B-042AAF234F0D}']
    function AccessToken(AScope: String): String;
    function CurrentDateTime(AValue: TDateTime): IGCloud4DAuth;
  end;

  IGCloud4DStorage = interface
    ['{A57D730C-3D3B-4A67-BA05-632F100786CC}']
    function CheckFileExists(AFileName: String): Boolean;
    function DeleteFile(AFileName: String): IGCloud4DStorage;
    function DownloadFile(ADirectory, AFileName: String): IGCloud4DStorage;
    function ListFiles: TJSONArray;
    function MoveFile(AOrigin, ADestination: String): IGCloud4DStorage;
    function UploadFile(AFullPath, AFileName: String): IGCloud4DStorage;
  end;

implementation

end.
