unit GCloud4D;

interface

uses
  GCloud4D.Auth, GCloud4D.Exceptions, GCloud4D.Interfaces, GCloud4D.Storage;

type
  // Exceptions
  EGCloud4DException = GCloud4D.Exceptions.EGCloud4DException;

  // Interfaces
  IGCloud4DAuth = GCloud4D.Interfaces.IGCloud4DAuth;
  IGCloud4DStorage = GCloud4D.Interfaces.IGCloud4DStorage;

  // Classes
  TGCloud4DAuth = GCloud4D.Auth.TGCloud4DAuth;
  TGCloud4DStorage = GCloud4D.Storage.TGCloud4DStorage;



implementation

end.
