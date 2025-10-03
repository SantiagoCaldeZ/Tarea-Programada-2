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
                Nombre,
                ValorDocumentoIdentidad
            FROM Empleado
            WHERE Nombre LIKE '%' + @Filtro + '%'
            ORDER BY Nombre ASC;

            SET @outValorRetorno = 0; -- Éxito
        END
        ELSE IF @Tipo = 'Documento'
        BEGIN
            SELECT 
                Nombre,
                ValorDocumentoIdentidad
            FROM Empleado
            WHERE ValorDocumentoIdentidad LIKE '%' + @Filtro + '%'
            ORDER BY Nombre ASC;

            SET @outValorRetorno = 0; -- Éxito
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