/*
T-SQL
-- table
CREATE TABLE ventas( 
	venta_codigo char(8),
	venta_detalle char(50),
	venta_movimientos INT,
	venta_precio DECIMAL(12,2),
	venta_renglon NUMERIC(6,0),
	venta_ganancia DECIMAL(12,2)
)
GO

-- views
-- function

-- Devuelve valor
CREATE FUNCTION fnc_cuadrado(  @param1 decimal(12,2)  )
RETURNS decimal(14,4) 
AS
BEGIN
	declare @result decimal(12,2) 
	
	set @result = @param1 * @param1
	return @result 
END;

select dbo.fnc_cuadrado(12)

-- Devuelve tabla
create function fnc_tabla1 (@codigo char(6)) 
RETURNS TABLE 
AS 
RETURN (SELECT * FROM CLIENTE WHERE clie_codigo != @codigo);

-- cursores
DECLARE mi_cursor CURSOR FOR 
		SELECT 
			clie_codigo ,
			clie_razon_social 
		FROM Cliente c 
		ORDER BY
			clie_codigo DESC 
			
	OPEN mi_cursor 
	fetch mi_cursor into @cod, @nombre
	
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		PRINT @NOMBRE
		fetch mi_cursor into @cod, @nombre
	END 
	CLOSE mi_cursor 
	DEALLOCATE mi_cursor

-- Cursor para algo en especifico 
-- le permite realizar cambios de update.
DECLARE mi_cursor CURSOR  FOR 
		SELECT 
			clie_codigo ,
			clie_razon_social 
		FROM Cliente c 
		ORDER BY
			clie_codigo DESC 
	FOR UPDATE OF 
		clie_razon_social 
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		IF @cod = '00000'
		BEGIN 
			UPDATE CLIENTE 
				SET clie_razon_social = 'CAMBIADO FOR UDPATE CURSOR'
			WHERE 
				CURRENT OF MI_CURSOR 
		END 	
		fetch mi_cursor into @cod, @nombre

FETCH NEXT FROM mi_cursor INTO @CLIENTE
WHILE @@FETCH_STATUS = 0
if @@rowcount = 0 

-- Transacciones 

BEGIN TRANSACTION
COMMIT / ROLLBACK
TRANSACTION ISOLATION LEVEL 
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

 -- Trigger
AFTER / INSTEAD OF / BEFORE (no en sql server)
INSERT, DELETE, UPDATE
tabla:
inserted, deleted, inserted y deleted

CREATE  trigger tr_ejemplo_empl
on factura 
AFTER INSERT 
AS 
BEGIN TRANSACTION
COMMIT 

--Consideraciones
- Contemplar siempre el caso del Update, cuando hago los trigger. Pensar que puede estar
- A las tablas que creo pueden llegar a tener una constrain pk por ejemplo
- si tengo algun filtrado dentro del WHILE del cursor, puedo pensar en hacerlo en el cursor mismo.
*/