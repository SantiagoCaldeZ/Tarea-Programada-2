CREATE OR ALTER PROCEDURE sp_InsertarMovimiento
    @IdEmpleado INT,
    @IdTipoMovimiento INT,
    @Monto DECIMAL(10,2),
    @IdPostByUser INT,
    @PostInIP VARCHAR(50),
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @TipoAccion NVARCHAR(20);
        DECLARE @SaldoActual DECIMAL(10,2);
        DECLARE @NuevoSaldo DECIMAL(10,2);

        -- Verificar existencia del empleado activo
        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE Id = @IdEmpleado AND EsActivo = 1)
        BEGIN
            SET @outCodigo = 50031; -- Empleado inexistente o inactivo
            RETURN;
        END;

        -- Obtener tipo de acción y saldo actual
        SELECT 
            @TipoAccion = tm.TipoAccion,
            @SaldoActual = e.SaldoVacaciones
        FROM Empleado e
        INNER JOIN TipoMovimiento tm ON tm.Id = @IdTipoMovimiento
        WHERE e.Id = @IdEmpleado;

        IF @TipoAccion IS NULL
        BEGIN
            SET @outCodigo = 50032; -- Tipo de movimiento inválido
            RETURN;
        END;

        -- Calcular nuevo saldo según tipo de acción
        IF @TipoAccion IN ('Credito', 'Crédito')
            SET @NuevoSaldo = @SaldoActual + @Monto;
        ELSE IF @TipoAccion IN ('Debito', 'Débito')
            SET @NuevoSaldo = @SaldoActual - @Monto;
        ELSE
        BEGIN
            SET @outCodigo = 50035; -- TipoAccion desconocido
            RETURN;
        END;

        -- Validar saldo no negativo
        IF @NuevoSaldo < 0
        BEGIN
            SET @outCodigo = 50033; -- Saldo insuficiente
            RETURN;
        END;

        -- Registrar movimiento
        INSERT INTO Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
        VALUES (@IdEmpleado, @IdTipoMovimiento, GETDATE(), @Monto, @NuevoSaldo, @IdPostByUser, @PostInIP, GETDATE());

        -- Actualizar saldo en empleado
        UPDATE Empleado
        SET SaldoVacaciones = @NuevoSaldo
        WHERE Id = @IdEmpleado;

        SET @outCodigo = 0; -- Éxito
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50034; -- Error inesperado
    END CATCH
END;
GO