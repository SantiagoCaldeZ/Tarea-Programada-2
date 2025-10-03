CREATE OR ALTER PROCEDURE sp_ConsultarEmpleado
    @IdEmpleado INT,
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Trae exactamente lo que la interfaz necesita para "Consulta"
        SELECT 
            e.Id,
            e.Nombre,
            e.ValorDocumentoIdentidad,
            p.Nombre AS Puesto,
            e.SaldoVacaciones
        FROM Empleado e
        INNER JOIN Puesto p ON e.IdPuesto = p.Id
        WHERE e.Id = @IdEmpleado AND e.EsActivo = 1;

        -- Si no hay filas, igual devolvemos 0 y que la capa lógica decida el mensaje
        SET @outCodigo = 0;
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50020; -- Error inesperado en consulta
    END CATCH
END