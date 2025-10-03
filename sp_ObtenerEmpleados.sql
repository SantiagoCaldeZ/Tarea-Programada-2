CREATE OR ALTER PROCEDURE sp_ObtenerEmpleados
    @outValorRetorno INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            Nombre,
            ValorDocumentoIdentidad
        FROM Empleado
        ORDER BY Nombre ASC;

        SET @outValorRetorno = 0; -- Éxito
    END TRY
    BEGIN CATCH
        SET @outValorRetorno = 50001; -- Error genérico al obtener
    END CATCH
END