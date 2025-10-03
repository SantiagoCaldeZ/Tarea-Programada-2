CREATE OR ALTER PROCEDURE sp_ObtenerPuestos
    @outValorRetorno INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT Id, Nombre
        FROM Puesto
        ORDER BY Nombre ASC;

        SET @outValorRetorno = 0;
    END TRY
    BEGIN CATCH
        SET @outValorRetorno = 50010; -- error al obtener puestos
    END CATCH
END