CREATE OR ALTER PROCEDURE [dbo].[sp_Login]
    @inUsuario NVARCHAR(50),
    @inPassword NVARCHAR(64),
    @inPostInIP VARCHAR(50),
    @outCodigo INT OUTPUT,
    @outMinutosRestantes INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUsuario INT = NULL;
    DECLARE @IdTipoEvento INT = NULL;
    DECLARE @bloqueado BIT = 0;
    DECLARE @minRest INT = 0;

    BEGIN TRY
        -----------------------------------------------------------------
        -- 🔒 1. Verificar si el usuario está bloqueado actualmente
        -----------------------------------------------------------------
        EXEC sp_CheckLoginBlock 
            @inUsuario = @inUsuario,
            @inPostInIP = @inPostInIP,
            @estaBlock = @bloqueado OUTPUT,
            @minutosRestantes = @minRest OUTPUT;

        IF @bloqueado = 1
        BEGIN
            SET @outCodigo = 50003;               -- Usuario bloqueado
            SET @outMinutosRestantes = @minRest;  -- Minutos restantes
            RETURN;
        END

        -----------------------------------------------------------------
        -- 🔐 2. Verificar existencia y credenciales
        -----------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Username = @inUsuario)
        BEGIN
            SET @outCodigo = 50001; -- Usuario no existe
            SET @IdTipoEvento = 2;  -- Login fallido
            SET @IdUsuario = 7;     -- Usuario genérico no válido
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Username = @inUsuario AND [Password] = @inPassword)
        BEGIN
            SET @outCodigo = 50002; -- Contraseña incorrecta
            SET @IdTipoEvento = 2;
            SET @IdUsuario = (SELECT TOP 1 Id FROM dbo.Usuario WHERE Username = @inUsuario);
        END
        ELSE
        BEGIN
            SET @outCodigo = 0;     -- Éxito
            SET @IdTipoEvento = 1;  -- Login exitoso
            SET @IdUsuario = (SELECT TOP 1 Id FROM dbo.Usuario WHERE Username = @inUsuario);
        END

        -----------------------------------------------------------------
        -- 🧾 3. Registrar evento en la bitácora
        -----------------------------------------------------------------
        IF @IdTipoEvento IS NULL SET @IdTipoEvento = 2;
        IF @IdUsuario IS NULL SET @IdUsuario = 7;

        INSERT INTO dbo.BitacoraEvento (IdTipoEvento, IdPostByUser, PostInIP, PostTime)
        VALUES (@IdTipoEvento, @IdUsuario, @inPostInIP, GETDATE());
    END TRY

    BEGIN CATCH
        -----------------------------------------------------------------
        -- ⚠️ 4. Manejo de errores
        -----------------------------------------------------------------
        SET @outCodigo = 50008; -- Error en BD
        INSERT INTO dbo.DBError (UserName, Message, [DateTime])
        VALUES (SUSER_SNAME(), ERROR_MESSAGE(), GETDATE());
    END CATCH
END;
GO