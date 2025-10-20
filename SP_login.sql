CREATE OR ALTER PROCEDURE [dbo].[sp_Login]
    @inUsuario NVARCHAR(50),
    @inPassword NVARCHAR(64),
    @inPostInIP VARCHAR(50),
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Variables para la Bitácora
    DECLARE @IdUsuario INT;
    DECLARE @IdTipoEvento INT;
    DECLARE @IdError INT;

    BEGIN TRY

        -- Verificar existencia
        IF NOT EXISTS (SELECT 1
    FROM dbo.Usuario
    WHERE Username = @inUsuario)
        BEGIN
        SET @outCodigo = 50001;
        -- Usuario no existe
        SET @IdTipoEvento = 2;
        --Usuario no existe
        SET @IdError = (SELECT Id
        FROM dbo.Error
        WHERE Codigo = '50001')
        SET @IdUsuario = 7;
    --Usuario No valido            
    END

        -- Validar credenciales
        ELSE IF NOT EXISTS (SELECT 1
    FROM dbo.Usuario
    WHERE Username = @inUsuario AND Password = @inPassword)
        BEGIN
        SET @outCodigo = 50002;
        -- Contraseña incorrecta
        SET @IdTipoEvento = 2;
        -- Login No Exitoso
        SET @IdError = (SELECT Id
        FROM dbo.Error
        WHERE Codigo = '50002')
        SET @IdUsuario = (SELECT Id
        FROM dbo.Usuario
        WHERE Username = @inUsuario)
    END
        ELSE
        BEGIN
        -- Login exitoso
        SET @outCodigo = 0;
        SET @IdTipoEvento = 1;--login exitoso
        SET @IdUsuario = (SELECT Id
        FROM dbo.Usuario
        WHERE Username = @inUsuario)
    END
        INSERT INTO dbo.BitacoraEvento
        (
        IdTipoEvento,
        IdPostByUser,
        PostInIP,
        PostTime
        )
    VALUES
        (
            @IdTipoEvento,
            @IdUsuario,
            @inPostInIP,
            GETDATE()
        );
        RETURN;
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50008; -- Error en la BD
        SET @IdTipoEvento = 7; --Login no existoso
        INSERT INTO dbo.BitacoraEvento
        (
        IdTipoEvento,
        IdPostByUser,
        PostInIP,
        PostTime
        )
    VALUES
        (
            @IdTipoEvento,
            @IdUsuario,
            @inPostInIP,
            GETDATE()
        );
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RETURN;
    END CATCH
END