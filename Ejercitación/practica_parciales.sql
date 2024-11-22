-- Parcial Martes 2022 SQL
/*
Enunciado: 
Realizar una consulta sql que permita saber los clientes que compraron todos los rubros dispoinbles del sistema en el 2012
De estos clientes mostrar: 
1) codigo del cliente
2) codigo de producto que en cantidades mas compro
3) nombre del producto
4) cantidad de productos distintos comprados por el cliente 
5) cantidad de productos con composicion comprados por el cliente

*/

select f.fact_cliente as cliente,
	   (
		select top 1 if2.item_producto
		from Item_Factura if2
		inner join Factura f1
			on if2.item_numero = f1.fact_numero 
			and if2.item_sucursal = f1.fact_sucursal
			and if2.item_tipo = f1.fact_tipo
			and f.fact_cliente = f1.fact_cliente
		group by f1.fact_cliente, if2.item_producto
		order by sum(if2.item_cantidad) desc
	   ) as producto,
	   (
	   select top 1 p1.prod_detalle
		from Item_Factura if2
		inner join Factura f1
			on if2.item_numero = f1.fact_numero 
			and if2.item_sucursal = f1.fact_sucursal
			and if2.item_tipo = f1.fact_tipo
			and f.fact_cliente = f1.fact_cliente
		inner join Producto p1
			on p1.prod_codigo = if2.item_producto
		group by f1.fact_cliente, p1.prod_codigo, p1.prod_detalle
		order by sum(if2.item_cantidad) desc
	   ) as detalle,
	   count (distinct p.prod_codigo) as prod_distintos,
	   (
	   select count(distinct if2.item_producto)
	   from Item_Factura if2
		inner join Factura f1
			on if2.item_numero = f1.fact_numero 
			and if2.item_sucursal = f1.fact_sucursal
			and if2.item_tipo = f1.fact_tipo
			and f.fact_cliente = f1.fact_cliente
		inner join Producto p1
			on p1.prod_codigo = if2.item_producto
		where exists (select 1 from Composicion where p1.prod_codigo = comp_producto)
	   ) as prod_compuestos
from Factura f 
inner join Item_Factura if1
	on if1.item_numero = f.fact_numero 
	and if1.item_tipo = f.fact_tipo
	and if1.item_sucursal = f.fact_sucursal
inner join Producto p
	on if1.item_producto = p.prod_codigo
where year(f.fact_fecha) = 2012
group by f.fact_cliente
having  count( distinct p.prod_rubro) = 
		(
		select count(distinct r.rubr_id) from Rubro r
		)
go
--Tsql

/*
implementar una regla de negocio en linea que al realizar una venta (insert) permita componer los productos descompuestos
si se guardan en la factura 2 hamb 2 papas 2 gaseosas se deber� guardar en la factura 2 (DOS) combo 1. Si 1 combo1 equivale a 1 hamb 1 papa 1 gaseosa
considerar que se guardan todos a la vez
*/

create trigger tr_martes22
on Item_Factura
instead of INSERT
as
begin
	declare @comp_producto char(8)
	declare @componente1 char(8)
	declare @componente2 char(8)
	declare @item_num char(8)
	declare @item_tipo char(1)
	declare @item_sucursal char(4)
	declare @comp_cantidad decimal(12,2)
	declare @item_cantidad decimal(12,2)
	declare @cantidad decimal(12,2)
	declare @precio_prod decimal(12,2)

	declare micursor cursor for 
		select item_numero, item_tipo, item_sucursal, item_producto, item_cantidad,c.comp_producto, c.comp_cantidad, p.prod_precio 
		from inserted 
		inner join Composicion c
			on item_producto = c.comp_componente
			and item_cantidad % c.comp_cantidad = 0
		inner join Producto p
			on p.prod_codigo = c.comp_producto
	open micursor
	fetch next from micursor into
		@item_num, @item_tipo, @item_sucursal, @componente1, @item_cantidad ,@comp_producto, @comp_cantidad, @precio_prod
	
	while @@FETCH_STATUS = 0
	begin
		set @cantidad = @item_cantidad / @comp_cantidad

		set @componente2 = 
			(select item_producto 
			 from inserted
			 inner join Composicion c
				on c.comp_producto = @comp_producto
				and item_producto = c.comp_componente
				and item_cantidad / c.comp_cantidad = @cantidad
			 where item_producto <> @componente1 
				and item_sucursal = @item_sucursal 
				and item_tipo = @item_tipo
				and item_numero = @item_num
			)
		if @componente2 is not null 
		begin
			insert into Item_Factura values
				(@item_tipo, @item_sucursal, @item_num, @comp_producto, @cantidad, @precio_prod)
		end
		else 
			insert into Item_Factura values
				(@item_tipo, @item_sucursal, @item_num, @comp_producto, @cantidad, @precio_prod)

		fetch next from micursor into @item_num, @item_tipo, @item_sucursal, @componente1, @item_cantidad ,@comp_producto, @comp_cantidad, @precio_prod
	end
end

CREATE TRIGGER tr_martes22
ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @comp_producto CHAR(8)
	DECLARE @item_num CHAR(8)
	DECLARE @item_tipo CHAR(1)
	DECLARE @item_sucursal CHAR(4)
	DECLARE @cantidad_combo DECIMAL(12,2)
	DECLARE @precio_combo DECIMAL(12,2)

	-- Cursor para obtener los productos y sus cantidades insertados
	DECLARE micursor CURSOR FOR 
		SELECT item_numero, item_tipo, item_sucursal, c.comp_producto, MIN(item_cantidad / c.comp_cantidad) AS cantidad_combo, p.prod_precio
		FROM inserted i
		INNER JOIN Composicion c ON i.item_producto = c.comp_componente
		INNER JOIN Producto p ON p.prod_codigo = c.comp_producto
		GROUP BY item_numero, item_tipo, item_sucursal, c.comp_producto, p.prod_precio
		HAVING COUNT(DISTINCT c.comp_componente) = (SELECT COUNT(*) FROM Composicion WHERE comp_producto = c.comp_producto)

	OPEN micursor
	FETCH NEXT FROM micursor INTO @item_num, @item_tipo, @item_sucursal, @comp_producto, @cantidad_combo, @precio_combo
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Insertar el combo completo en la tabla Item_Factura
		INSERT INTO Item_Factura
		VALUES (@item_tipo, @item_sucursal, @item_num, @comp_producto, @cantidad_combo, @precio_combo)

		-- Eliminar los componentes individuales usados del Inserted para evitar duplicados
		DELETE i
		FROM inserted i
		INNER JOIN Composicion c ON i.item_producto = c.comp_componente
		WHERE i.item_numero = @item_num
			AND i.item_tipo = @item_tipo
			AND i.item_sucursal = @item_sucursal
			AND c.comp_producto = @comp_producto

		FETCH NEXT FROM micursor INTO @item_num, @item_tipo, @item_sucursal, @comp_producto, @cantidad_combo, @precio_combo
	END

	CLOSE micursor
	DEALLOCATE micursor

	-- Insertar los productos restantes que no se convirtieron en combos
	INSERT INTO Item_Factura
	SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, prod_precio
	FROM inserted i
	LEFT JOIN Producto p ON i.item_producto = p.prod_codigo
	WHERE NOT EXISTS (
		SELECT 1
		FROM Composicion c
		WHERE i.item_producto = c.comp_componente
	)
END
-- Parcial Sabado 2022 SQL

/*
Realizaruna consulta sql que permita saber los clientes que compraron por encima del prromedio de compras fact_total de todos los clientes del 2012
De estos clientes mostrar para el 2012
cod cliente
razon social cliente
cod prod que en cant mas compro
nombre del producto del 3 
cant de prod distintos comprados por el cliente
cant de prod con comp comprados por el cliente
oprdenar poniendo primero a los clientes que compraron mas de entre 5 y 10 prod distintos en 2012
*/

select f.fact_cliente,
	   sum(f.fact_total) as facturado,
	   count(distinct if1.item_producto) as prod_distintos,
	   (
	   select c.clie_razon_social
	   from Cliente c
	   where c.clie_codigo = f.fact_cliente
	   ) as razon_social,
	   (
	   select top 1 if2.item_producto
	   from Factura f1
	   inner join Item_Factura if2
			on f1.fact_numero + f1.fact_sucursal + f1.fact_tipo
			= if2.item_numero + if2.item_sucursal + if2.item_tipo
	   where f.fact_cliente = f1.fact_cliente
	   group by f1.fact_cliente, if2.item_producto
	   order by sum(if2.item_cantidad) desc
	   ) as prod_mas_comprado,
	   (
	   select top 1 p1.prod_detalle
	   from Factura f1
	   inner join Item_Factura if2
			on f1.fact_numero + f1.fact_sucursal + f1.fact_tipo
			= if2.item_numero + if2.item_sucursal + if2.item_tipo
	   inner join Producto p1
			on p1.prod_codigo = if2.item_producto
	   where f.fact_cliente = f1.fact_cliente
	   group by f1.fact_cliente, if2.item_producto, p1.prod_detalle
	   order by sum(if2.item_cantidad)
	   ) detalle_prod_mas_comprado,
	   (
	   select count(distinct p1.prod_codigo)
	   from Factura f1
	   inner join Item_Factura if2
			on f1.fact_numero + f1.fact_sucursal + f1.fact_tipo
			= if2.item_numero + if2.item_sucursal + if2.item_tipo
	   inner join Producto p1
			on p1.prod_codigo = if2.item_producto
	   where f.fact_cliente = f1.fact_cliente
			 and exists 
			 (select 1 from Composicion 
			 where comp_producto = p1.prod_codigo
			 )
	   ) as prod_con_composicion
from Factura f
inner join Item_Factura if1
	on f.fact_numero + f.fact_sucursal + f.fact_tipo
	= if1.item_numero + if1.item_sucursal + if1.item_tipo
where year(f.fact_fecha) = 2012
group by f.fact_cliente
having sum(f.fact_total) > 
		(
		select avg(f1.fact_total) from Factura f1
		where year(f1.fact_fecha) = 2012
		)
order by case 
			when count(distinct if1.item_producto) between 5 and 10 
			then 1 
			else 0 
			end 
desc
go;
--TSQL
/*
implementar una regla de negocio de validacion en linea que permita validar el stock al realizarse una venta
cada venta se debe descontar el sobre el deposito 00
en caso de que se venda un producto compuesto, el descuento de stock se debe realizar por sus componentes
si no hay stock para ese articulo, no se debera guardar ese articulo, pero si los otros en los cuales hay stock positivo
es decir, solamente se deberan guardar aquelllos para los cuales si hay stock, sin guardarse los que no poseen cantidades suficientes
*/
create function f_sab (@prod_codigo char(8), @cantidad decimal(12,2))
returns decimal (12,2)
as
begin
	declare @stock_actual decimal (12,2)

	if @cantidad <= (select stoc_cantidad = @stock_actual from Stock where stoc_producto = @prod_codigo and stoc_deposito = '00')
		return @stock_actual 
	else 
		return -1
end
go

create trigger tr_sab
on Item_Factura
instead of INSERT
as
begin transaction
	declare @item_producto char(8)
	declare @item_precio decimal(12,2)
	declare @item_tipo char(1)
	declare @item_sucursal char(4)
	declare @item_numero char(8)
	declare @item_cantidad decimal(12,2)

	declare @stock_actual decimal(12,2)

	declare @comp_cantidad decimal(12,2)
	declare @prod_componente char(8)

	declare cursor_sab cursor for 
		select item_tipo, item_sucursal, item_numero, item_cantidad, item_producto, item_precio
		from inserted
	open cursor_sab
		fetch next from cursor_sab into @item_tipo, @item_sucursal, @item_numero, @item_cantidad, @item_producto, @item_precio
	
	while @@FETCH_STATUS = 0
	begin
		if @item_producto in (select comp_producto from Composicion)
		begin
			declare cursor_aux cursor for
				select comp_componente, comp_cantidad
				from Composicion
				where comp_producto = @item_producto
			open cursor_aux
			fetch next from cursor_aux into @prod_componente, @comp_cantidad
			while @@FETCH_STATUS = 0
			begin
				declare @stock_componente decimal (12,2)
				declare @stock_necesario decimal (12,2)
				set @stock_necesario = @comp_cantidad * @item_cantidad
				set @stock_componente = dbo.f_sab(@prod_componente, @stock_necesario)
				if @stock_componente > 0
				begin
					update Stock set stoc_cantidad = stoc_cantidad - @stock_necesario where stoc_producto = @prod_componente and stoc_deposito = '00'
					
					set @item_precio = (select prod_precio from Producto where prod_codigo = @prod_componente)

					insert into Item_Factura values (@item_tipo, @item_sucursal, @item_numero, @stock_necesario, @prod_componente, @item_precio)
				end
				fetch next from cursor_aux into @prod_componente, @comp_cantidad
			end
		end
		else
		begin
			set @stock_actual = dbo.f_sab(@item_producto, @item_cantidad)
			if @stock_actual > 0
			begin
				update Stock set stoc_cantidad = stoc_cantidad - @item_cantidad where stoc_producto = @item_producto and stoc_deposito = '00'
				insert into Item_Factura values (@item_tipo, @item_sucursal, @item_numero, @stock_necesario, @prod_componente, @item_precio)
			end
		end
	end
commit transaction
go

-- Parcial Recu Sabado SQL
--SQL
/*
Realizar una consulta sql que permita saber los clientes que compraron en el 2012 al menos 1 unidad de todos los productos compuestos
mostrar para el 2012
- cod cliente
- cod prod que en cant mas compro
- num de fila segun el orden establecido con alias llamado ordinal
- cant productos distintos comprados por el cliente
- monto total comprado
ordenar por razon social del cliente alfabeticamente primero los clientes que compraron 20 y 30 % del total facturado en el 2012 primero, luego lo restante
*/

select f1.fact_cliente,
	   (select item_producto 
	    from Item_Factura 
		inner join Factura
			on fact_numero = item_numero
			and fact_sucursal = item_sucursal
			and fact_tipo = item_tipo
			and fact_cliente = f1.fact_cliente
		where year(fact_fecha) = 2012
		order by sum(item_cantidad) desc
	   ),
	   row_number() over (partition by c.clie_codigo order by c.clie_razon_social) as ordinal
from Factura f1
inner join Item_Factura if1
	on f1.fact_numero = if1.item_numero
	and f1.fact_sucursal = if1.item_sucursal
	and f1.fact_tipo = if1.item_tipo
inner join Cliente c
	on c.clie_codigo = f1.fact_cliente
where year(f1.fact_fecha) = 2012
group by f1.fact_cliente, c.clie_razon_social ,if1.item_numero, if1.item_sucursal, if1.item_tipo
having (select count(distinct comp_producto) from Composicion) =
	   (select count(distinct if2.item_producto) from Item_Factura if2 
	    where if2.item_numero = if1.item_numero
		and if2.item_sucursal = if1.item_sucursal
		and if2.item_tipo = if1.item_tipo
		and if2.item_producto in (select comp_producto from Composicion)
	   )
order by clie_razon_social asc,
	case when sum(f1.fact_total) 
		between 
		(select sum(f2.fact_total) * 0.2 
			from Factura f2 
		 group by year(f2.fact_fecha)
		 having year(f2.fact_fecha) = 2012)
		and
		(select sum(f2.fact_total) * 0.3 
			from Factura f2 
		 group by year(f2.fact_fecha)
		 having year(f2.fact_fecha) = 2012)
	then 1
	else 0
	end
go

select f1.fact_cliente, count(distinct(if1.item_producto))
from Factura f1
inner join Item_Factura if1
	on f1.fact_numero = if1.item_numero
	and f1.fact_sucursal = if1.item_sucursal
	and f1.fact_tipo = if1.item_tipo
where if1.item_producto in (select comp_producto from Composicion)
	and year(f1.fact_fecha) = 2012
group by f1.fact_cliente

--TSQL
/*
implementar una regla de negocio en linea donde nunca una factura nueva tenga un precio de producto distinto
al que figura en la tabla PRODUCTO. Rergistrar en una estructura adicional todos los casos donde se intenta guardar un producto distinto
*/
create table tabla_recu_sab 
	(
	 prod_codigo char(8),
	 precio_correspondiente decimal(12,2),
	 precio_intentado decimal (12,2)
	)

create trigger tr_recu_sab 
on Item_Factura
instead of INSERT
as
begin tran
	declare @prod_codigo char(8)
	declare @precio_intentado decimal (12,2)
	declare @precio_correspondiente decimal(12,2)
	
	declare @item_tipo char(1)
	declare @item_sucursal char(4)
	declare @item_numero char(8)
	declare @item_cantidad decimal(12,2)

	declare cursor_recu cursor for 
		select item_tipo, item_sucursal, item_numero, item_cantidad, item_producto, item_precio
		from inserted
	open cursor_recu
	fetch next from cursor_recu into @item_tipo, @item_sucursal, @item_numero, @prod_codigo, @precio_intentado

	while @@FETCH_STATUS = 0
	begin
		set @precio_correspondiente = 
			(
			select prod_precio
			from Producto
			where @prod_codigo = prod_codigo
			)
		if @precio_correspondiente = @precio_intentado
		begin
			insert into Item_Factura values 
				(
					@item_tipo,
					@item_sucursal,
					@item_numero,
					@prod_codigo,
					@precio_intentado
				)
		end
		else 
			insert into dbo.tabla_recu_sab values (@prod_codigo, @precio_correspondiente, @precio_intentado)
	
	fetch next from cursor_recu into @item_tipo, @item_sucursal, @item_numero, @prod_codigo, @precio_intentado

	end

commit tran

-- Parcial 2023
--sql
/*
Realizar una consulta sql que devuelva todos los clientes que durante 2 a�os consecutivos compraron al menos 5 productos distintos
mostrar:
- cod cliente
- monto total comprado en 2012
- cantidad de unidades de productos compradas en el 2012
ordenado primero por aquellos clientes que compraron solo productos compuestos en algun momento, luego el resto.
*/

select distinct f1.fact_cliente,
	   (
	   select sum(f2.fact_total)
	   from Factura f2
	   where year(f2.fact_fecha) = 2012
	   and f1.fact_cliente = f2.fact_cliente
	   ) as total_facturado_2012,
	   (
	   select sum(if2.item_cantidad) 
	   from Item_Factura if2
	   inner join Factura f2
			on f2.fact_numero = if2.item_numero
			and f2.fact_sucursal = if2.item_sucursal
			and f2.fact_tipo = if2.item_tipo
	   where year(f2.fact_fecha) = 2012 
	   and f1.fact_cliente = f2.fact_cliente
	   ) as total_unidades_2012
from Item_Factura if1
inner join Factura f1
	on f1.fact_numero = if1.item_numero
	and f1.fact_sucursal = if1.item_sucursal
	and f1.fact_tipo = if1.item_tipo
group by f1.fact_cliente, year(f1.fact_fecha)
having count(distinct if1.item_producto) >= 5
	and exists
	(
	select 1 from Item_Factura if2
	inner join Factura f2
		on f2.fact_numero = if2.item_numero
		and f2.fact_sucursal = if2.item_sucursal
		and f2.fact_tipo = if2.item_tipo
	where f2.fact_cliente = f1.fact_cliente
	and year(f2.fact_fecha) in (year(f1.fact_fecha) -1,
		year(f1.fact_fecha) + 1)
	group by f2.fact_fecha, f2.fact_cliente
	having count(distinct if2.item_producto) >= 5
	)
ORDER BY CASE 
            WHEN NOT EXISTS (
                SELECT 1 
                FROM Item_Factura
                INNER JOIN Factura
                    ON item_numero = fact_numero
                    AND item_sucursal = fact_sucursal
                    AND item_tipo = fact_tipo
                WHERE fact_cliente = f1.fact_cliente
                AND item_producto NOT IN (SELECT comp_producto FROM Composicion)
            ) 
            THEN 0 
            ELSE 1 
          END 
ASC;

-- transact sql
/*
suponiendo que se aplican los siguientes cambios en el modelo de datos
1) create table provincia (id int primary key, nombre char(100))
2) alter table cliente add pcia_id int null;
crear el/los objetos necesarios para implementar el concepto de foreign key entre 2 cliente y provincia
*/

-- Parcial 2021
-- SQL
/*
1.  Armar una consulta Sql que retorne:

    - Raz�n social del cliente
    - L�mite de cr�dito del cliente
    - Producto m�s comprado en la historia (en unidades)

    Solamente deber� mostrar aquellos clientes que tuvieron mayor cantidad de ventas en el 2012 que
    en el 2011 en cantidades y cuyos montos de ventas en dichos a�os sean un 30 % mayor el 2012 con
    respecto al 2011. El resultado deber� ser ordenado por c�digo de cliente ascendente

    NOTA: No se permite el uso de sub-selects en el FROM.
*/
select c.clie_razon_social,
	   c.clie_limite_credito,
	   (
	   select top 1 sum(item_cantidad)
	   from Item_Factura
	   inner join Factura 
			on item_tipo = fact_tipo
			and item_sucursal = fact_sucursal
			and item_numero = fact_numero
			and c.clie_codigo = fact_cliente
		order by sum(item_cantidad) desc
	   )
from Factura f1
inner join Item_Factura if1
	on f1.fact_numero = if1.item_numero
	and f1.fact_sucursal = if1.item_sucursal
	and f1.fact_tipo = if1.item_tipo
inner join Cliente c
	on f1.fact_cliente = c.clie_codigo 


-- T-SQL
/*
2.  Realizar un stored procedure que reciba un c�digo de producto y una fecha y devuelva la mayor cantidad de
    d�as consecutivos a partir de esa fecha que el producto tuvo al menos la venta de una unidad en el d�a, el
    sistema de ventas on line est� habilitado 24-7 por lo que se deben evaluar todos los d�as incluyendo domingos y feriados.
*/
create procedure sp_consecutivos (@cod_producto char(8), @fecha datetime)
as
begin
	declare @fechaConsecutiva datetime
	declare @diasConsecutivos int = 0
	declare @maxDiasConsecutivos int = 0
	declare @contadorAux int = 0

	declare micursor cursor for 
	select distinct f.fact_fecha
	from Item_Factura if1
	inner join Factura f 
		on if1.item_numero = f.fact_numero
		and if1.item_sucursal = f.fact_sucursal
		and if1.item_tipo = f.fact_tipo
	where if1.item_producto = @cod_producto 
	and f.fact_fecha >= @fecha
	order by f.fact_fecha asc

	open micursor 
	fetch next from micursor into @fechaConsecutiva
	while @@FETCH_STATUS = 0
	begin
		if (dateadd(day, 1, @fecha) = @fechaConsecutiva)
		begin
			set @diasConsecutivos += 1
		end
		else 
			set @contadorAux = @diasConsecutivos
			set @diasConsecutivos = 0

		if @contadorAux > @maxDiasConsecutivos 
			set @maxDiasConsecutivos =  @diasConsecutivos

		set @fecha = @fechaConsecutiva
		fetch next from micursor into @fechaConsecutiva
	end
	close micursor
	deallocate micursor


	select @diasConsecutivos as dias_consecutivos
end

-- Parcial 2023 07 08
/*Se pide que realice un reporte generado por una sola query que de cortes de informacion por periodos
(anual,semestral y bimestral).
Un corte por el a�o, un corte por el semestre el a�o y un corte por bimestre el a�o. 
En el corte por a�o mostrar: 
las ventas totales realizadas por a�o 
la cantidad de rubros distintos comprados por a�o
la cantidad de productos con composicion distintos comporados por a�o 
la cantidad de clientes que compraron por a�o.
Luego, en la informacion del semestre mostrar la misma informacion, es decir, las ventas totales por semestre, cantidad de rubros 
por semestre, etc. y la misma logica por bimestre. El orden tiene que ser cronologico.
*/
SELECT CONCAT(YEAR(f1.fact_fecha), '') AS 'Periodo', SUM(f1.fact_total) AS 'Ventas totales',

(SELECT COUNT(DISTINCT prod_rubro) FROM Item_Factura
JOIN Producto ON prod_codigo = item_producto
JOIN Factura f2 ON f2.fact_numero = item_numero AND f2.fact_sucursal = item_sucursal AND f2.fact_tipo = item_tipo
WHERE YEAR(F2.fact_fecha) = YEAR(f1.fact_fecha)) AS 'Cant rubros',

(SELECT COUNT(DISTINCT prod_codigo) FROM Item_Factura 
JOIN Producto ON prod_codigo = item_producto
JOIN Composicion ON comp_producto = prod_codigo
JOIN Factura f2 ON f2.fact_numero = item_numero AND f2.fact_sucursal = item_sucursal AND f2.fact_tipo = item_tipo
WHERE YEAR(F2.fact_fecha) = YEAR(f1.fact_fecha)) AS 'Cant productos compuestos',

COUNT(f1.fact_cliente) AS 'Clientes del a�o'

FROM Factura f1
GROUP BY YEAR(f1.fact_fecha)

UNION 

SELECT CONCAT('Semestre ',(case when(MONTH(f1.fact_fecha) <=6) then 0 else 1 end)), SUM(f1.fact_total) AS 'Ventas totales',

(SELECT COUNT(DISTINCT prod_rubro) FROM Item_Factura
JOIN Producto ON prod_codigo = item_producto
JOIN Factura f2 ON f2.fact_numero = item_numero AND f2.fact_sucursal = item_sucursal AND f2.fact_tipo = item_tipo
WHERE YEAR(F2.fact_fecha) = YEAR(f1.fact_fecha)) AS 'Cant rubros',

(SELECT COUNT(DISTINCT prod_codigo) FROM Item_Factura 
JOIN Producto ON prod_codigo = item_producto
JOIN Composicion ON comp_producto = prod_codigo
JOIN Factura f2 ON f2.fact_numero = item_numero AND f2.fact_sucursal = item_sucursal AND f2.fact_tipo = item_tipo
WHERE YEAR(F2.fact_fecha) = YEAR(f1.fact_fecha)) AS 'Cant productos compuestos',

COUNT(f1.fact_cliente) AS 'Clientes del a�o'

FROM Factura f1
GROUP BY YEAR(f1.fact_fecha), (case when(MONTH(f1.fact_fecha) <=6) then 0 else 1 end)

UNION 

SELECT CONCAT('Bimestre ',(FLOOR((MONTH(f1.fact_fecha)-1)/2) + 1)), SUM(f1.fact_total) AS 'Ventas totales',

(SELECT COUNT(DISTINCT prod_rubro) FROM Item_Factura
JOIN Producto ON prod_codigo = item_producto
JOIN Factura f2 ON f2.fact_numero = item_numero AND f2.fact_sucursal = item_sucursal AND f2.fact_tipo = item_tipo
WHERE YEAR(F2.fact_fecha) = YEAR(f1.fact_fecha)) AS 'Cant rubros',

(SELECT COUNT(DISTINCT prod_codigo) FROM Item_Factura 
JOIN Producto ON prod_codigo = item_producto
JOIN Composicion ON comp_producto = prod_codigo
JOIN Factura f2 ON f2.fact_numero = item_numero AND f2.fact_sucursal = item_sucursal AND f2.fact_tipo = item_tipo
WHERE YEAR(F2.fact_fecha) = YEAR(f1.fact_fecha)) AS 'Cant productos compuestos',

COUNT(f1.fact_cliente) AS 'Clientes del a�o'

FROM Factura f1
GROUP BY YEAR(f1.fact_fecha), (FLOOR((MONTH(f1.fact_fecha)-1)/2) + 1)


-- Parciales de clase de repaso
/* Ej parcial 2024
1. Sabiendo que un producto recurrente es aquel producto que al menos
se compr� durante 6 meses en el �ltimo a�o.
Realizar una consulta SQL que muestre los clientes que tengan
productos recurrentes y de estos clientes mostrar:

i. El c�digo de cliente.
ii. El nombre del producto m�s comprado del cliente.
iii. La cantidad comprada total del cliente en el �ltimo a�o.

Ordenar el resultado por el nombre del cliente alfab�ticamente.
*/
select distinct f1.fact_cliente,
	   (select top 1 prod_detalle from Producto
		inner join Item_Factura
			on item_producto = prod_codigo
		inner join Factura
			on item_numero = fact_numero
			and item_sucursal = fact_sucursal
			and item_tipo = fact_tipo
			and fact_cliente = f1.fact_cliente
		group by prod_codigo, prod_detalle
		order by sum(item_cantidad) desc
	   ) as prod_mas_comprado,
	   (select sum(item_cantidad) from Item_Factura
		inner join Factura
			on fact_cliente = f1.fact_cliente
			and item_numero = fact_numero
			and item_sucursal = fact_sucursal
			and item_tipo = fact_tipo
	   )as cantidad_comprada
from Factura f1
inner join Item_Factura if1
	on if1.item_numero = f1.fact_numero
	and if1.item_sucursal = f1.fact_sucursal
	and if1.item_tipo = f1.fact_tipo
where year(f1.fact_fecha) = 2012
group by f1.fact_cliente, if1.item_producto
having count(distinct month(f1.fact_fecha)) > 6

-- Otra solucion 
SELECT DISTINCT 
    c.clie_codigo AS codigo_del_cliente,
    c.clie_razon_social AS nombre,
    (SELECT TOP 1 p.prod_detalle
     FROM Factura f2
     JOIN item_factura ifact2 
       ON f2.fact_tipo = ifact2.item_tipo
      AND f2.fact_sucursal = ifact2.item_sucursal
      AND f2.fact_numero = ifact2.item_numero
     JOIN producto p 
       ON p.prod_codigo = ifact2.item_producto
     WHERE f2.fact_cliente = c.clie_codigo
       AND YEAR(f2.fact_fecha) = 2012
     GROUP BY p.prod_detalle
     ORDER BY SUM(ifact2.item_cantidad) DESC
    ) AS producto_mas_comprado,
    SUM(ifact.item_cantidad) AS total_cantidad_comprada
FROM Factura f
JOIN cliente c 
    ON f.fact_cliente = c.clie_codigo
JOIN item_factura ifact 
    ON f.fact_tipo = ifact.item_tipo
   AND f.fact_sucursal = ifact.item_sucursal
   AND f.fact_numero = ifact.item_numero
WHERE YEAR(f.fact_fecha) = 2012
  AND ifact.item_producto IN (
      SELECT DISTINCT ifact2.item_producto
      FROM Factura f2
      JOIN item_factura ifact2 
        ON f2.fact_tipo = ifact2.item_tipo
       AND f2.fact_sucursal = ifact2.item_sucursal
       AND f2.fact_numero = ifact2.item_numero
	   and f2.fact_cliente = f.fact_cliente
      WHERE YEAR(f2.fact_fecha) = 2012
      GROUP BY ifact2.item_producto, f2.fact_cliente
      HAVING COUNT(DISTINCT MONTH(f2.fact_fecha)) >= 6
  )
GROUP BY c.clie_codigo, c.clie_razon_social
ORDER BY c.clie_razon_social ASC;

-- Ejercicio 2 
/*
1. Implementar una restricci�n que no deje realizar operaciones masivas
sobre la tabla cliente. 
En caso de que esto se intente se deber� registrar que operaci�n se intent� realizar , en que fecha y hora y sobre
que datos se trat� de realizar.
*/
create table table_ej2_24 
	(tipo_op varchar(50),
	 fecha datetime,
	 cliente_id char(6),
	 clie_razon_social char(100),
	 clie_telefono char(100),
	 clie_domicilio char(100),
	 clie_limite_credito decimal(12,2),
	 clie_vendedor numeric(6)
	)

create trigger tr_ej2_24 on Cliente
INSTEAD OF INSERT, UPDATE, DELETE
as 
begin transaction
	declare @tipo_op varchar(50) 
	declare @cliente_id char(6)
	declare @clie_razon_social char(100)
	declare @clie_telefono char(100)
	declare @clie_domicilio char(100)
	declare @clie_limite_credito decimal(12,2)
	declare @clie_vendedor numeric(6)

	if (select * from inserted) >= 1 and (select * from deleted) >=1
		set @tipo_op = 'UPDATE'
	else if (select * from inserted) >= 1
		set @tipo_op = 'INSERT'
	else 
		set @tipo_op = 'DELETE'

	if (select * from inserted) > 1 or (select * from deleted) > 1 
	begin
		if @tipo_op = 'INSERT'
		begin
			declare micursor cursor for 
			select clie_codigo, clie_domicilio, clie_razon_social, clie_telefono, clie_domicilio, clie_limite_credito, clie_vendedor 
			from inserted
			open micursor
			fetch next from micursor into @cliente_id, @clie_razon_social, @clie_telefono, @clie_domicilio, @clie_limite_credito, @clie_vendedor
			while @@FETCH_STATUS = 0
			begin
				insert into dbo.table_ej2_24
				values(@tipo_op, SYSDATETIME(), @cliente_id, @clie_razon_social, @clie_telefono, @clie_domicilio, @clie_limite_credito)
				fetch next from micursor into @cliente_id, @clie_razon_social, @clie_telefono, @clie_domicilio, @clie_limite_credito, @clie_vendedor
			end
		end
		else if @tipo_op = 'DELETE' or @tipo_op = 'UPDATE' -- muestro los valores q se quisieron updatear
		begin
			declare micursor cursor for 
			select clie_codigo, clie_domicilio, clie_razon_social, clie_telefono, clie_domicilio, clie_limite_credito, clie_vendedor 
			from deleted
			open micursor
			fetch next from micursor into @cliente_id, @clie_razon_social, @clie_telefono, @clie_domicilio, @clie_limite_credito, @clie_vendedor
			while @@FETCH_STATUS = 0
			begin
				insert into dbo.table_ej2_24
				values(@tipo_op, SYSDATETIME(), @cliente_id, @clie_razon_social, @clie_telefono, @clie_domicilio, @clie_limite_credito)
				fetch next from micursor into @cliente_id, @clie_razon_social, @clie_telefono, @clie_domicilio, @clie_limite_credito, @clie_vendedor
			end
		end

		commit transaction
	end

	if @tipo_op = 'INSERT'
	begin
		insert into Cliente
		select * from inserted
	end

	if @tipo_op = 'DELETE'
	begin
		insert into Cliente
		select * from inserted
	end

	if @tipo_op = 'UPDATE'
	begin
		UPDATE Cliente 
		set clie_codigo = i.clie_codigo
		--, ...
		from Cliente c 
		inner join inserted i on c.clie_codigo = i.clie_codigo
	end
go



-- Parcial 2024
-- 2 TSQL
/*
Implementar los objetos necesarios para registrar, en tiempo real, los 10 productos mas vendidos por a�o en una tabla especifica.
Esta tabla debe contener exclusivamente la informacion requerida sin incluir filas adicionales.
Los mas vendidos se definen como aquellos productos con el mayor numero de unidades vendidas.
*/
create table top_ventas_anio 
	(
		anio int not null,
		codigo_producto char(8) not null,
		PRIMARY KEY (anio, codigo_producto)
	)
go
/*
recorrer un select top 10 por a�o
todos los a�os posibles
*/
create procedure top_ventas
as 
begin
	declare @cod_prod char(8)
	declare @anio int

    -- a�os diferentes
    declare cursor_anios cursor FOR
    select distinct cast(year(fact_fecha) as int) from Factura
    open cursor_anios 
    fetch next from cursor_anios INTO @anio

    while @@FETCH_STATUS = 0
    BEGIN
        --inserto los 10 mas vendidos en los diferentes a�os

        insert into top_ventas_anio
        select top 10 item_producto, @anio from Item_Factura
        inner join Factura
        	on item_numero = fact_numero
	        and item_sucursal = fact_sucursal
	        and item_tipo = fact_tipo 
        where cast(year(fact_fecha) as int ) = @anio
        group by item_producto
        order by sum(item_cantidad) desc

        fetch next from cursor_anios INTO @anio
    END

    close cursor_anios
    deallocate cursor_anios
end
GO

create trigger tr_parcial24 on Item_Factura
after INSERT, UPDATE, DELETE
as 
begin
	delete from top_ventas_anio
	exec top_ventas
end

-- SQL 2024 
------------------------------ SQL - PARCIAL (16/11/2024) ------------------------------

/*
    Curso: K3673
    Alumno: Franco Ezequiel Centuri�n
    Profesor: Edgardo Lacquaniti
    Legajo: 1780189
*/

SELECT
    ROW_NUMBER() over (ORDER BY SUM(if1.item_cantidad) DESC) as numero_fila,
    c1.clie_codigo as codigo_cliente,
    c1.clie_razon_social as nombre_cliente,

    SUM(if1.item_cantidad) as cantidad_total_comprada,

    (
        SELECT TOP 1
            r1.rubr_detalle     -- Categoria m�s comprada (agarre el detalle pero tambi�n podr�a haber agarrado el id)
        FROM Factura f2
            JOIN Item_Factura if2 ON f2.fact_tipo = if2.item_tipo and f2.fact_sucursal = if2.item_sucursal and f2.fact_numero = if2.item_numero
            JOIN Producto p1 ON if2.item_producto = p1.prod_codigo
            JOIN Rubro r1 ON p1.prod_rubro = r1.rubr_id
        WHERE f2.fact_cliente = c1.clie_codigo AND YEAR(f2.fact_fecha) = 2012
        GROUP BY r1.rubr_id, r1.rubr_detalle
        ORDER BY SUM(if2.item_cantidad) desc

    ) as categoria_mas_comprada_2012

FROM Cliente c1
    JOIN Factura f1 ON c1.clie_codigo = f1.fact_cliente
    JOIN Item_Factura if1 ON f1.fact_tipo = if1.item_tipo and f1.fact_sucursal = if1.item_sucursal and f1.fact_numero = if1.item_numero
GROUP BY c1.clie_codigo, c1.clie_razon_social
HAVING
    (
        SELECT COUNT(DISTINCT r2.rubr_id)
        FROM Rubro r2
            JOIN Producto p2 ON r2.rubr_id = p2.prod_rubro
            JOIN Item_Factura if2 ON p2.prod_codigo = if2.item_producto
            JOIN Factura f2 ON if2.item_tipo = f2.fact_tipo and if2.item_sucursal = f2.fact_sucursal and if2.item_numero = f2.fact_numero
        WHERE f2.fact_cliente = c1.clie_codigo AND YEAR(f2.fact_fecha) = 2012

        ) > 3       -- Compro en m�s de 3 rubros diferentes en el 2012
        AND
        NOT EXISTS( SELECT                      -- No existe una factura de ese cliente que haya sido emitida en un a�o impar (o sea, todas las compras fueron en a�os pares)
                        1
                    FROM Factura f3
                    WHERE f3.fact_cliente = c1.clie_codigo AND YEAR(f3.fact_fecha) % 2 != 0)

ORDER BY SUM(if1.item_cantidad)�DESC

-- yo
/*
realizar una consulta sql que muestre la siguiente informacion para los clientes que hayan comprado productos en mas de tres rubros dif en el 2012
y que no compro en a�os impares
- numero de fila
- codigo cliente
- nombre cliente
- cantidad total comprada en 2012
- categoria mas comprada en 2012
ordenar por cantidad total comprada de mayor a menor
*/

-- 1 SQL
select row_number() over (order by sum(if1.item_cantidad) desc) as numero_de_fila,
	   c.clie_codigo as codigo,
	   c.clie_razon_social as nombre,
	   sum(if1.item_cantidad) as cantidad_comprada,
	   (
		select top 1 rubr_detalle from Item_Factura
		inner join Factura
			on fact_tipo = item_tipo 
    		and fact_sucursal = item_sucursal 
    		and fact_numero = item_numero
			and fact_cliente = c.clie_codigo -- sobre el mismo cliente de la consulta
		inner join Producto 
			on item_producto = prod_codigo
		inner join Rubro 
			on prod_rubro = rubr_id
		where year(fact_fecha) = 2012 
		group by prod_rubro, rubr_detalle
		order by sum(item_cantidad) desc
	   ) as rubro_mas_comprado
from Cliente c
inner join Factura f
	on f.fact_cliente = c.clie_codigo
inner join Item_Factura if1
	on if1.item_numero = f.fact_numero
	and if1.item_sucursal = f.fact_sucursal
	and if1.item_tipo = f.fact_tipo
inner join Producto p
	on p.prod_codigo = if1.item_producto
where year(f.fact_fecha) = 2012 and c.clie_codigo not in
    (
        -- que no est� dentro de compradores de a�os impares
        select distinct f2.fact_cliente from Factura f2
        where year(f2.fact_fecha) % 2 <> 0
    )
group by c.clie_codigo, c.clie_razon_social
having count(distinct p.prod_rubro) > 3 