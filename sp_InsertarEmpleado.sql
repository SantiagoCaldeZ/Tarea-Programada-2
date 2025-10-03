CREATE OR ALTER PROCEDURE sp_InsertarEmpleado
    @Nombre NVARCHAR(64),
    @Documento NVARCHAR(64),
    @IdPuesto INT,
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Validar duplicados
        IF EXISTS (SELECT 1 FROM Empleado WHERE Nombre = @Nombre)
        BEGIN
            SET @outCodigo = 50001; -- Nombre duplicado
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Empleado WHERE ValorDocumentoIdentidad = @Documento)
        BEGIN
            SET @outCodigo = 50002; -- Documento duplicado
            RETURN;
        END

        -- Insertar nuevo empleado
        INSERT INTO Empleado (Id, IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
        VALUES (
            (SELECT ISNULL(MAX(Id),0)+1 FROM Empleado), -- genera Id
            @IdPuesto,
            @Documento,
            @Nombre,
            GETDATE(),
            0, -- saldo inicial
            1  -- activo
        );

        SET @outCodigo = 0; -- éxito
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50099; -- error inesperado
    END CATCH
END