CREATE OR ALTER PROCEDURE sp_ListarMovimientos
    @IdEmpleado INT,
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Verificamos que el empleado exista y esté activo
        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE Id = @IdEmpleado AND EsActivo = 1)
        BEGIN
            SET @outCodigo = 50021; -- Empleado no existe o inactivo
            RETURN;
        END;

        -- Consulta principal: encabezado + lista de movimientos
        SELECT 
            e.ValorDocumentoIdentidad,
            e.Nombre AS NombreEmpleado,
            e.SaldoVacaciones,
            m.Fecha,
            tm.Nombre AS TipoMovimiento,
            m.Monto,
            m.NuevoSaldo,
            u.Username AS Usuario,
            m.PostInIP,
            m.PostTime
        FROM Movimiento m
        INNER JOIN Empleado e ON e.Id = m.IdEmpleado
        INNER JOIN TipoMovimiento tm ON tm.Id = m.IdTipoMovimiento
        INNER JOIN Usuario u ON u.Id = m.IdPostByUser
        WHERE e.Id = @IdEmpleado
        ORDER BY m.Fecha DESC, m.PostTime DESC; -- 🔹 Solo esto cambia

        SET @outCodigo = 0; -- Éxito
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50022; -- Error inesperado
    END CATCH
END;
GO