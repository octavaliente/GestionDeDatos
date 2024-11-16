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
si se guardan en la factura 2 hamb 2 papas 2 gaseosas se deberá guardar en la factura 2 (DOS) combo 1. Si 1 combo1 equivale a 1 hamb 1 papa 1 gaseosa
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
Realizar una consulta sql que devuelva todos los clientes que durante 2 años consecutivos compraron al menos 5 productos distintos
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

sp que tenga un cursor para recorrer los clientes
por cada provincia de cliente, si es la primera vez que ingresa el nombre hace un insert
y si el nombre ya está, se trae el valor del id
al cliente le agrego el pcia_id
a la tabla provincia le agrego campos a medida que recorro clientes
*/
/*
create table provincia (id int primary key, nombre char(100))
go

create procedure sp_parcial23
as
begin transaction
	declare @nombre_provincia char(100)
	declare cursor_23 cursor for

		from Cliente

commit

select * from Cliente
*/

-- Parcial 2021
-- SQL
/*
1.  Armar una consulta Sql que retorne:

    - Razón social del cliente
    - Límite de crédito del cliente
    - Producto más comprado en la historia (en unidades)

    Solamente deberá mostrar aquellos clientes que tuvieron mayor cantidad de ventas en el 2012 que
    en el 2011 en cantidades y cuyos montos de ventas en dichos años sean un 30 % mayor el 2012 con
    respecto al 2011. El resultado deberá ser ordenado por código de cliente ascendente

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
2.  Realizar un stored procedure que reciba un código de producto y una fecha y devuelva la mayor cantidad de
    días consecutivos a partir de esa fecha que el producto tuvo al menos la venta de una unidad en el día, el
    sistema de ventas on line está habilitado 24-7 por lo que se deben evaluar todos los días incluyendo domingos y feriados.
*/

-- Parcial 2023 07 08
/*Se pide que realice un reporte generado por una sola query que de cortes de informacion por periodos
(anual,semestral y bimestral).
Un corte por el año, un corte por el semestre el año y un corte por bimestre el año. 
En el corte por año mostrar: 
las ventas totales realizadas por año 
la cantidad de rubros distintos comprados por año
la cantidad de productos con composicion distintos comporados por año 
la cantidad de clientes que compraron por año.
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

COUNT(f1.fact_cliente) AS 'Clientes del año'

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

COUNT(f1.fact_cliente) AS 'Clientes del año'

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

COUNT(f1.fact_cliente) AS 'Clientes del año'

FROM Factura f1
GROUP BY YEAR(f1.fact_fecha), (FLOOR((MONTH(f1.fact_fecha)-1)/2) + 1)


-- Parciales de clase de repaso
/* Ej parcial 2024
1. Sabiendo que un producto recurrente es aquel producto que al menos
se compró durante 6 meses en el último año.
Realizar una consulta SQL que muestre los clientes que tengan
productos recurrentes y de estos clientes mostrar:

i. El código de cliente.
ii. El nombre del producto más comprado del cliente.
iii. La cantidad comprada total del cliente en el último año.

Ordenar el resultado por el nombre del cliente alfabéticamente.
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
1. Implementar una restricción que no deje realizar operaciones masivas
sobre la tabla cliente. 
En caso de que esto se intente se deberá registrar que operación se intentó realizar , en que fecha y hora y sobre
que datos se trató de realizar.
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

-- juaun 
CREATE TABLE cliente_operaciones_masivas_rechazadas(
clie_codigo char(6) primary key,
clie_razon_social char(100),
clie_telefono char(100),
clie_domicilio char(100),
clie_limite_credito decimal(12,2),
clie_vendedor numeric(6),
fecha_hora datetime,
operacion varchar(20)
)
GO

create trigger tr_procesos_masivos_cliente
on cliente
INSTEAD OF UPDATE, DELETE, INSERT
as 
begin
declare @insertados int
declare @borrados int
declare @actualizados int

if((select count(*) from inserted) > 0 and (select count(*) from deleted) > 0)
set @actualizados = (select count(*) from inserted)

if (select count(*) from inserted) > 0 and (select count(*) from deleted) = 0
set @insertados = (select count(*) from inserted)

if (select count(*) from deleted) > 0 and (select count(*) from inserted) = 0
set @borrados = (select count(*) from deleted)

if @actualizados > 1
begin 
insert into cliente_operaciones_masivas_rechazadas
select *, getdate(), 'UPDATE' from deleted

end
else
begin 
if @actualizados is not null
UPDATE c SET c.clie_codigo = i.clie_codigo
, c.clie_domicilio = i.clie_domicilio
, c.clie_limite_credito = i.clie_limite_credito
, c.clie_razon_social = i.clie_razon_social
, c.clie_telefono = i.clie_telefono
, c.clie_vendedor = i.clie_vendedor 
FROM Cliente c 
INNER JOIN inserted i ON c.clie_codigo = i.clie_codigo 
end

if @insertados > 1
begin
insert into cliente_operaciones_masivas_rechazadas
select *, getdate(), 'INSERT' from inserted
end
else
begin
if @insertados is not null
insert into cliente select * from cliente
end

if @borrados > 1 
begin 
insert into cliente_operaciones_masivas_rechazadas
select *, getdate(), 'DELETE' from deleted

end
else
begin
if @borrados is not null
delete from cliente where clie_codigo = (select clie_codigo from deleted)


end
end


/* Ej parcial
Realizar una consulta SQL que muestre aquellos productos que tengan
entre 2 y 4 componentes distintos a nivel producto y cuyos
componentes no fueron todos vendidos (todos) en 2012 pero si en el
2011.
De estos productos mostrar:
i. El código de producto.
ii. El nombre del producto.
iii. El precio máximo al que se vendió en 2011 el producto.
El resultado deberá ser ordenado por cantidad de unidades vendidas
del producto en el 2011.
resolucion: 
productos que tengan entre 2 y 4 componentes,
*/
select c.comp_producto as cod_prod,
	   p.prod_detalle as prod_detalle,
	   (select max(item_precio) from Item_Factura
	    inner join Factura
			on item_sucursal = fact_sucursal
			and item_tipo = fact_tipo
			and item_numero = fact_numero
			and year(fact_fecha) = 2011
		where item_producto = c.comp_producto) as precio_maximo
	   from Producto p
inner join Composicion c
	on p.prod_codigo = c.comp_producto
inner join Item_Factura
	on item_producto = p.prod_codigo
inner join Factura 
	on item_sucursal = fact_sucursal
	and item_tipo = fact_tipo
	and item_numero = fact_numero
where year(fact_fecha) = 2011
group by c.comp_producto, p.prod_detalle
having count(distinct c.comp_componente) between 2 and 4
	and (select count(distinct item_producto) from Item_Factura
		 INNER JOIN Factura 
			on item_numero = fact_numero
			and item_sucursal = fact_sucursal
			and item_tipo = fact_tipo
		 where year(fact_fecha) = 2012 
		 and item_producto in 
			(select comp_componente 
			 from Composicion 
			 where comp_producto = c.comp_producto)
		) < count(distinct c.comp_componente)
	and (select count(distinct item_producto) from Item_Factura
		 INNER JOIN Factura 
			on item_numero = fact_numero
			and item_sucursal = fact_sucursal
			and item_tipo = fact_tipo
		 where year(fact_fecha) = 2011 
		 and item_producto in 
			(select comp_componente 
			 from Composicion 
			 where comp_producto = c.comp_producto)
		) = count(distinct c.comp_componente)
order by sum(item_cantidad) desc

select p.prod_codigo, p.prod_detalle, count(distinct comp.comp_componente) from Producto p
inner join Composicion comp
	on p.prod_codigo = comp_producto
group by p.prod_codigo, p.prod_detalle
having count(distinct comp.comp_componente) between 2 and 4
go

select p.prod_codigo,
	   p.prod_detalle,
	   (
	   select max(if2.item_precio) 
	   from Item_Factura if2
	   inner join Factura f2
		on f2.fact_numero = if2.item_numero
		and f2.fact_sucursal = if2.item_sucursal
		and f2.fact_tipo = if2.item_tipo
	   where if2.item_producto = p.prod_codigo and year(f2.fact_fecha) = 2011
	   )
from Producto p
inner join Composicion comp
	on p.prod_codigo = comp.comp_producto
left join Producto p2
	on p2.prod_codigo = comp.comp_componente
inner join Item_Factura if1
	on if1.item_producto = p2.prod_codigo
inner join Factura f
	on f.fact_tipo = if1.item_tipo 
    AND f.fact_sucursal = if1.item_sucursal 
    AND f.fact_numero = if1.item_numero
where YEAR(f.fact_fecha) != 2012 AND YEAR(f.fact_fecha) = 2011
group by p.prod_codigo, p.prod_detalle
having count(distinct comp.comp_componente) between 2 and 4