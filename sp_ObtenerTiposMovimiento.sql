CREATE OR ALTER PROCEDURE sp_ObtenerTiposMovimiento
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM TipoMovimiento)
        BEGIN
            SELECT Id, Nombre, TipoAccion
            FROM TipoMovimiento
            ORDER BY Nombre;
            SET @outCodigo = 0;
        END
        ELSE
        BEGIN
            SET @outCodigo = 50040; -- sin registros
        END
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50041; -- error inesperado
    END CATCH
END;
GO