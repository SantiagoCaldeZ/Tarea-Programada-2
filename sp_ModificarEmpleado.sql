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
            @Descripcion NVARCHAR(400);

    BEGIN TRY
        -- 1️⃣ Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE Id = @IdEmpleado AND EsActivo = 1)
        BEGIN
            SET @outCodigo = 50001;
            SET @Descripcion = 'Error 50001: intento de modificar empleado inexistente (Id=' + CAST(@IdEmpleado AS NVARCHAR(10)) + ')';
            EXEC sp_RegistrarEvento 4, @Descripcion, @IdPostByUser, @PostInIP;
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

        -- 2️⃣ Validar duplicado de documento
        IF @NuevoDocumento IS NOT NULL AND EXISTS (
            SELECT 1 FROM Empleado
            WHERE ValorDocumentoIdentidad = @NuevoDocumento
              AND Id <> @IdEmpleado AND EsActivo = 1
        )
        BEGIN
            SET @outCodigo = 50002;
            SET @Descripcion = 'Error 50002: documento duplicado (' + @DocumentoAntiguo + ' → ' + @NuevoDocumento + ')';
            EXEC sp_RegistrarEvento 4, @Descripcion, @IdPostByUser, @PostInIP;
            RETURN;
        END

        -- 3️⃣ Validar duplicado de nombre
        IF @NuevoNombre IS NOT NULL AND EXISTS (
            SELECT 1 FROM Empleado
            WHERE Nombre = @NuevoNombre
              AND Id <> @IdEmpleado AND EsActivo = 1
        )
        BEGIN
            SET @outCodigo = 50003;
            SET @Descripcion = 'Error 50003: nombre duplicado (' + @NombreAntiguo + ' → ' + @NuevoNombre + ')';
            EXEC sp_RegistrarEvento 4, @Descripcion, @IdPostByUser, @PostInIP;
            RETURN;
        END

        -- 4️⃣ Actualizar
        UPDATE Empleado
        SET 
            Nombre = ISNULL(@NuevoNombre, Nombre),
            ValorDocumentoIdentidad = ISNULL(@NuevoDocumento, ValorDocumentoIdentidad),
            IdPuesto = ISNULL(@NuevoIdPuesto, IdPuesto)
        WHERE Id = @IdEmpleado;

        -- 5️⃣ Obtener nuevo puesto para bitácora
        SELECT @PuestoNuevo = p.Nombre
        FROM Puesto p
        INNER JOIN Empleado e ON e.IdPuesto = p.Id
        WHERE e.Id = @IdEmpleado;

        -- 6️⃣ Registrar éxito
        SET @Descripcion = 'Empleado modificado correctamente. Antes: ' +
                           @DocumentoAntiguo + ', ' + @NombreAntiguo + ', ' + @PuestoAntiguo +
                           ' | Después: ' + ISNULL(@NuevoDocumento, @DocumentoAntiguo) + ', ' +
                           ISNULL(@NuevoNombre, @NombreAntiguo) + ', ' +
                           @PuestoNuevo + '. Saldo=' + CAST(@SaldoVacaciones AS NVARCHAR(20));
        EXEC sp_RegistrarEvento 3, @Descripcion, @IdPostByUser, @PostInIP;

        SET @outCodigo = 0;
    END TRY

    BEGIN CATCH
        SET @outCodigo = 50020;
        SET @Descripcion = 'Error 50020: excepción en sp_ModificarEmpleado (' + ERROR_MESSAGE() + ')';
        EXEC sp_RegistrarEvento 4, @Descripcion, @IdPostByUser, @PostInIP;
    END CATCH
END;
GO