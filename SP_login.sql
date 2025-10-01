CREATE OR ALTER PROCEDURE [dbo].[sp_Login]
    @inUsuario NVARCHAR(50),
    @inPassword NVARCHAR(64),
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Verificar existencia
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Username = @inUsuario)
        BEGIN
            SET @outCodigo = 50001; -- Usuario no existe
            RETURN;
        END

        -- Validar credenciales
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Username = @inUsuario AND Password = @inPassword)
        BEGIN
            SET @outCodigo = 50002; -- Contraseña incorrecta
            RETURN;
        END

        -- Login exitoso
        SET @outCodigo = 0;
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50099; -- Error inesperado
    END CATCH
END
