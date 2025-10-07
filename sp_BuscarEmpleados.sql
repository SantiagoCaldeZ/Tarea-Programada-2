CREATE OR ALTER PROCEDURE sp_BuscarEmpleados
    @Filtro NVARCHAR(100),
    @Tipo   NVARCHAR(20),
    @outValorRetorno INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @Tipo = 'Nombre'
        BEGIN
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
              AND e.Nombre LIKE '%' + @Filtro + '%'
            ORDER BY e.Nombre ASC;

            SET @outValorRetorno = 0;
        END
        ELSE IF @Tipo = 'Documento'
        BEGIN
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
              AND e.ValorDocumentoIdentidad LIKE '%' + @Filtro + '%'
            ORDER BY e.Nombre ASC;

            SET @outValorRetorno = 0;
        END
        ELSE
        BEGIN
            SET @outValorRetorno = 50002; -- Tipo de filtro inválido
        END
    END TRY
    BEGIN CATCH
        SET @outValorRetorno = 50003; -- Error inesperado
    END CATCH
END
GO
