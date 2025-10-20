select *
from dbo.Puesto
select *
from dbo.TipoEvento
select *
from dbo.TipoMovimiento
select *
from dbo.Usuario
select *
from dbo.Error
select *
from dbo.Empleado
select *
from dbo.Movimiento

delete from dbo.Movimiento
--7
delete from dbo.Empleado
--6
delete from dbo.Puesto
--1
delete from dbo.TipoEvento
--2
delete from dbo.TipoMovimiento
--3
delete from dbo.Usuario
--4
delete from dbo.Error
--5

DBCC CHECKIDENT ('dbo.Puesto', RESEED, 0);
DBCC CHECKIDENT ('dbo.TipoEvento', RESEED, 0);
DBCC CHECKIDENT ('dbo.TipoMovimiento', RESEED, 0);
DBCC CHECKIDENT ('dbo.Usuario', RESEED, 0);
DBCC CHECKIDENT ('dbo.Error', RESEED, 0);
DBCC CHECKIDENT ('dbo.Empleado', RESEED, 0);
DBCC CHECKIDENT ('dbo.Movimiento', RESEED, 0);







