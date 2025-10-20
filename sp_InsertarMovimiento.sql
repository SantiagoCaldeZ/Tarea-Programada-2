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
        DECLARE @NombreEmpleado NVARCHAR(100);
        DECLARE @ValorDoc NVARCHAR(50);
        DECLARE @NombreTipo NVARCHAR(50);
        DECLARE @mensaje NVARCHAR(300);

        -- Verificar existencia del empleado activo
        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE Id = @IdEmpleado AND EsActivo = 1)
        BEGIN
            SET @outCodigo = 50031; -- Empleado inexistente o inactivo

            SET @mensaje = 'Error 50031: Empleado no existe o está inactivo (Id=' + CAST(@IdEmpleado AS NVARCHAR(10)) + ')';
            EXEC sp_RegistrarEvento 
                 @IdTipoEvento = 4,
                 @Descripcion = @mensaje,
                 @IdPostByUser = @IdPostByUser,
                 @PostInIP = @PostInIP;
            RETURN;
        END;

        -- Obtener tipo de acción, nombre y saldo actual
        SELECT 
            @TipoAccion = tm.TipoAccion,
            @NombreTipo = tm.Nombre,
            @SaldoActual = e.SaldoVacaciones,
            @NombreEmpleado = e.Nombre,
            @ValorDoc = e.ValorDocumentoIdentidad
        FROM Empleado e
        INNER JOIN TipoMovimiento tm ON tm.Id = @IdTipoMovimiento
        WHERE e.Id = @IdEmpleado;

        IF @TipoAccion IS NULL
        BEGIN
            SET @outCodigo = 50032; -- Tipo de movimiento inválido
            SET @mensaje = 'Error 50032: Tipo de movimiento inválido (Empleado=' + @NombreEmpleado + ')';
            EXEC sp_RegistrarEvento 
                 @IdTipoEvento = 4,
                 @Descripcion = @mensaje,
                 @IdPostByUser = @IdPostByUser,
                 @PostInIP = @PostInIP;
            RETURN;
        END;

        -- Calcular nuevo saldo
        IF @TipoAccion IN ('Credito', 'Crédito')
            SET @NuevoSaldo = @SaldoActual + @Monto;
        ELSE IF @TipoAccion IN ('Debito', 'Débito')
            SET @NuevoSaldo = @SaldoActual - @Monto;
        ELSE
        BEGIN
            SET @outCodigo = 50035; -- TipoAccion desconocido
            SET @mensaje = 'Error 50035: Tipo de acción desconocido (' + ISNULL(@TipoAccion,'NULL') + ')';
            EXEC sp_RegistrarEvento 
                 @IdTipoEvento = 4,
                 @Descripcion = @mensaje,
                 @IdPostByUser = @IdPostByUser,
                 @PostInIP = @PostInIP;
            RETURN;
        END;

        -- Validar saldo no negativo
        IF @NuevoSaldo < 0
        BEGIN
            SET @outCodigo = 50033; -- Saldo insuficiente
            SET @mensaje = 'Error 50033: Saldo negativo resultante para empleado ' + @NombreEmpleado +
                           ' (Saldo actual=' + CAST(@SaldoActual AS NVARCHAR(20)) +
                           ', Monto=' + CAST(@Monto AS NVARCHAR(20)) + ')';
            EXEC sp_RegistrarEvento 
                 @IdTipoEvento = 4,
                 @Descripcion = @mensaje,
                 @IdPostByUser = @IdPostByUser,
                 @PostInIP = @PostInIP;
            RETURN;
        END;

        -- Registrar movimiento
        INSERT INTO Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
        VALUES (@IdEmpleado, @IdTipoMovimiento, GETDATE(), @Monto, @NuevoSaldo, @IdPostByUser, @PostInIP, GETDATE());

        -- Actualizar saldo
        UPDATE Empleado
        SET SaldoVacaciones = @NuevoSaldo
        WHERE Id = @IdEmpleado;

        SET @outCodigo = 0; -- Éxito

        -- ✅ Registrar evento exitoso
        SET @mensaje = 'Movimiento insertado exitosamente: Documento=' + @ValorDoc +
                       ', Nombre=' + @NombreEmpleado +
                       ', Tipo=' + @NombreTipo +
                       ', Acción=' + @TipoAccion +
                       ', Monto=' + CAST(@Monto AS NVARCHAR(20)) +
                       ', NuevoSaldo=' + CAST(@NuevoSaldo AS NVARCHAR(20));
        EXEC sp_RegistrarEvento 
             @IdTipoEvento = 3,  -- Inserción exitosa
             @Descripcion = @mensaje,
             @IdPostByUser = @IdPostByUser,
             @PostInIP = @PostInIP;

    END TRY
    BEGIN CATCH
        SET @outCodigo = 50034; -- Error inesperado
        SET @mensaje = 'Error 50034: Excepción inesperada al insertar movimiento (Empleado Id=' + CAST(@IdEmpleado AS NVARCHAR(10)) + ')';
        EXEC sp_RegistrarEvento 
             @IdTipoEvento = 4,
             @Descripcion = @mensaje,
             @IdPostByUser = @IdPostByUser,
             @PostInIP = @PostInIP;
    END CATCH
END;
GO
