CREATE OR ALTER PROCEDURE sp_RegistrarEvento
  @IdTipoEvento INT,
  @Descripcion NVARCHAR(256),
  @IdPostByUser INT,
  @PostInIP VARCHAR(32)
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
  VALUES (
    @IdTipoEvento,
    @Descripcion,
    @IdPostByUser,
    @PostInIP,
    GETDATE()
  );
END;
GO
