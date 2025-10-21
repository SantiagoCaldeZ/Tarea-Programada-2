CREATE OR ALTER PROCEDURE sp_CheckLoginBlock
    @inUsuario NVARCHAR(50),
    @inPostInIP VARCHAR(50),
    @estaBlock BIT OUTPUT,
    @minutosRestantes INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @V_IdUsuario INT;
    DECLARE @V_MaxIntentos INT = 5;
    DECLARE @V_TiempoEvaluacion INT = 5;  -- ventana de conteo (min)
    DECLARE @V_TiempoBloqueo INT = 10;    -- duración del bloqueo (min)
    DECLARE @V_UltimoBloqueo DATETIME;
    DECLARE @V_UltimoFallido DATETIME;
    DECLARE @V_FailedAttempts INT;
    DECLARE @V_MinutosTranscurridos INT;
    DECLARE @V_Mensaje NVARCHAR(200);

    SET @estaBlock = 0;
    SET @minutosRestantes = 0;

    SELECT @V_IdUsuario = Id FROM Usuario WHERE Username = @inUsuario;
    IF @V_IdUsuario IS NULL RETURN;

    -----------------------------------------------------------------------
    -- 🕐 PRIMERO: verificar si ya está bloqueado (evento tipo 4)
    -----------------------------------------------------------------------
    SELECT @V_UltimoBloqueo = MAX(PostTime)
    FROM BitacoraEvento
    WHERE IdTipoEvento = 4
      AND IdPostByUser = @V_IdUsuario
      AND PostInIP = @inPostInIP;

    IF @V_UltimoBloqueo IS NOT NULL
    BEGIN
        SET @V_MinutosTranscurridos = DATEDIFF(MINUTE, @V_UltimoBloqueo, GETDATE());
        IF @V_MinutosTranscurridos < @V_TiempoBloqueo
        BEGIN
            SET @estaBlock = 1;
            SET @minutosRestantes = @V_TiempoBloqueo - @V_MinutosTranscurridos;
            RETURN; -- 🔒 sale sin evaluar más
        END
    END

    -----------------------------------------------------------------------
    -- ⚠️ SEGUNDO: verificar si hay demasiados fallos recientes
    -----------------------------------------------------------------------
    SELECT 
        @V_FailedAttempts = COUNT(*),
        @V_UltimoFallido = MAX(PostTime)
    FROM BitacoraEvento
    WHERE IdTipoEvento = 2  -- login fallido
      AND IdPostByUser = @V_IdUsuario
      AND PostInIP = @inPostInIP
      AND PostTime >= DATEADD(MINUTE, -@V_TiempoEvaluacion, GETDATE());

    IF (@V_FailedAttempts >= @V_MaxIntentos)
    BEGIN
        SET @estaBlock = 1;
        SET @minutosRestantes = @V_TiempoBloqueo;

        SET @V_Mensaje = CONCAT(
            'Usuario bloqueado temporalmente por demasiados intentos: ',
            @inUsuario,
            ' (IP ', @inPostInIP, ')'
        );

        EXEC sp_RegistrarEvento 4, @V_Mensaje, @V_IdUsuario, @inPostInIP;
    END
END;
GO