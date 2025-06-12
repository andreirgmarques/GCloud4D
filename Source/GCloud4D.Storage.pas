unit GCloud4D.Storage;

interface

uses
  System.SysUtils, GCloud4D.Interfaces, GCloud4D.Exceptions, RESTRequest4D, System.IOUtils, System.Classes,
  System.NetEncoding, System.JSON;

type
  TGCloud4DStorage = class(TInterfacedObject, IGCloud4DStorage)
  private
    [Weak]
    FGCloud4DAuth: IGCloud4DAuth;
    FBucket: String;
    function PrepareRequest(AUpload: Boolean = False): IRequest;
  public
    constructor Create(AGCloud4DAuth: IGCloud4DAuth; ABucket: String);
    destructor Destroy; override;
    class function New(AGCloud4DAuth: IGCloud4DAuth; ABucket: String): IGCloud4DStorage;

    function CheckFileExists(AFileName: String): Boolean;
    function DeleteFile(AFileName: String): IGCloud4DStorage;
    function DownloadFile(AFullPath, AFileName: String): IGCloud4DStorage;
    function ListFiles: TJSONArray;
    function MoveFile(AOrigin, ADestination: String): IGCloud4DStorage;
    function UploadFile(AFullPath, AFileName: String): IGCloud4DStorage;
  end;

implementation

{ TGCloud4DStorage }

function TGCloud4DStorage.CheckFileExists(AFileName: String): Boolean;
begin
  Result := Self.PrepareRequest.Resource(TNetEncoding.URL.Encode(AFileName)).Get.StatusCode = 200;
end;

constructor TGCloud4DStorage.Create(AGCloud4DAuth: IGCloud4DAuth; ABucket: String);
begin
  FGCloud4DAuth := AGCloud4DAuth;
  FBucket := ABucket;
end;

function TGCloud4DStorage.DeleteFile(AFileName: String): IGCloud4DStorage;
begin
  Result := Self;
  var LResponse := Self.PrepareRequest
                       .Resource(TNetEncoding.URL.Encode(AFileName))
                       .Delete;

  if LResponse.StatusCode <> 204 then
    raise EGCloud4DException.CreateFmt('Failed to delete file from the bucket!%s%s', [sLineBreak, LResponse.Content]);
end;

destructor TGCloud4DStorage.Destroy;
begin
  inherited;
end;

function TGCloud4DStorage.DownloadFile(AFullPath, AFileName: String): IGCloud4DStorage;
begin
  Result := Self;
  var LResponse := Self.PrepareRequest
                       .Resource(TNetEncoding.URL.Encode(AFileName))
                       .AddParam('alt', 'media')
                       .Get;

  if (LResponse.StatusCode = 404) or (Length(LResponse.RawBytes) = 0) then
    raise EGCloud4DException.Create('File not found in the bucket.');
  if LResponse.StatusCode <> 200 then
    raise EGCloud4DException.CreateFmt('Failed to download file from the bucket!%s%s', [sLineBreak, LResponse.Content]);

  if not TDirectory.Exists(TPath.GetDirectoryName(AFullPath)) then
    TDirectory.CreateDirectory(TPath.GetDirectoryName(AFullPath));
  if TFile.Exists(AFullPath) then
    TFile.Delete(AFullPath);

  var LFile := TFileStream.Create(AFullPath, fmCreate);
  try
    LFile.WriteBuffer(LResponse.RawBytes[0], Length(LResponse.RawBytes));
  finally
    LFile.Free;
  end;
end;

function TGCloud4DStorage.ListFiles: TJSONArray;
begin
  var LResponse := Self.PrepareRequest.Get;

  if LResponse.StatusCode <> 200 then
    raise EGCloud4DException.CreateFmt('Failed to list files in the bucket!%s%s', [sLineBreak, LResponse.Content]);

  Result := TJSONValue.ParseJSONValue(LResponse.JSONValue.GetValue<TJSONArray>('items').ToString) as TJSONArray;
end;

function TGCloud4DStorage.MoveFile(AOrigin, ADestination: String): IGCloud4DStorage;
begin
  Result := Self;
  var LResponse := Self.PrepareRequest
                       .Resource(Format('%s/moveTo/o/%s', [
                         TNetEncoding.URL.Encode(AOrigin),
                         TNetEncoding.URL.Encode(ADestination)
                       ]))
                       .Post;

  if LResponse.StatusCode <> 200 then
    raise EGCloud4DException.CreateFmt('Failed to move file in the bucket!%s%s', [sLineBreak, LResponse.Content]);
end;

class function TGCloud4DStorage.New(AGCloud4DAuth: IGCloud4DAuth; ABucket: String): IGCloud4DStorage;
begin
  Result := Self.Create(AGCloud4DAuth, ABucket);
end;

function TGCloud4DStorage.PrepareRequest(AUpload: Boolean): IRequest;
begin
  var LBaseURL := Format('https://storage.googleapis.com/storage/v1/b/%s/o', [FBucket]);
  if AUpload then
    LBaseURL := Format('https://storage.googleapis.com/upload/storage/v1/b/%s/o', [FBucket]);
  Result := TRequest.New
              .BaseURL(LBaseURL)
              .TokenBearer(FGCloud4DAuth.AccessToken('https://www.googleapis.com/auth/devstorage.read_write'));
end;

function TGCloud4DStorage.UploadFile(AFullPath, AFileName: String): IGCloud4DStorage;
begin
  Result := Self;
  var LResponse := Self.PrepareRequest(True)
                       .AddParam('uploadType', 'media')
                       .AddParam('name', AFileName)
                       .AddHeader('Content-Type', 'application/octet-stream')
                       .AddBody(TFileStream.Create(AFullPath, fmOpenRead or fmShareDenyWrite))
                       .Post;

  if LResponse.StatusCode <> 200 then
    raise EGCloud4DException.CreateFmt('Failed to upload file to the bucket!%s%s', [sLineBreak, LResponse.Content]);
end;

end.

