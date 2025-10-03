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
                Id,            
                Nombre,
                ValorDocumentoIdentidad
            FROM Empleado
            WHERE EsActivo = 1
              AND Nombre LIKE '%' + @Filtro + '%'
            ORDER BY Nombre ASC;

            SET @outValorRetorno = 0;
        END
        ELSE IF @Tipo = 'Documento'
        BEGIN
            SELECT 
                Id,              
                Nombre,
                ValorDocumentoIdentidad
            FROM Empleado
            WHERE EsActivo = 1
              AND ValorDocumentoIdentidad LIKE '%' + @Filtro + '%'
            ORDER BY Nombre ASC;

            SET @outValorRetorno = 0;
        END
        ELSE
        BEGIN
            SET @outValorRetorno = 50002;
        END
    END TRY
    BEGIN CATCH
        SET @outValorRetorno = 50003;
    END CATCH
END

