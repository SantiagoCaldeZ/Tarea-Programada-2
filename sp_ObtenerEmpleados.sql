CREATE OR ALTER PROCEDURE sp_ObtenerEmpleados
    @outValorRetorno INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            Id,                  
            Nombre,
            ValorDocumentoIdentidad
        FROM Empleado
        WHERE EsActivo = 1
        ORDER BY Nombre ASC;

        SET @outValorRetorno = 0;
    END TRY
    BEGIN CATCH
        SET @outValorRetorno = 50001;
    END CATCH
END
