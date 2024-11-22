/*
T-SQL
-- table
CREATE TABLE ventas( 
	venta_codigo char(8) primary key,
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

 -- Trigger -> Usa procedure
	AFTER / INSTEAD OF / BEFORE (no en sql server)
	INSERT, DELETE, UPDATE
	tabla:
	inserted, deleted, inserted y deleted

	CREATE TRIGGER trg_actualizar_saldo
	ON Ventas
	AFTER INSERT
	AS
	BEGIN
		BEGIN TRANSACTION;

		BEGIN TRY
			-- Actualizar saldo del cliente
			UPDATE Clientes
			SET saldo = saldo - (
				SELECT SUM(monto)
				FROM Inserted
			)
			WHERE cliente_id = (SELECT cliente_id FROM Inserted);

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW;
		END CATCH;
	END;

-- Procedure -> Transacciones

	CREATE PROCEDURE ActualizarInventario
		@productoId INT,
		@cantidad INT
	AS
	BEGIN
		BEGIN TRANSACTION;

		BEGIN TRY
			-- Disminuir el inventario
			UPDATE Inventario
			SET cantidad = cantidad - @cantidad
			WHERE producto_id = @productoId;

			-- Registrar el movimiento
			INSERT INTO Movimientos (producto_id, cantidad, fecha)
			VALUES (@productoId, @cantidad, GETDATE());

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW; -- Relanzar el error para su manejo
		END CATCH;
	END;

--Consideraciones
- Contemplar siempre el caso del Update, cuando hago los trigger. Pensar que puede estar
- A las tablas que creo pueden llegar a tener una constrain pk por ejemplo
- si tengo algun filtrado dentro del WHILE del cursor, puedo pensar en hacerlo en el cursor mismo.
*/