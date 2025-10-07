CREATE OR ALTER PROCEDURE sp_ObtenerEmpleados
    @outValorRetorno INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            e.Id,
            e.Nombre,
            e.ValorDocumentoIdentidad,
            e.IdPuesto,
            p.Nombre AS Puesto,
            e.SaldoVacaciones
        FROM Empleado e
        INNER JOIN Puesto p ON e.IdPuesto = p.Id
        WHERE e.EsActivo = 1
        ORDER BY e.Nombre ASC;

        SET @outValorRetorno = 0;
    END TRY
    BEGIN CATCH
        SET @outValorRetorno = 50001; -- Error inesperado al obtener empleados
    END CATCH
END
GO
