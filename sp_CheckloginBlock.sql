CREATE OR ALTER PROCEDURE dbo.sp_CheckLoginBlock
     @inUsuario          AS NVARCHAR(50)
   , @inPostInIP         AS VARCHAR(50)
   , @estaBlock       AS BIT OUTPUT    -- 1: Bloqueado temporalmente, 0: Disponible
AS
BEGIN
    
    SET NOCOUNT ON;

    -- Constantes para las reglas
    DECLARE @V_TiempoLimite AS INT;
    DECLARE @V_MaxIntentos      AS INT;
    SET @V_TiempoLimite = 5;
    SET @V_MaxIntentos      = 5;

    -- Variables para el proceso
    DECLARE @V_UserId           AS INT;
    DECLARE @V_FailedAttempts   AS INT;

    SET @estaBlock = 0; -- Por defecto, no está bloqueado

    -- 1. Obtener el ID del usuario
    SELECT 
          @V_UserId = U.Id
    FROM 
        dbo.Usuario AS U
    WHERE 
        ( U.Username = @inUsuario );
        
    -- Si el usuario no existe, no puede estar bloqueado, se mantiene @@estaBlock = 0
    IF ( @V_UserId IS NULL )
    BEGIN
        RETURN;
    END;

    -- 2. Contar intentos fallidos (TipoEvento=2) en los últimos 5 minutos
    SELECT
          @V_FailedAttempts = COUNT(BE.Id)
    FROM
        dbo.BitacoraEvento AS BE
    WHERE
            ( BE.IdTipoEvento = 2 )
        AND ( BE.IdPostByUser = @V_UserId )
        AND ( BE.PostInIP = @inPostInIP )
        AND ( BE.PostTime >= DATEADD(MINUTE, -@V_TiempoLimite, GETDATE()) );

    -- 3. Verificar si el conteo excede el límite
    IF ( @V_FailedAttempts > @V_MaxIntentos )
    BEGIN
        SET @estaBlock = 1; -- Bloqueo activo
    END;
    
END;

