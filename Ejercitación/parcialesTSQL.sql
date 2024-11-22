-- Parciales TSQL
-- 2021
-- T-SQL
/*
2.  Realizar un stored procedure que reciba un código de producto y una fecha y devuelva la mayor cantidad de
    días consecutivos a partir de esa fecha que el producto tuvo al menos la venta de una unidad en el día, el
    sistema de ventas on line está habilitado 24-7 por lo que se deben evaluar todos los días incluyendo domingos y feriados.
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
go
-- Martes 2022 sql
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
go 

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
go
-- Sabado 2022
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

-- Recu 2022 sabado
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

-- Clase repaso 
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
go

-- Parcial 2024 
-- Parcial 2024
-- 2 TSQL
/*
Implementar los objetos necesarios para registrar, en tiempo real, los 10 productos mas vendidos por año en una tabla especifica.
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
recorrer un select top 10 por año
todos los años posibles
*/
create procedure top_ventas
as 
begin
	declare @cod_prod char(8)
	declare @anio int

    -- años diferentes
    declare cursor_anios cursor FOR
    select distinct cast(year(fact_fecha) as int) from Factura
    open cursor_anios 
    fetch next from cursor_anios INTO @anio

    while @@FETCH_STATUS = 0
    BEGIN
        --inserto los 10 mas vendidos en los diferentes años

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