CREATE OR ALTER PROCEDURE sp_InsertarEmpleado
    @Nombre NVARCHAR(64),
    @Documento NVARCHAR(64),
    @IdPuesto INT,
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje NVARCHAR(200);

    BEGIN TRY
        -- Validar duplicados solo entre empleados activos
        IF EXISTS (SELECT 1 FROM Empleado WHERE Nombre = @Nombre AND EsActivo = 1)
        BEGIN
            SET @outCodigo = 50001; -- Nombre duplicado
            SET @mensaje = 'Error 50001: intento de insertar empleado con nombre duplicado activo (' + @Nombre + ')';
            EXEC sp_RegistrarEvento 4, @mensaje, 1, '127.0.0.1';
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM Empleado WHERE ValorDocumentoIdentidad = @Documento AND EsActivo = 1)
        BEGIN
            SET @outCodigo = 50002; -- Documento duplicado
            SET @mensaje = 'Error 50002: intento de insertar empleado con documento duplicado activo (' + @Documento + ')';
            EXEC sp_RegistrarEvento 4, @mensaje, 1, '127.0.0.1';
            RETURN;
        END;

        -- Insertar nuevo empleado
        INSERT INTO Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
        VALUES (@IdPuesto, @Documento, @Nombre, GETDATE(), 0, 1);

        SET @outCodigo = 0; -- éxito
        SET @mensaje = 'Empleado insertado correctamente (' + @Nombre + ', Doc=' + @Documento + ')';
        EXEC sp_RegistrarEvento 3, @mensaje, 1, '127.0.0.1';
    END TRY

    BEGIN CATCH
        SET @outCodigo = 50008; -- Error en base de datos
        SET @mensaje = 'Error 50008 en sp_InsertarEmpleado: ' + ERROR_MESSAGE();
        EXEC sp_RegistrarEvento 4, @mensaje, 1, '127.0.0.1';
    END CATCH;
END;
GO

SELECT * FROM Empleado