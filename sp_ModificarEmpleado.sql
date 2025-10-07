CREATE OR ALTER PROCEDURE sp_ModificarEmpleado
    @IdEmpleado INT,
    @NuevoNombre NVARCHAR(64) = NULL,
    @NuevoDocumento NVARCHAR(64) = NULL,
    @NuevoIdPuesto INT = NULL,
    @IdPostByUser INT,
    @PostInIP VARCHAR(32),
    @outCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NombreAntiguo NVARCHAR(64),
            @DocumentoAntiguo NVARCHAR(64),
            @PuestoAntiguo NVARCHAR(64),
            @SaldoVacaciones MONEY,
            @PuestoNuevo NVARCHAR(64),
            @Descripcion NVARCHAR(256);

    BEGIN TRY
        -- Verificar existencia del empleado activo
        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE Id = @IdEmpleado AND EsActivo = 1)
        BEGIN
            SET @outCodigo = 50001; -- No existe
            RETURN;
        END

        -- Cargar datos actuales
        SELECT 
            @NombreAntiguo = e.Nombre,
            @DocumentoAntiguo = e.ValorDocumentoIdentidad,
            @PuestoAntiguo = p.Nombre,
            @SaldoVacaciones = e.SaldoVacaciones
        FROM Empleado e
        INNER JOIN Puesto p ON e.IdPuesto = p.Id
        WHERE e.Id = @IdEmpleado;

        -- Validar duplicado de documento (solo entre empleados activos)
        IF @NuevoDocumento IS NOT NULL AND EXISTS (
            SELECT 1 
            FROM Empleado 
            WHERE ValorDocumentoIdentidad = @NuevoDocumento 
              AND Id <> @IdEmpleado
              AND EsActivo = 1
        )
        BEGIN
            SET @outCodigo = 50002; -- Documento duplicado
            SET @Descripcion = CONCAT('Error: Documento duplicado (activo). Intento cambiar ', @DocumentoAntiguo, ' → ', @NuevoDocumento);
            EXEC sp_RegistrarEvento 6, @Descripcion, @IdPostByUser, @PostInIP; -- Update No Exitoso
            RETURN;
        END

        -- Validar duplicado de nombre (solo entre empleados activos)
        IF @NuevoNombre IS NOT NULL AND EXISTS (
            SELECT 1 
            FROM Empleado 
            WHERE Nombre = @NuevoNombre 
              AND Id <> @IdEmpleado
              AND EsActivo = 1
        )
        BEGIN
            SET @outCodigo = 50003; -- Nombre duplicado
            SET @Descripcion = CONCAT('Error: Nombre duplicado (activo). Intento cambiar ', @NombreAntiguo, ' → ', @NuevoNombre);
            EXEC sp_RegistrarEvento 6, @Descripcion, @IdPostByUser, @PostInIP;
            RETURN;
        END

        -- 🔹 Actualizar solo los campos que no estén nulos
        UPDATE Empleado
        SET 
            Nombre = ISNULL(@NuevoNombre, Nombre),
            ValorDocumentoIdentidad = ISNULL(@NuevoDocumento, ValorDocumentoIdentidad),
            IdPuesto = ISNULL(@NuevoIdPuesto, IdPuesto)
        WHERE Id = @IdEmpleado;

        -- Obtener nombre del nuevo puesto
        SELECT @PuestoNuevo = p.Nombre
        FROM Puesto p
        INNER JOIN Empleado e ON e.IdPuesto = p.Id
        WHERE e.Id = @IdEmpleado;

        -- Registrar en BitácoraEvento (Update Exitoso)
        SET @Descripcion = CONCAT(
            'Antes: ', @DocumentoAntiguo, ', ', @NombreAntiguo, ', ', @PuestoAntiguo,
            ' | Después: ', ISNULL(@NuevoDocumento, @DocumentoAntiguo), ', ',
            ISNULL(@NuevoNombre, @NombreAntiguo), ', ',
            @PuestoNuevo, '. Saldo ', @SaldoVacaciones
        );
        EXEC sp_RegistrarEvento 7, @Descripcion, @IdPostByUser, @PostInIP;

        SET @outCodigo = 0; -- Éxito
    END TRY
    BEGIN CATCH
        SET @outCodigo = 50020; -- Error inesperado

        DECLARE @Err NVARCHAR(400);
        SET @Err = ERROR_MESSAGE();

        DECLARE @DescripcionError NVARCHAR(400);
        SET @DescripcionError = 'Error inesperado: ' + ISNULL(@Err, 'Desconocido');

        EXEC sp_RegistrarEvento 
            @IdTipoEvento = 6, 
            @Descripcion = @DescripcionError, 
            @IdPostByUser = @IdPostByUser, 
            @PostInIP = @PostInIP;
    END CATCH
END
GO