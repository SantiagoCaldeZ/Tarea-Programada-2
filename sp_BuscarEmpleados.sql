CREATE OR ALTER PROCEDURE sp_BuscarEmpleados
    @Filtro NVARCHAR(100),
    @Tipo   NVARCHAR(20),
    @outValorRetorno INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje NVARCHAR(150);

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
            RETURN;
        END

        -- Registro del evento (se ejecuta siempre que haya éxito)
        IF @outValorRetorno = 0
        BEGIN
            IF @Tipo = 'Nombre'
                SET @mensaje = 'Consulta con filtro de nombre: ' + @Filtro;
            ELSE IF @Tipo = 'Documento'
                SET @mensaje = 'Consulta con filtro de cédula: ' + @Filtro;

            EXEC sp_RegistrarEvento 
                 @IdTipoEvento = 6,  -- tipo de evento de consulta
                 @Descripcion = @mensaje,
                 @IdPostByUser = 1,
                 @PostInIP = '127.0.0.1';
        END
    END TRY

    BEGIN CATCH
        SET @outValorRetorno = 50003; -- Error inesperado
        SET @mensaje = 'Error inesperado en sp_BuscarEmpleados con filtro: ' + @Filtro;
        EXEC sp_RegistrarEvento 
             @IdTipoEvento = 4,
             @Descripcion = @mensaje,
             @IdPostByUser = 1,
             @PostInIP = '127.0.0.1';
    END CATCH
END;
GO