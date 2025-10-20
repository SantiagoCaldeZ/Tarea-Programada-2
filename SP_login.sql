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
    DECLARE @EstaBloqueado BIT = 0;

    BEGIN TRY
        -- 🔍 1. Verificar si está bloqueado
        EXEC sp_CheckLoginBlock
            @inUsuario = @inUsuario,
            @inPostInIP = @inPostInIP,
            @estaBlock = @EstaBloqueado OUTPUT;

        IF @EstaBloqueado = 1
        BEGIN
            SET @outCodigo = 50010; -- Bloqueado por exceso de intentos
            RETURN;
        END

        -- 🔐 2. Verificar existencia del usuario
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Username = @inUsuario)
        BEGIN
            SET @outCodigo = 50001;
            SET @IdTipoEvento = 2;
            SET @IdUsuario = 7;
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Username = @inUsuario AND [Password] = @inPassword)
        BEGIN
            SET @outCodigo = 50002;
            SET @IdTipoEvento = 2;
            SET @IdUsuario = (SELECT TOP 1 Id FROM dbo.Usuario WHERE Username = @inUsuario);
        END
        ELSE
        BEGIN
            SET @outCodigo = 0;
            SET @IdTipoEvento = 1;
            SET @IdUsuario = (SELECT TOP 1 Id FROM dbo.Usuario WHERE Username = @inUsuario);
        END

        IF @IdTipoEvento IS NULL SET @IdTipoEvento = 2;
        IF @IdUsuario IS NULL SET @IdUsuario = 7;

        INSERT INTO dbo.BitacoraEvento (IdTipoEvento, IdPostByUser, PostInIP, PostTime)
        VALUES (@IdTipoEvento, @IdUsuario, @inPostInIP, GETDATE());
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50008;
        INSERT INTO dbo.DBError (UserName, Message, [DateTime])
        VALUES (SUSER_SNAME(), ERROR_MESSAGE(), GETDATE());
    END CATCH
END;
GO