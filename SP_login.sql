CREATE OR ALTER PROCEDURE [dbo].[sp_Login]
    @inUsuario NVARCHAR(50),
    @inPassword NVARCHAR(64),
    @inPostInIP VARCHAR(50),
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUsuario INT = NULL;
    DECLARE @IdTipoEvento INT = NULL;
    DECLARE @IdError INT = NULL;

    BEGIN TRY
        -- Verificar existencia del usuario
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Username = @inUsuario)
        BEGIN
            SET @outCodigo = 50001; -- Usuario no existe
            SET @IdTipoEvento = 2;  -- Login No Exitoso
            SET @IdUsuario = 7;     -- Usuario no válido (ficticio)
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Username = @inUsuario AND [Password] = @inPassword)
        BEGIN
            SET @outCodigo = 50002; -- Contraseña incorrecta
            SET @IdTipoEvento = 2;  -- Login No Exitoso
            SET @IdUsuario = (SELECT TOP 1 Id FROM dbo.Usuario WHERE Username = @inUsuario);
        END
        ELSE
        BEGIN
            SET @outCodigo = 0;     -- Éxito
            SET @IdTipoEvento = 1;  -- Login Exitoso
            SET @IdUsuario = (SELECT TOP 1 Id FROM dbo.Usuario WHERE Username = @inUsuario);
        END;

        -- Protección contra nulls en inserción
        IF @IdTipoEvento IS NULL SET @IdTipoEvento = 2;
        IF @IdUsuario IS NULL SET @IdUsuario = 7;

        INSERT INTO dbo.BitacoraEvento (IdTipoEvento, IdPostByUser, PostInIP, PostTime)
        VALUES (@IdTipoEvento, @IdUsuario, @inPostInIP, GETDATE());
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50008; -- Error en BD
        SET @IdTipoEvento = 2;  -- Login No Exitoso

        IF @IdUsuario IS NULL SET @IdUsuario = 7;

        INSERT INTO dbo.BitacoraEvento (IdTipoEvento, IdPostByUser, PostInIP, PostTime)
        VALUES (@IdTipoEvento, @IdUsuario, @inPostInIP, GETDATE());

        -- Registrar error técnico en DBError
        INSERT INTO dbo.DBError (UserName, Number, State, Severity, Line, [Procedure], Message, [DateTime])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(),
                ERROR_LINE(), ISNULL(ERROR_PROCEDURE(), 'sp_Login'), ERROR_MESSAGE(), GETDATE());
    END CATCH
END;
GO