CREATE OR ALTER PROCEDURE sp_CheckLoginBlock
    @inUsuario NVARCHAR(50),
    @inPostInIP VARCHAR(50),
    @estaBlock BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @V_IdUsuario INT;
    DECLARE @V_FailedAttempts INT;
    DECLARE @V_MaxIntentos INT = 5;
    DECLARE @V_TiempoLimite INT = 5;
    DECLARE @V_MinutosRestantes INT;
    DECLARE @V_Mensaje NVARCHAR(200);

    SET @estaBlock = 0;

    -- Obtener ID del usuario si existe
    SELECT @V_IdUsuario = Id FROM Usuario WHERE Username = @inUsuario;

    -- Si no existe, no bloquear (evita afectar a todos)
    IF @V_IdUsuario IS NULL
        RETURN;

    -- Contar los intentos fallidos del usuario en esa IP en los últimos 5 minutos
    SELECT @V_FailedAttempts = COUNT(*)
    FROM BitacoraEvento
    WHERE IdTipoEvento = 2  -- login fallido
      AND IdPostByUser = @V_IdUsuario
      AND PostInIP = @inPostInIP
      AND PostTime >= DATEADD(MINUTE, -@V_TiempoLimite, GETDATE());

    -- Si superó el límite
    IF (@V_FailedAttempts >= @V_MaxIntentos)
    BEGIN
        SET @estaBlock = 1;

        -- Registrar el evento de bloqueo en bitácora
        SET @V_Mensaje = 'Bloqueo de login: usuario ' + @inUsuario +
                         ' desde IP ' + @inPostInIP +
                         ' tras ' + CAST(@V_FailedAttempts AS NVARCHAR) + ' intentos fallidos';
        EXEC sp_RegistrarEvento 4, @V_Mensaje, @V_IdUsuario, @inPostInIP;
    END
END;
GO