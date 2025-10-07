CREATE OR ALTER PROCEDURE sp_RegistrarEvento
  @IdTipoEvento INT,
  @Descripcion NVARCHAR(256),
  @IdPostByUser INT,
  @PostInIP VARCHAR(32)
AS
BEGIN
  INSERT INTO BitacoraEvento (Id, IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
  VALUES (
    (SELECT ISNULL(MAX(Id), 0) + 1 FROM BitacoraEvento),
    @IdTipoEvento,
    @Descripcion,
    @IdPostByUser,
    @PostInIP,
    GETDATE()
  );
END
GO