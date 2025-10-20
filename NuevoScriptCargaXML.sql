SET NOCOUNT ON;

DECLARE @XML AS XML;
DECLARE @handle AS INT;
DECLARE @outResultCode AS INT;
--esta variable se va a usar en el SP que se llama mas adelante el cual que permite a SQL Server navegar por la estructura del XML como si fueran tablas relacionales

-- Variables para el procesamiento de Movimientos
DECLARE @T_Movimientos AS TABLE --tablas variables, segun el estandar del profe si se pueden usar. Esta alamacena los datos brutos del XML junto con claves y un numero de fila secuencial
    (
    RowNum INT PRIMARY KEY
    ,
    IdEmpleado INT
    ,
    IdTipoMovimiento INT
    ,
    TipoAccion VARCHAR(10)
    ,
    Fecha DATE
    ,
    Monto DECIMAL(10, 2)
    ,
    IdPostByUser INT
    ,
    PostInIP VARCHAR(50)
    ,
    PostTime DATETIME
    );

DECLARE @T_MovAcumulados AS TABLE --se usa para calcular el saldo por cada movimiento.
    (
    RowNum INT PRIMARY KEY
    ,
    IdEmpleado INT
    ,
    NuevoSaldo DECIMAL(10, 2)
    );


--le asigna el contenido del XML a la variable @XML
SET @XML = N'<?xml version=''1.0''?> 
<Datos>
<Puestos>
<Puesto Nombre="Cajero" SalarioxHora="11.00"/>
<Puesto Nombre="Camarero" SalarioxHora="10.00"/>
<Puesto Nombre="Cuidador" SalarioxHora="13.50"/>
<Puesto Nombre="Conductor" SalarioxHora="15.00"/>
<Puesto Nombre="Asistente" SalarioxHora="11.00"/>
<Puesto Nombre="Recepcionista" SalarioxHora="12.00"/>
<Puesto Nombre="Fontanero" SalarioxHora="13.00"/>
<Puesto Nombre="Niñera" SalarioxHora="12.00"/>
<Puesto Nombre="Conserje" SalarioxHora="11.00"/>
<Puesto Nombre="Albañil" SalarioxHora="10.50"/>
</Puestos>
<TiposEvento>
<TipoEvento Id="1" Nombre="Login Exitoso"/>
<TipoEvento Id="2" Nombre="Login No Exitoso"/>
<TipoEvento Id="3" Nombre="Login deshabilitado"/>
<TipoEvento Id="4" Nombre="Logout"/>
<TipoEvento Id="5" Nombre="Insercion no exitosa"/>
<TipoEvento Id="6" Nombre="Insercion exitosa"/>
<TipoEvento Id="7" Nombre="Update no exitoso"/>
<TipoEvento Id="8" Nombre="Update exitoso"/>
<TipoEvento Id="9" Nombre="Intento de borrado"/>
<TipoEvento Id="10" Nombre="Borrado exitoso"/>
<TipoEvento Id="11" Nombre="Consulta con filtro de nombre"/>
<TipoEvento Id="12" Nombre="Consulta con filtro de cedula"/>
<TipoEvento Id="13" Nombre="Intento de insertar movimiento"/>
<TipoEvento Id="14" Nombre="Insertar movimiento exitoso"/>
</TiposEvento>
<TiposMovimientos>
<TipoMovimiento Id="1" Nombre="Cumplir mes" TipoAccion="Credito"/>
<TipoMovimiento Id="2" Nombre="Bono vacacional" TipoAccion="Credito"/>
<TipoMovimiento Id="3" Nombre="Reversion Debito" TipoAccion="Credito"/>
<TipoMovimiento Id="4" Nombre="Disfrute de vacaciones" TipoAccion="Debito"/>
<TipoMovimiento Id="5" Nombre="Venta de vacaciones" TipoAccion="Debito"/>
<TipoMovimiento Id="6" Nombre="Reversion de Credito" TipoAccion="Debito"/>
</TiposMovimientos>
<Usuarios>
<usuario Id="1" Nombre="UsuarioScripts" Pass=")*2LnSr^lk"/>
<usuario Id="2" Nombre="David" Pass="232rr^k"/>
<usuario Id="3" Nombre="Alejandro" Pass="test"/>
<usuario Id="4" Nombre="Esteban" Pass="contrasena"/>
<usuario Id="5" Nombre="Daniel" Pass="himB9Dzd%_"/>
<usuario Id="6" Nombre="Alex" Pass="24himAzzd%_65"/>
<usuario Id="7" Nombre="Usuario No Valido" Pass="NoSoyValido"/>
</Usuarios>
<Error>
<errorCodigo Id="1" Codigo="50001" Descripcion="Username no existe"/>
<errorCodigo Id="2" Codigo="50002" Descripcion="Password no existe"/>
<errorCodigo Id="3" Codigo="50003" Descripcion="Login deshabilitado"/>
<errorCodigo Id="4" Codigo="50004" Descripcion="Empleado con ValorDocumentoIdentidad ya existe en inserción"/>
<errorCodigo Id="5" Codigo="50005" Descripcion="Empleado con mismo nombre ya existe en inserción"/>
<errorCodigo Id="6" Codigo="50006" Descripcion="Empleado con ValorDocumentoIdentidad ya existe en actualizacion"/>
<errorCodigo Id="7" Codigo="50007" Descripcion="Empleado con mismo nombre ya existe en actualización"/>
<errorCodigo Id="8" Codigo="50008" Descripcion="Error de base de datos"/>
<errorCodigo Id="9" Codigo="50009" Descripcion="Nombre de empleado no alfabético"/>
<errorCodigo Id="10" Codigo="50010" Descripcion="Valor de documento de identidad no alfabético"/>
<errorCodigo Id="11" Codigo="50011" Descripcion="Monto del movimiento rechazado pues si se aplicar el saldo seria negativo."/>
</Error>
<Empleados>
<empleado Puesto="Fontanero" ValorDocumentoIdentidad="56917772" Nombre="Samantha Pratt" FechaContratacion="2022-01-08"/>
<empleado Puesto="Cajero" ValorDocumentoIdentidad="26992786" Nombre="Jeffrey Watson" FechaContratacion="2023-02-13"/>
<empleado Puesto="Asistente" ValorDocumentoIdentidad="36042906" Nombre="Carrie Tran" FechaContratacion="2021-10-16"/>
<empleado Puesto="Recepcionista" ValorDocumentoIdentidad="99364103" Nombre="William Jenkins" FechaContratacion="2024-04-29"/>
<empleado Puesto="Conductor" ValorDocumentoIdentidad="23357035" Nombre="Nathan Lee" FechaContratacion="2021-07-25"/>
<empleado Puesto="Asistente" ValorDocumentoIdentidad="44223318" Nombre="Gerald Ponce" FechaContratacion="2022-10-27"/>
<empleado Puesto="Albañil" ValorDocumentoIdentidad="1463670" Nombre="Matthew Martin" FechaContratacion="2025-08-15"/>
<empleado Puesto="Fontanero" ValorDocumentoIdentidad="25008030" Nombre="Matthew Rodriguez" FechaContratacion="2025-08-03"/>
<empleado Puesto="Cuidador" ValorDocumentoIdentidad="25381150" Nombre="Crystal Mills" FechaContratacion="2021-05-13"/>
<empleado Puesto="Recepcionista" ValorDocumentoIdentidad="6402399" Nombre="Shane Robinson" FechaContratacion="2025-03-13"/>
<empleado Puesto="Camarero" ValorDocumentoIdentidad="90886933" Nombre="Kevin Holmes" FechaContratacion="2017-12-17"/>
<empleado Puesto="Fontanero" ValorDocumentoIdentidad="6575299" Nombre="Elizabeth Lin" FechaContratacion="2015-11-30"/>
<empleado Puesto="Asistente" ValorDocumentoIdentidad="21169228" Nombre="Hannah Peterson" FechaContratacion="2022-04-27"/>
<empleado Puesto="Conserje" ValorDocumentoIdentidad="44454429" Nombre="Antonio Wallace" FechaContratacion="2022-05-10"/>
<empleado Puesto="Cuidador" ValorDocumentoIdentidad="25090046" Nombre="Patricia Richardson" FechaContratacion="2024-06-21"/>
<empleado Puesto="Albañil" ValorDocumentoIdentidad="17308111" Nombre="Mr. Mark Nguyen" FechaContratacion="2022-11-29"/>
<empleado Puesto="Conserje" ValorDocumentoIdentidad="74794219" Nombre="Randy Hale" FechaContratacion="2025-03-22"/>
<empleado Puesto="Cuidador" ValorDocumentoIdentidad="21086955" Nombre="Christopher Coffey" FechaContratacion="2019-09-05"/>
<empleado Puesto="Recepcionista" ValorDocumentoIdentidad="28280052" Nombre="Dwayne Medina" FechaContratacion="2024-08-04"/>
<empleado Puesto="Camarero" ValorDocumentoIdentidad="94377996" Nombre="Aaron Crawford" FechaContratacion="2018-11-24"/>
</Empleados>
<Movimientos>
<movimiento ValorDocId="26992786" IdTipoMovimiento="1" Fecha="2025-01-10" Monto="3" PostByUser="David" PostInIP="43.66.240.64" PostTime="2025-01-10 00:00:00"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="6" Fecha="2025-01-11" Monto="3" PostByUser="David" PostInIP="43.66.240.64" PostTime="2025-01-11 07:33:38"/>
<movimiento ValorDocId="6402399" IdTipoMovimiento="3" Fecha="2025-01-12" Monto="4" PostByUser="Daniel" PostInIP="76.7.98.161" PostTime="2025-01-12 21:23:25"/>
<movimiento ValorDocId="74794219" IdTipoMovimiento="1" Fecha="2025-01-15" Monto="1" PostByUser="Alejandro" PostInIP="210.239.208.137" PostTime="2025-01-15 03:39:11"/>
<movimiento ValorDocId="25381150" IdTipoMovimiento="1" Fecha="2025-01-19" Monto="5" PostByUser="Alex" PostInIP="120.60.29.65" PostTime="2025-01-19 00:00:00"/>
<movimiento ValorDocId="25381150" IdTipoMovimiento="5" Fecha="2025-01-20" Monto="5" PostByUser="Alex" PostInIP="120.60.29.65" PostTime="2025-01-20 18:18:08"/>
<movimiento ValorDocId="56917772" IdTipoMovimiento="2" Fecha="2025-01-26" Monto="5" PostByUser="David" PostInIP="167.95.180.65" PostTime="2025-01-26 00:00:42"/>
<movimiento ValorDocId="6575299" IdTipoMovimiento="1" Fecha="2025-01-30" Monto="5" PostByUser="Alejandro" PostInIP="151.147.244.214" PostTime="2025-01-30 10:54:24"/>
<movimiento ValorDocId="17308111" IdTipoMovimiento="1" Fecha="2025-02-04" Monto="5" PostByUser="Daniel" PostInIP="25.162.194.113" PostTime="2025-02-04 00:00:00"/>
<movimiento ValorDocId="17308111" IdTipoMovimiento="5" Fecha="2025-02-05" Monto="1" PostByUser="Daniel" PostInIP="25.162.194.113" PostTime="2025-02-05 05:09:49"/>
<movimiento ValorDocId="21086955" IdTipoMovimiento="1" Fecha="2025-02-06" Monto="4" PostByUser="David" PostInIP="14.143.235.8" PostTime="2025-02-06 14:31:30"/>
<movimiento ValorDocId="17308111" IdTipoMovimiento="1" Fecha="2025-02-07" Monto="3" PostByUser="Alex" PostInIP="22.153.169.249" PostTime="2025-02-07 00:00:00"/>
<movimiento ValorDocId="17308111" IdTipoMovimiento="4" Fecha="2025-02-08" Monto="3" PostByUser="Alex" PostInIP="22.153.169.249" PostTime="2025-02-08 11:42:01"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="1" Fecha="2025-02-10" Monto="5" PostByUser="UsuarioScripts" PostInIP="53.77.99.217" PostTime="2025-02-10 00:00:00"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="4" Fecha="2025-02-11" Monto="5" PostByUser="UsuarioScripts" PostInIP="53.77.99.217" PostTime="2025-02-11 08:36:40"/>
<movimiento ValorDocId="44454429" IdTipoMovimiento="1" Fecha="2025-02-14" Monto="1" PostByUser="Daniel" PostInIP="200.32.72.100" PostTime="2025-02-14 01:54:55"/>
<movimiento ValorDocId="21169228" IdTipoMovimiento="1" Fecha="2025-02-15" Monto="5" PostByUser="UsuarioScripts" PostInIP="71.18.82.231" PostTime="2025-02-15 00:00:00"/>
<movimiento ValorDocId="21169228" IdTipoMovimiento="5" Fecha="2025-02-16" Monto="5" PostByUser="UsuarioScripts" PostInIP="71.18.82.231" PostTime="2025-02-16 02:47:06"/>
<movimiento ValorDocId="21086955" IdTipoMovimiento="4" Fecha="2025-02-19" Monto="1" PostByUser="UsuarioScripts" PostInIP="44.31.235.134" PostTime="2025-02-19 19:15:41"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="1" Fecha="2025-02-27" Monto="5" PostByUser="Daniel" PostInIP="248.85.164.92" PostTime="2025-02-27 17:13:28"/>
<movimiento ValorDocId="23357035" IdTipoMovimiento="1" Fecha="2025-02-28" Monto="11" PostByUser="Daniel" PostInIP="190.114.70.192" PostTime="2025-02-28 00:00:00"/>
<movimiento ValorDocId="23357035" IdTipoMovimiento="5" Fecha="2025-03-01" Monto="3" PostByUser="David" PostInIP="190.114.70.192" PostTime="2025-03-01 22:06:42"/>
<movimiento ValorDocId="74794219" IdTipoMovimiento="1" Fecha="2025-03-03" Monto="5" PostByUser="UsuarioScripts" PostInIP="192.228.93.183" PostTime="2025-03-03 12:36:39"/>
<movimiento ValorDocId="94377996" IdTipoMovimiento="1" Fecha="2025-03-09" Monto="3" PostByUser="Alex" PostInIP="212.122.53.118" PostTime="2025-03-09 00:00:00"/>
<movimiento ValorDocId="21086955" IdTipoMovimiento="2" Fecha="2025-03-09" Monto="1" PostByUser="Esteban" PostInIP="98.11.83.4" PostTime="2025-03-09 23:40:43"/>
<movimiento ValorDocId="94377996" IdTipoMovimiento="4" Fecha="2025-03-10" Monto="3" PostByUser="Alex" PostInIP="212.122.53.118" PostTime="2025-03-10 03:22:23"/>
<movimiento ValorDocId="21169228" IdTipoMovimiento="2" Fecha="2025-03-15" Monto="1" PostByUser="Daniel" PostInIP="106.73.23.109" PostTime="2025-03-15 13:12:00"/>
<movimiento ValorDocId="6402399" IdTipoMovimiento="1" Fecha="2025-03-26" Monto="5" PostByUser="Daniel" PostInIP="32.33.87.154" PostTime="2025-03-26 00:00:00"/>
<movimiento ValorDocId="6402399" IdTipoMovimiento="5" Fecha="2025-03-27" Monto="5" PostByUser="Daniel" PostInIP="32.33.87.154" PostTime="2025-03-27 13:02:23"/>
<movimiento ValorDocId="44223318" IdTipoMovimiento="2" Fecha="2025-04-11" Monto="3" PostByUser="David" PostInIP="177.104.198.156" PostTime="2025-04-11 07:13:10"/>
<movimiento ValorDocId="17308111" IdTipoMovimiento="1" Fecha="2025-04-11" Monto="3" PostByUser="Alejandro" PostInIP="150.248.28.40" PostTime="2025-04-11 10:30:28"/>
<movimiento ValorDocId="56917772" IdTipoMovimiento="4" Fecha="2025-04-13" Monto="3" PostByUser="UsuarioScripts" PostInIP="14.127.138.177" PostTime="2025-04-13 10:20:01"/>
<movimiento ValorDocId="25008030" IdTipoMovimiento="1" Fecha="2025-04-16" Monto="5" PostByUser="David" PostInIP="187.204.69.37" PostTime="2025-04-16 00:00:00"/>
<movimiento ValorDocId="90886933" IdTipoMovimiento="1" Fecha="2025-04-16" Monto="1" PostByUser="UsuarioScripts" PostInIP="51.53.162.157" PostTime="2025-04-16 00:43:40"/>
<movimiento ValorDocId="25008030" IdTipoMovimiento="6" Fecha="2025-04-17" Monto="5" PostByUser="David" PostInIP="187.204.69.37" PostTime="2025-04-17 05:11:36"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="5" Fecha="2025-04-24" Monto="3" PostByUser="UsuarioScripts" PostInIP="56.137.191.192" PostTime="2025-04-24 04:54:07"/>
<movimiento ValorDocId="21086955" IdTipoMovimiento="4" Fecha="2025-04-25" Monto="1" PostByUser="Alejandro" PostInIP="247.132.37.150" PostTime="2025-04-25 22:03:21"/>
<movimiento ValorDocId="6402399" IdTipoMovimiento="1" Fecha="2025-04-29" Monto="5" PostByUser="Alex" PostInIP="233.126.189.4" PostTime="2025-04-29 00:00:00"/>
<movimiento ValorDocId="6575299" IdTipoMovimiento="2" Fecha="2025-04-29" Monto="3" PostByUser="Daniel" PostInIP="3.72.224.225" PostTime="2025-04-29 19:20:18"/>
<movimiento ValorDocId="6402399" IdTipoMovimiento="4" Fecha="2025-04-30" Monto="5" PostByUser="Alex" PostInIP="233.126.189.4" PostTime="2025-04-30 08:14:11"/>
<movimiento ValorDocId="25381150" IdTipoMovimiento="2" Fecha="2025-05-02" Monto="2" PostByUser="Daniel" PostInIP="191.95.123.55" PostTime="2025-05-02 20:39:36"/>
<movimiento ValorDocId="17308111" IdTipoMovimiento="2" Fecha="2025-05-05" Monto="4" PostByUser="Esteban" PostInIP="215.185.52.14" PostTime="2025-05-05 18:48:50"/>
<movimiento ValorDocId="94377996" IdTipoMovimiento="2" Fecha="2025-05-05" Monto="5" PostByUser="Daniel" PostInIP="91.69.28.29" PostTime="2025-05-05 21:51:00"/>
<movimiento ValorDocId="99364103" IdTipoMovimiento="1" Fecha="2025-05-07" Monto="1" PostByUser="UsuarioScripts" PostInIP="93.120.225.198" PostTime="2025-05-07 05:24:20"/>
<movimiento ValorDocId="90886933" IdTipoMovimiento="2" Fecha="2025-05-08" Monto="1" PostByUser="Daniel" PostInIP="159.122.81.68" PostTime="2025-05-08 08:47:26"/>
<movimiento ValorDocId="23357035" IdTipoMovimiento="5" Fecha="2025-05-09" Monto="4" PostByUser="Daniel" PostInIP="136.5.233.167" PostTime="2025-05-09 20:31:20"/>
<movimiento ValorDocId="44223318" IdTipoMovimiento="2" Fecha="2025-05-22" Monto="1" PostByUser="Alex" PostInIP="161.184.151.136" PostTime="2025-05-22 16:44:00"/>
<movimiento ValorDocId="1463670" IdTipoMovimiento="2" Fecha="2025-05-25" Monto="1" PostByUser="Alejandro" PostInIP="209.33.102.178" PostTime="2025-05-25 05:15:58"/>
<movimiento ValorDocId="36042906" IdTipoMovimiento="1" Fecha="2025-06-02" Monto="2" PostByUser="Alejandro" PostInIP="107.251.169.29" PostTime="2025-06-02 00:00:00"/>
<movimiento ValorDocId="25090046" IdTipoMovimiento="3" Fecha="2025-06-03" Monto="3" PostByUser="David" PostInIP="96.202.21.227" PostTime="2025-06-03 02:02:50"/>
<movimiento ValorDocId="23357035" IdTipoMovimiento="6" Fecha="2025-06-03" Monto="2" PostByUser="UsuarioScripts" PostInIP="73.14.29.206" PostTime="2025-06-03 09:16:54"/>
<movimiento ValorDocId="36042906" IdTipoMovimiento="5" Fecha="2025-06-03" Monto="2" PostByUser="Alejandro" PostInIP="107.251.169.29" PostTime="2025-06-03 15:13:47"/>
<movimiento ValorDocId="25008030" IdTipoMovimiento="1" Fecha="2025-06-06" Monto="1" PostByUser="Alex" PostInIP="48.234.245.82" PostTime="2025-06-06 22:26:20"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="1" Fecha="2025-06-10" Monto="3" PostByUser="David" PostInIP="97.121.125.85" PostTime="2025-06-10 00:00:00"/>
<movimiento ValorDocId="99364103" IdTipoMovimiento="1" Fecha="2025-06-10" Monto="2" PostByUser="David" PostInIP="14.174.54.133" PostTime="2025-06-10 01:10:19"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="6" Fecha="2025-06-11" Monto="5" PostByUser="David" PostInIP="97.121.125.85" PostTime="2025-06-11 13:06:56"/>
<movimiento ValorDocId="44454429" IdTipoMovimiento="1" Fecha="2025-06-13" Monto="5" PostByUser="David" PostInIP="102.153.127.242" PostTime="2025-06-13 00:00:00"/>
<movimiento ValorDocId="44454429" IdTipoMovimiento="5" Fecha="2025-06-14" Monto="3" PostByUser="David" PostInIP="102.153.127.242" PostTime="2025-06-14 06:16:36"/>
<movimiento ValorDocId="25090046" IdTipoMovimiento="6" Fecha="2025-06-17" Monto="2" PostByUser="Alex" PostInIP="251.179.41.35" PostTime="2025-06-17 22:47:16"/>
<movimiento ValorDocId="17308111" IdTipoMovimiento="6" Fecha="2025-06-19" Monto="2" PostByUser="Esteban" PostInIP="223.203.62.207" PostTime="2025-06-19 23:24:21"/>
<movimiento ValorDocId="94377996" IdTipoMovimiento="1" Fecha="2025-06-27" Monto="1" PostByUser="Daniel" PostInIP="33.146.139.18" PostTime="2025-06-27 00:41:12"/>
<movimiento ValorDocId="28280052" IdTipoMovimiento="2" Fecha="2025-07-05" Monto="1" PostByUser="David" PostInIP="155.188.74.28" PostTime="2025-07-05 07:03:36"/>
<movimiento ValorDocId="25008030" IdTipoMovimiento="1" Fecha="2025-07-21" Monto="3" PostByUser="Daniel" PostInIP="94.183.32.100" PostTime="2025-07-21 01:19:48"/>
<movimiento ValorDocId="28280052" IdTipoMovimiento="1" Fecha="2025-07-22" Monto="1" PostByUser="Alex" PostInIP="73.179.216.77" PostTime="2025-07-22 00:00:00"/>
<movimiento ValorDocId="28280052" IdTipoMovimiento="5" Fecha="2025-07-23" Monto="2" PostByUser="Alex" PostInIP="73.179.216.77" PostTime="2025-07-23 05:24:37"/>
<movimiento ValorDocId="6575299" IdTipoMovimiento="5" Fecha="2025-07-25" Monto="4" PostByUser="Alex" PostInIP="93.113.85.164" PostTime="2025-07-25 04:47:46"/>
<movimiento ValorDocId="23357035" IdTipoMovimiento="5" Fecha="2025-07-29" Monto="2" PostByUser="UsuarioScripts" PostInIP="8.242.126.94" PostTime="2025-07-29 21:44:07"/>
<movimiento ValorDocId="21169228" IdTipoMovimiento="6" Fecha="2025-08-06" Monto="1" PostByUser="Alejandro" PostInIP="172.194.127.98" PostTime="2025-08-06 23:15:16"/>
<movimiento ValorDocId="90886933" IdTipoMovimiento="1" Fecha="2025-08-10" Monto="3" PostByUser="Daniel" PostInIP="195.245.39.101" PostTime="2025-08-10 00:00:00"/>
<movimiento ValorDocId="90886933" IdTipoMovimiento="5" Fecha="2025-08-11" Monto="3" PostByUser="Daniel" PostInIP="195.245.39.101" PostTime="2025-08-11 01:34:27"/>
<movimiento ValorDocId="44454429" IdTipoMovimiento="1" Fecha="2025-08-12" Monto="3" PostByUser="Alejandro" PostInIP="95.249.98.184" PostTime="2025-08-12 00:00:00"/>
<movimiento ValorDocId="44454429" IdTipoMovimiento="4" Fecha="2025-08-13" Monto="2" PostByUser="Alejandro" PostInIP="95.249.98.184" PostTime="2025-08-13 18:02:39"/>
<movimiento ValorDocId="94377996" IdTipoMovimiento="5" Fecha="2025-08-17" Monto="2" PostByUser="David" PostInIP="10.158.143.160" PostTime="2025-08-17 17:36:59"/>
<movimiento ValorDocId="44454429" IdTipoMovimiento="1" Fecha="2025-08-24" Monto="1" PostByUser="Esteban" PostInIP="188.225.97.77" PostTime="2025-08-24 00:00:00"/>
<movimiento ValorDocId="44454429" IdTipoMovimiento="6" Fecha="2025-08-25" Monto="1" PostByUser="Esteban" PostInIP="188.225.97.77" PostTime="2025-08-25 08:21:10"/>
<movimiento ValorDocId="1463670" IdTipoMovimiento="4" Fecha="2025-09-02" Monto="1" PostByUser="David" PostInIP="180.255.95.75" PostTime="2025-09-02 03:16:32"/>
<movimiento ValorDocId="6402399" IdTipoMovimiento="1" Fecha="2025-09-19" Monto="1" PostByUser="Alejandro" PostInIP="194.85.35.137" PostTime="2025-09-19 00:00:00"/>
<movimiento ValorDocId="6402399" IdTipoMovimiento="6" Fecha="2025-09-20" Monto="1" PostByUser="Alejandro" PostInIP="194.85.35.137" PostTime="2025-09-20 02:09:23"/>
<movimiento ValorDocId="6575299" IdTipoMovimiento="3" Fecha="2025-10-09" Monto="3" PostByUser="David" PostInIP="56.217.141.32" PostTime="2025-10-09 12:31:11"/>
<movimiento ValorDocId="99364103" IdTipoMovimiento="2" Fecha="2025-10-16" Monto="1" PostByUser="David" PostInIP="97.157.120.48" PostTime="2025-10-16 02:24:51"/>
<movimiento ValorDocId="23357035" IdTipoMovimiento="1" Fecha="2025-10-18" Monto="4" PostByUser="Daniel" PostInIP="78.237.104.161" PostTime="2025-10-18 21:32:48"/>
<movimiento ValorDocId="36042906" IdTipoMovimiento="1" Fecha="2025-10-23" Monto="5" PostByUser="David" PostInIP="232.99.58.132" PostTime="2025-10-23 11:22:07"/>
<movimiento ValorDocId="6575299" IdTipoMovimiento="2" Fecha="2025-11-01" Monto="1" PostByUser="David" PostInIP="221.106.143.142" PostTime="2025-11-01 01:26:12"/>
<movimiento ValorDocId="25090046" IdTipoMovimiento="1" Fecha="2025-11-04" Monto="5" PostByUser="David" PostInIP="198.228.99.29" PostTime="2025-11-04 21:26:33"/>
<movimiento ValorDocId="25090046" IdTipoMovimiento="1" Fecha="2025-11-09" Monto="2" PostByUser="Esteban" PostInIP="171.46.75.52" PostTime="2025-11-09 20:39:14"/>
<movimiento ValorDocId="21169228" IdTipoMovimiento="1" Fecha="2025-11-14" Monto="2" PostByUser="UsuarioScripts" PostInIP="53.77.32.73" PostTime="2025-11-14 12:20:55"/>
<movimiento ValorDocId="56917772" IdTipoMovimiento="2" Fecha="2025-11-21" Monto="2" PostByUser="Alex" PostInIP="134.34.201.165" PostTime="2025-11-21 18:32:10"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="1" Fecha="2025-11-26" Monto="3" PostByUser="Esteban" PostInIP="112.174.87.212" PostTime="2025-11-26 00:00:00"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="4" Fecha="2025-11-27" Monto="3" PostByUser="Esteban" PostInIP="112.174.87.212" PostTime="2025-11-27 17:03:51"/>
<movimiento ValorDocId="26992786" IdTipoMovimiento="1" Fecha="2025-11-28" Monto="4" PostByUser="Daniel" PostInIP="28.125.172.87" PostTime="2025-11-28 02:27:27"/>
<movimiento ValorDocId="90886933" IdTipoMovimiento="1" Fecha="2025-12-01" Monto="1" PostByUser="David" PostInIP="43.163.48.231" PostTime="2025-12-01 00:00:00"/>
<movimiento ValorDocId="90886933" IdTipoMovimiento="4" Fecha="2025-12-02" Monto="1" PostByUser="David" PostInIP="43.163.48.231" PostTime="2025-12-02 15:03:16"/>
<movimiento ValorDocId="17308111" IdTipoMovimiento="3" Fecha="2025-12-27" Monto="5" PostByUser="Esteban" PostInIP="113.8.183.44" PostTime="2025-12-27 21:01:05"/>
</Movimientos>
</Datos>';


EXEC sp_xml_preparedocument --se llama al SP del sistema que analiza el XML y prepara una estructura de nodos a la que se puede acceder mediante OPENXML o el método nodes()
     @handle OUTPUT
    , @XML;

BEGIN TRY
    
    PRINT 'Inicio del try';

    BEGIN TRANSACTION;
    PRINT 'Transaccion Iniciada';
    
    --Catalogos:
    SET IDENTITY_INSERT dbo.error OFF; --esta linea se coloco ya que daba un error
    -- Tipos de Evento
    SET IDENTITY_INSERT dbo.TipoEvento ON;
    
    INSERT INTO dbo.TipoEvento
    ( Id
    , Nombre
    )
SELECT
    T.Item.value('@Id', 'INT')        AS Id
        , T.Item.value('@Nombre', 'VARCHAR(100)') AS Nombre
FROM
    @XML.nodes('/Datos/TiposEvento/TipoEvento') AS T(Item)

WHERE T.Item.value('@Id', 'INT') NOT IN (SELECT Id
FROM dbo.TipoEvento); 
    PRINT 'TipoEvento: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' filas insertadas.';
    SET IDENTITY_INSERT dbo.TipoEvento OFF;
    
    -- Tipos de Movimiento
    SET IDENTITY_INSERT dbo.TipoMovimiento ON;
    
    INSERT INTO dbo.TipoMovimiento
    ( Id
    , Nombre
    , TipoAccion
    )
SELECT
    T.Item.value('@Id', 'INT')        AS Id
        , T.Item.value('@Nombre', 'VARCHAR(100)') AS Nombre
        , T.Item.value('@TipoAccion', 'VARCHAR(10)') AS TipoAccion
FROM
    @XML.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS T(Item)

WHERE T.Item.value('@Id', 'INT') NOT IN (SELECT Id
FROM dbo.TipoMovimiento);
    PRINT 'TipoMovimiento: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' filas insertadas.';
    SET IDENTITY_INSERT dbo.TipoMovimiento OFF;
    
    -- Usuarios
    SET IDENTITY_INSERT dbo.Usuario ON;
    
    INSERT INTO dbo.Usuario
    ( Id
    , Username
    , [Password]
    )
SELECT
    T.Item.value('@Id', 'INT')        AS Id
        , T.Item.value('@Nombre', 'VARCHAR(50)') AS Username
        , T.Item.value('@Pass', 'VARCHAR(100)') AS [Password]
FROM
    @XML.nodes('/Datos/Usuarios/usuario') AS T(Item)

WHERE T.Item.value('@Id', 'INT') NOT IN (SELECT Id
FROM dbo.Usuario);
    PRINT 'Usuario: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' filas insertadas.';
    SET IDENTITY_INSERT dbo.Usuario OFF;
    
    -- Errores
    SET IDENTITY_INSERT dbo.Error ON;
    
    INSERT INTO dbo.Error
    ( Id
    , Codigo
    , Descripcion
    )
SELECT
    T.Item.value('@Id', 'INT')        AS Id
        , T.Item.value('@Codigo', 'VARCHAR(10)') AS Codigo
        , T.Item.value('@Descripcion', 'VARCHAR(255)') AS Descripcion
FROM
    @XML.nodes('/Datos/Error/errorCodigo') AS T(Item)

WHERE T.Item.value('@Id', 'INT') NOT IN (SELECT Id
FROM dbo.Error);
    PRINT 'Error Catalogo: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' filas insertadas.';
    SET IDENTITY_INSERT dbo.Error OFF;
    

    -- CARGA DE PUESTOS
    
    INSERT INTO dbo.Puesto
    ( Nombre
    , SalarioxHora
    )
SELECT
    T.Item.value('@Nombre', 'VARCHAR(100)') AS Nombre
        , T.Item.value('@SalarioxHora', 'DECIMAL(10, 2)') AS SalarioxHora
FROM
    @XML.nodes('/Datos/Puestos/Puesto') AS T(Item)

WHERE T.Item.value('@Nombre', 'VARCHAR(100)') NOT IN (SELECT Nombre
FROM dbo.Puesto);
    PRINT 'Puesto: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' filas insertadas.';

    -- CARGA DE EMPLEADOS
    
    INSERT INTO dbo.Empleado
    ( IdPuesto
    , ValorDocumentoIdentidad
    , Nombre
    , FechaContratacion
    , SaldoVacaciones
    , EsActivo
    )
SELECT
    P.Id                                    AS IdPuesto
        , E.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)') AS ValorDocumentoIdentidad
        , E.Item.value('@Nombre', 'VARCHAR(100)') AS Nombre
        , E.Item.value('@FechaContratacion', 'DATE') AS FechaContratacion
        , 0                                        AS SaldoVacaciones 
        , 1                                        AS EsActivo
FROM
    @XML.nodes('/Datos/Empleados/empleado') AS E(Item)
    INNER JOIN
    dbo.Puesto AS P
    ON 
        ( P.Nombre = E.Item.value('@Puesto', 'VARCHAR(100)') )

WHERE E.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)') NOT IN (SELECT ValorDocumentoIdentidad
FROM dbo.Empleado);
    PRINT 'Empleado: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' filas insertadas.';
    
    -- Precarga de movimientos en tabla variable y ordenamiento secuencial 
    INSERT INTO @T_Movimientos
    ( RowNum, IdEmpleado, IdTipoMovimiento, TipoAccion, Fecha, Monto, IdPostByUser, PostInIP, PostTime )
SELECT
    ROW_NUMBER() OVER (ORDER BY M.Item.value('@PostTime', 'DATETIME'), M.Item.value('@ValorDocId', 'VARCHAR(20)')) AS RowNum --asigna un número secuencial (RowNum) a cada movimiento, asegurando que el orden de procesamiento sea por fecha y hora de registro
        , E.Id, TM.Id, TM.TipoAccion
        , M.Item.value('@Fecha', 'DATE')
        , M.Item.value('@Monto', 'DECIMAL(10, 2)')
        , U.Id
        , M.Item.value('@PostInIP', 'VARCHAR(50)')
        , M.Item.value('@PostTime', 'DATETIME')
FROM
    @XML.nodes('/Datos/Movimientos/movimiento') AS M(Item)
    INNER JOIN dbo.Empleado AS E ON ( E.ValorDocumentoIdentidad = M.Item.value('@ValorDocId', 'VARCHAR(20)') )
    INNER JOIN dbo.TipoMovimiento AS TM ON ( TM.Id = M.Item.value('@IdTipoMovimiento', 'INT') )
    INNER JOIN dbo.Usuario AS U ON ( U.Username = M.Item.value('@PostByUser', 'VARCHAR(50)') );
    
    
    DECLARE @MovRows INT = (SELECT COUNT(*)
FROM @T_Movimientos);
    PRINT 'Movimientos Precargados (@T_Movimientos): ' + CAST(@MovRows AS VARCHAR(10)) + ' filas.';

    IF @MovRows = 0
    BEGIN
    PRINT 'ADVERTENCIA: 0 Movimientos cargados';
END


-- Calcular el saldo acumulado para cada movimiento
INSERT INTO @T_MovAcumulados
    ( RowNum, IdEmpleado, NuevoSaldo )
SELECT
    T.RowNum,
    T.IdEmpleado,
    SUM( --convierto los montos a positivos o negativos segun si es credito o debito
        CASE T.TipoAccion
            WHEN 'Credito' THEN T.Monto
            WHEN 'Debito' THEN -T.Monto 
            ELSE 0
        END
    ) OVER (
        PARTITION BY T.IdEmpleado 
        ORDER BY T.PostTime, T.RowNum 
        ROWS UNBOUNDED PRECEDING
    ) AS NuevoSaldo
FROM
    @T_Movimientos AS T
ORDER BY T.RowNum;


--Actualizar el saldo final en la tabla principal (solo la última fila de cada empleado)
UPDATE 
    E
SET 
    E.SaldoVacaciones = T_Max.NuevoSaldo
FROM
    dbo.Empleado AS E
    INNER JOIN
    (
        SELECT
        MA.IdEmpleado,
        MA.NuevoSaldo,
        ROW_NUMBER() OVER (PARTITION BY MA.IdEmpleado ORDER BY MA.RowNum DESC) AS rn
    FROM
        @T_MovAcumulados AS MA
    ) AS T_Max
    ON 
    ( T_Max.IdEmpleado = E.Id )
WHERE
    ( T_Max.rn = 1 );
PRINT 'Empleado.SaldoVacaciones: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' filas actualizadas.';
    

    INSERT INTO dbo.Movimiento
    ( IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime )
SELECT
    T.IdEmpleado, T.IdTipoMovimiento, T.Fecha, T.Monto
        , MA.NuevoSaldo
        , T.IdPostByUser, T.PostInIP, T.PostTime
FROM
    @T_Movimientos AS T
    INNER JOIN
    @T_MovAcumulados AS MA
    ON 
        ( MA.RowNum = T.RowNum );
    PRINT 'Movimiento Final: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' filas insertadas.';

    -- Finalizar la transacción
    COMMIT TRANSACTION; --si todo sale bien se hace el commit transaction
    PRINT 'Transaccion completa';
    SELECT @outResultCode = 0;
    

END TRY
BEGIN CATCH

    -- Mensajes de Error

    PRINT 'ERROR estamios en el catch';
    PRINT 'Numero de Error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Linea de Error: ' + CAST(ERROR_LINE() AS VARCHAR(10));
    PRINT 'Mensaje de Error: ' + ERROR_MESSAGE();
    
    IF ( @@TRANCOUNT > 0 )
    BEGIN
    ROLLBACK TRANSACTION;
    --si hay un errr hace un rollback
    PRINT 'rollback Ejecutado.';
END;
    
    -- Insertar en tabla de errores
    INSERT INTO dbo.DBError
    ( UserName, Number, State, Severity, Line, [Procedure], Message, [DateTime] )
VALUES
    ( SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(),
        ISNULL(ERROR_PROCEDURE(), 'Ad-Hoc Batch'), ERROR_MESSAGE(), GETDATE() )
        
    SELECT @outResultCode = 50008; 
    
END CATCH;

-- LIMPIEZA FINAL
IF ( @handle IS NOT NULL )
BEGIN
    EXEC sp_xml_removedocument --Libera la memoria utilizada por SQL Server.
          @handle;
END;