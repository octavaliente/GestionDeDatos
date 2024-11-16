/*
Transaccion
Algo particular. Se limita por un bloque de codigo.
Engloba un conjunto de instrucciones y da las propiedades ACID
Propiedades 
A -> Atomicidad
C -> Consistencia
I -> Isolation
D -> Durabilidad

Se pueden cerrar con commit o rollback
*/
BEGIN TRANSACTION
	
	UPDATE Envases SET enva_detalle = 'NUEVO' 
	WHERE enva_codigo = 1 
			
ROLLBACK

-- Es para que no permita que dentro de la transaccion se lea con una misma consulta, valores distintos.
-- En el medio se actualiza el valor mediante transaccion

SET TRANSACTION ISOLATION LEVEL  REPEATABLE READ 

BEGIN TRANSACTION
	
	SELECT * FROM Envases e 
	WHERE 
		enva_codigo = 1 
		

	-- ...
	
	SELECT * FROM Envases e 
	WHERE 
		enva_codigo = 1 
			
COMMIT

--Ejecuto primero lo otro sin terminar, despues ejecuto esto y queda bloqueado hasta que termina lo primero.

SET TRANSACTION ISOLATION LEVEL READ COMMITTED 

BEGIN TRANSACTION
	
	UPDATE Envases SET enva_detalle = 'NUEVO' 
	WHERE enva_codigo = 1 
	
ROLLBACK

-- Repeteable read no resuelve datos fantasma. Para eso es serializable que es la capa maxima
-- Repeteable read bloquea los datos a los que accede y serializable a toda la tabla.

-- Deadlock (ejecutar igual desde otra query)

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE 

BEGIN TRANSACTION
	
	SELECT *  FROM Envases e  WHERE enva_codigo = 1 

	UPDATE Envases SET enva_detalle = 'MODIF' WHERE enva_codigo = 1

COMMIT

/* Resumen

NIVEL               READ          READ     REPEATABLE SERIALIZABLE 
AISLAMIENTO       UNCOMMITTED   COMMITTED   READ 
----------------------------------------------------------------------
PROBLEMA 
 DATO SUCIO/
 NO CONFIRMADO        SI           NO       NO           NO 
 ----------------------------------------------------------------------
 DATO NO REPETIBLE    SI           SI       NO           NO 
 ----------------------------------------------------------------------
 DATO FANTASMA        SI           SI       SI           NO 
 -----------------------------------------------------------------------
 
 */

 -- Triggers
 -- Que se cumpla una condicion para realizar una funcion
 -- Agregar logica de negocio ante la ocurrencia de un evento
 -- Evento: insert update delete sobre una tabla. 
 -- Se puede hacer en 3 momentos. before after y instead of (durante)

CREATE  trigger tr_ejemplo_empl
on factura 
AFTER INSERT 
AS 
BEGIN TRANSACTION

	DECLARE @vend  numeric(6 ,0)
	DECLARE @total decimal(12,2)
	
	DECLARE mi_cursor cursor for 
		SELECT
			fact_vendedor,
			fact_total
		FROM INSERTED 
		
	open  mi_cursor
	fetch mi_cursor 
		into @vend, @total
		
	while @@fetch_status = 0
	begin
		print @vend	
		update Empleado 
			set empl_comision = empl_comision + @total
		where 
			empl_codigo = @vend	
			
		fetch mi_cursor 
			into @vend, @total
	end 
	close mi_cursor 
	deallocate mi_cursor 

COMMIT

select * from Empleado e 


insert into Factura (fact_cliente, fact_fecha, fact_numero, 
				     fact_sucursal, fact_tipo, fact_total,
				     fact_total_impuestos, fact_vendedor)
values(
	'00000', getdate(), '00000013',
	'0001' , 'A'  , 100 ,
	90, 1
)

-- Trigger con DELETE

CREATE   trigger tr_ejemplo_empl_DEL
on factura 
AFTER DELETE 
AS 
BEGIN TRANSACTION

	DECLARE @vend  numeric(6 ,0)
	DECLARE @total decimal(12,2)
	
	DECLARE mi_cursor cursor for 
		SELECT
			fact_vendedor,
			fact_total
		FROM DELETED  
		
		
	open  mi_cursor
	fetch mi_cursor 
		into @vend, @total
		
	while @@fetch_status = 0
	begin
		print 'ENTRO ACA'
		
		update Empleado 
			set empl_comision = empl_comision - @total
		where 
			empl_codigo = @vend	
			
		fetch mi_cursor 
			into @vend, @total
	end 
	close mi_cursor 
	deallocate mi_cursor 

COMMIT

select * from Empleado e 

SELECT * FROM Factura f WHERE fact_numero = '00000012'
DELETE Factura  WHERE fact_numero = '00000012'
select * from Empleado e 

SELECT * FROM Factura f WHERE fact_numero = '00000012'
DELETE Factura  WHERE fact_numero = '00000012'