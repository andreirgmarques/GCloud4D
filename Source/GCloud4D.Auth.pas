unit GCloud4D.Auth;

interface

uses
  System.SysUtils, GCloud4D.Interfaces, GCloud4D.Exceptions, System.Classes, System.JSON, System.Types, System.DateUtils,
  System.NetEncoding, RESTRequest4D, REST.Types, JOSE.Core.JWK, JOSE.Core.JWS, JOSE.Core.JWT, JOSE.Core.JWA;

type
  TGCloud4DAuth = class(TInterfacedObject, IGCloud4DAuth)
  private
    FAccessToken: String;
    FClientEmail: String;
    FCurrentDateTime: TDateTime;
    FPrivateKey: String;
    FTokenExpirationDateTime: Int64;
    procedure ReadResourceConfig(AValue: String);
    function CreateJWTToken(AScope: String): String;
  public
    constructor Create(AResourceConfig: String);
    destructor Destroy; override;
    class function New(AResourceConfig: String): IGCloud4DAuth;

    function AccessToken(AScope: String): String;
    function CurrentDateTime(AValue: TDateTime): IGCloud4DAuth;
  end;

implementation

{ TGCloud4DAuth }

function TGCloud4DAuth.AccessToken(AScope: String): String;
begin
  if UnixToDateTime(FTokenExpirationDateTime, False) >= FCurrentDateTime then
    Exit(FAccessToken);

  // Make the request to authenticate and obtain the access token
  var LResponse := TRequest.New
                     .BaseURL('https://oauth2.googleapis.com/token')
                     .AddParam('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer', TRESTRequestParameterKind.pkGETorPOST)
                     .AddParam('assertion', Self.CreateJWTToken(AScope), TRESTRequestParameterKind.pkGETorPOST)
                     .Post;
  if LResponse.StatusCode <> 200 then
    raise EGCloud4DException.CreateFmt('Authentication with GCloud API failed!%s%s', [sLineBreak, LResponse.Content]);

  FAccessToken := LResponse.JSONValue.GetValue<string>('access_token');
  Result := FAccessToken;
end;

constructor TGCloud4DAuth.Create(AResourceConfig: String);
begin
  FCurrentDateTime := Now;
  Self.ReadResourceConfig(AResourceConfig);
end;

function TGCloud4DAuth.CreateJWTToken(AScope: String): String;
const
  TOKEN_URL = 'https://oauth2.googleapis.com/token';
begin
  // Create the JWT
  var LJWT := TJWT.Create;
  try
    LJWT.Claims.Audience   := TOKEN_URL;
    LJWT.Claims.Issuer     := FClientEmail;
    LJWT.Claims.IssuedAt   := FCurrentDateTime;
    LJWT.Claims.Expiration := IncMinute(LJWT.Claims.IssuedAt, 60); // Token expiration time set to 1 hour
    LJWT.Claims.SetClaimOfType<String>('scope', AScope);

    // Sign the JWT
    var LJWK := TJWK.Create(FPrivateKey);
    var LJWS := TJWS.Create(LJWT);
    try
      LJWS.Sign(LJWK, TJOSEAlgorithmId.RS256);
      Result := LJWS.CompactToken;
    finally
      LJWK.Free;
      LJWS.Free;
    end;
  finally
    LJWT.Free;
  end;
end;

function TGCloud4DAuth.CurrentDateTime(AValue: TDateTime): IGCloud4DAuth;
begin
  FCurrentDateTime := AValue;
end;

destructor TGCloud4DAuth.Destroy;
begin
  inherited;
end;

class function TGCloud4DAuth.New(AResourceConfig: String): IGCloud4DAuth;
begin
  Result := Self.Create(AResourceConfig);
end;

procedure TGCloud4DAuth.ReadResourceConfig(AValue: String);
begin
  var LStringStream   := TStringStream.Create;
  var LResourceStream := TResourceStream.Create(HInstance, AValue, RT_RCDATA);
  try
    LResourceStream.SaveToStream(LStringStream);
    var LJSONCredentials := TJSONValue.ParseJSONValue(LStringStream.DataString);
    try
      FClientEmail := LJSONCredentials.GetValue<String>('client_email');
      FPrivateKey  := LJSONCredentials.GetValue<String>('private_key');
    finally
      LJSONCredentials.Free;
    end;
  finally
    LResourceStream.Free;
    LStringStream.Free;
  end;
end;

end.
