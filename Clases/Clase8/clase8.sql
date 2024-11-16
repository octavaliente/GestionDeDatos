create trigger tr_ejemplo_prod
on producto AFTER update 
as 
begin transaction

	select prod_codigo, prod_detalle, 'TABLA DELETED' from deleted 
	union 
	select prod_codigo, prod_detalle, 'TABLA INSERTED' from Inserted 

commit

SELECT * FROM Producto p
UPDATE Producto set prod_detalle = 'valor nuevo' 
where 
	prod_codigo IN ('00000030','00000031')

-- Trigger con rollback. Mete el update + trigger dentro del rollback

alter trigger tr_ejemplo_prod
on producto AFTER update 
as 
begin transaction


	print 'entro'
	
	select 
		prod_codigo, 
		prod_detalle, 
		'TABLA DELETED' 
	from deleted 
	union 
	select 
		prod_codigo, 
		prod_detalle, 
		'TABLA INSERTED' 
	from Inserted 

rollback
SELECT * FROM Producto p
UPDATE Producto set prod_detalle = 'valor nuevo ' +  prod_codigo
	where 
		prod_codigo IN ('00000030','00000031')

DROP TRIGGER tr_ejemplo_prod

-- El AFTER trigger tiene la tabla inserted y la deleted.

-- El Instead, en vez de hacer cierto comando, ejecuta el trigger.
-- El sig ejemplo instead of insert, en vez del insert ejecuta el trigger.
DROP TRIGGER tr_INSTEAD_envases

create trigger tr_INSTEAD_envases
on Envases INSTEAD OF insert  
as 
begin transaction

	select 
		'TABLA INSERTED',
		*
	from Inserted 

	insert into Envases (enva_codigo, enva_detalle)
	select 
		enva_codigo, LTRIM(RTRIM(enva_detalle)) + 'TR INSTEAD'
	from inserted 
	
commit

insert into Envases (enva_codigo, enva_detalle)
	values(17, 'envase 17' )

-- No hay recursividad dentro del mismo instead of. Llamaria a otro trigger si tendria un after por ej.

-- Ej 10 de la practica

-- Ejercicio
/*
EJERCICIO:
	Crear el/los objetos de base de datos que ante la venta 
	del producto '00000030' registre en una estructura adicional
	el mes, anio y la cantidad de ese producto que se esta 
	comprando.
	-------------------------
	Primero descompongo el problema
	1) entender que pide
	- Registrar en otra tabla (nueva), mes anio y cantidad de un prod_codigo
	- Realizar un trigger que se dispare al cargar una venta del producto 30
	- Tener la cantidad que vendi x mes de producto 30
	2) que tipo de trigger me conviene y sobre que evento y tabla
	-- After trigger sobre Item_Factura recupera la cantidad, la fecha recupera de Factura.
	-- Responde al evento Insert
	AFTER item_factura INSERT
	3) que otros objetos necesito para poder desarrollarlo
	-- Tabla nueva. Mes Anio Cantidad Prod_Codigo
	create table vta_30 (mes int, anio int, cantidad decimal(12,2))
	4) desarrollo
	5) test
*/
create table vta_30 (mes int, anio int, cantidad decimal(12,2))

CREATE TRIGGER tr_after_venta
ON Item_Factura AFTER INSERT
AS
BEGIN TRANSACTION
	if exists(select * from inserted where item_producto = '00000030')
	begin
		insert into vta_30 (mes, anio, cantidad)
		select MONTH(fact_fecha), 
			   YEAR(fact_fecha),
			   item_cantidad 
		from inserted
		join Factura 
		on item_tipo + item_numero + item_sucursal = fact_tipo + fact_sucursal + fact_numero
		where item_producto = '00000030'
	end
COMMIT

-- Solucion del profe completa

alter trigger trigger_producto 
	ON item_factura 
AFTER insert
AS
BEGIN TRANSACTION
declare @cantidad decimal(12,2)
declare @mes int 
declare @anio int 

		DECLARE mi_cursor CURSOR FOR 
			SELECT 
				SUM(item_cantidad),
				year(fact_fecha),
       			MONTH(fact_fecha)
			FROM INSERTED i JOIN 
				 factura f ON 
							f.fact_numero = i.item_numero and 
        				  	f.fact_tipo = i.item_tipo and 
        				  	f.fact_sucursal = i.item_sucursal 
        	WHERE 
        		i.item_producto = '00000030'
        	group by 
       			item_producto,
       			year(fact_fecha),
       			MONTH(fact_fecha)
       	OPEN mi_cursor 
       	fetch mi_cursor INTO 
       		@cantidad,
       		@anio ,
       		@mes
while @@fetch_status = 0 
       	begin
	       	
	       	update vta_30 
	       		set cantidad = cantidad + @cantidad
	       	where 
	       		mes = @mes and 
	       		anio = @anio 
	       		
	       	if @@rowcount = 0 
	       		insert into vta_30 (mes, anio, cantidad )
	       			values(@mes, @anio, @cantidad)
	       	
	    	fetch mi_cursor INTO 
	       		@cantidad,
	       		@anio ,
	       		@mes
       	end
       	close mi_cursor 
       	deallocate mi_cursor 
       			
		
COMMIT;

-- Ejercicio 10
/*
10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo verifique 
que no exista stock y si es así lo borre en caso contrario que emita un mensaje de error.
*/

alter trigger tr_producto_delete
on Producto instead of delete
as
begin
begin transaction
declare @cantidad decimal(12,2)
	if (select sum(stoc_cantidad) from deleted
	join Stock s
	on prod_codigo = stoc_producto
	group by stoc_producto) > 0
		begin
			raiserror('Error al realizar el delete', 16, 1)
			rollback
			return
		end
	else 
		begin 
			delete from Producto
			where prod_codigo in (select prod_codigo from deleted)
			-- Borrarlo de ambos lados
			DELETE s
            FROM Stock s
            JOIN DELETED d ON s.stoc_producto = d.prod_codigo;
			DELETE p
            FROM Producto p
            JOIN DELETED d ON p.prod_codigo = d.prod_codigo;
			commit
		end
end

delete from Producto where prod_codigo = '00000109'

select * from STOCK where stoc_producto = '00000117'

select * from Producto where prod_codigo = '00000117'

/*
EJERCICIO: REALIZAR UN DELETE EN CASCADA SOBRE LA TABLA CLIENTE 
QUE SE EJECUTE CUANDO UN USUARIO EJECUTA UN DELETE. 
ESTO SIGNIFICA QUE SI QUIERO BORRAR UN CLIENTE ME PERMITA HACERLO 
BORRANDO DE LAS TABLAS ADECUADAS.


DELETE CLIENTE WHERE .....
*/

CREATE TRIGGER tr_DELETE_EN_CASCADA
	ON CLIENTE
INSTEAD OF DELETE
AS
BEGIN TRANSACTION
	DECLARE @CLIENTE CHAR(6)

	DECLARE mi_cursor CURSOR FOR
		SELECT
			clie_codigo
		FROM deleted

	OPEN mi_cursor
	FETCH NEXT FROM mi_cursor INTO @CLIENTE

	WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Borro los item_factura correspondientes a las facturas del cliente
			DELETE FROM Item_Factura
			WHERE
				@CLIENTE IN (SELECT
								f.fact_cliente
							FROM Item_Factura i
								JOIN Factura f ON f.fact_numero = i.item_numero AND f.fact_sucursal = i.item_sucursal AND f.fact_tipo = i.item_tipo)
			
			-- Borro las facturas del cliente
			DELETE FROM Factura
			WHERE
				@CLIENTE = fact_cliente

			-- Borro al cliente
			DELETE FROM Cliente
			WHERE
				clie_codigo = @CLIENTE

			FETCH NEXT FROM mi_cursor INTO @CLIENTE
		END

		CLOSE mi_cursor
		DEALLOCATE mi_cursor
COMMIT

-- Ej 15 guia sql
/*
15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos 
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y 
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos 
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron 
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
Ejemplo de lo que retornaría la consulta:
PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2
*/

SELECT I1.item_producto AS 'Codigo 1',
	(SELECT prod_detalle 
	FROM Producto 
	WHERE prod_codigo = I1.item_producto) AS 'Producto 1',
	I2.item_producto AS 'Codigo 2',
	(SELECT prod_detalle 
	FROM Producto 
	WHERE prod_codigo = I2.item_producto) AS 'Producto 2',
	COUNT(*) AS 'Repeticiones'
FROM Item_Factura I1, Item_Factura I2
WHERE I1.item_numero = I2.item_numero
AND I1.item_sucursal =  I2.item_sucursal
AND I1.item_tipo = I2.item_tipo
AND I1.item_producto != I2.item_producto
AND I1.item_producto > I2.item_producto
GROUP BY I1.item_producto, I2.item_producto
HAVING COUNT(*) > 500
ORDER BY 5