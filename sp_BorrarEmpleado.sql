CREATE OR ALTER PROCEDURE sp_BorrarEmpleado
    @IdEmpleado INT,
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @mensaje NVARCHAR(200);

    BEGIN TRY
        -- Cuando el empleado no existe
        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE Id = @IdEmpleado)
        BEGIN
            SET @outCodigo = 50001; -- No existe
            SET @mensaje = 'Intento de eliminar empleado inexistente (Id=' + CAST(@IdEmpleado AS NVARCHAR(10)) + ')';
            EXEC sp_RegistrarEvento 
                 @IdTipoEvento = 4, 
                 @Descripcion = @mensaje,
                 @IdPostByUser = 1,
                 @PostInIP = '127.0.0.1';
            RETURN;
        END;

        -- Cuando ya estaba inactivo
        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE Id = @IdEmpleado AND EsActivo = 1)
        BEGIN
            SET @outCodigo = 50002; -- Ya estaba inactivo
            SET @mensaje = 'Empleado ya estaba inactivo (Id=' + CAST(@IdEmpleado AS NVARCHAR(10)) + ')';
            EXEC sp_RegistrarEvento 
                 @IdTipoEvento = 4, 
                 @Descripcion = @mensaje,
                 @IdPostByUser = 1,
                 @PostInIP = '127.0.0.1';
            RETURN;
        END;

        -- Éxito
        UPDATE Empleado 
        SET EsActivo = 0 
        WHERE Id = @IdEmpleado;

        SET @outCodigo = 0;

        SET @mensaje = 'Empleado desactivado exitosamente (Id=' + CAST(@IdEmpleado AS NVARCHAR(10)) + ')';
        EXEC sp_RegistrarEvento 
             @IdTipoEvento = 3, 
             @Descripcion = @mensaje,
             @IdPostByUser = 1,
             @PostInIP = '127.0.0.1';
    END TRY

    BEGIN CATCH
        SET @outCodigo = 50020;

        SET @mensaje = 'Error inesperado al eliminar empleado (Id=' + CAST(@IdEmpleado AS NVARCHAR(10)) + ')';
        EXEC sp_RegistrarEvento 
             @IdTipoEvento = 4, 
             @Descripcion = @mensaje,
             @IdPostByUser = 1,
             @PostInIP = '127.0.0.1';
    END CATCH
END;
GO