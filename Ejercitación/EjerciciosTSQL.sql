-- Ejercicios TSQL
--1 
create function dbo.fn_ej_1 (@cod_articulo char(8), @cod_depo char(2))
returns nvarchar(100)
as 
begin
	declare @cantidad_almacenada decimal(12,2)
	declare @cantidad_maxima decimal(12,2)
	declare @resultado nvarchar(100)
	select @cantidad_almacenada = stoc_cantidad, @cantidad_maxima = stoc_stock_maximo
	from STOCK
	where @cod_articulo = stoc_producto and @cod_depo = stoc_deposito
	if @cantidad_almacenada >= @cantidad_maxima
	begin 
		set @resultado = 'DEPOSITO COMPLETO'
	end 
	else 
	begin
		declare @porcentaje_ocupacion INT
		set @porcentaje_ocupacion = (@cantidad_almacenada * 100) / @cantidad_maxima;
		set @resultado = 'OCUPACION DEL DEPOSITO ' + cast(@porcentaje_ocupacion as nvarchar(3)) + '%'
	end

	return @resultado
end

select dbo.fn_ej_1('00000030','00')

--2
/*
Realizar una función que dado un artículo y una fecha, retorne el stock que 
existía a esa fecha
Solucion: Hacer un recuento de la cantidad vendida de ese articulo hasta la fecha de hoy y sumarlo al stock actual.
*/
alter function dbo.fn_ej2 (@cod_articulo char(8), @fecha smalldatetime)
returns int
as
begin
	declare @resultado int
	declare @cantidad_vendido decimal(12,2)
	declare @stock_actual decimal(12,2)

	select @cantidad_vendido = isnull(sum(item_cantidad),0) from Item_Factura
	join Factura on 
		fact_tipo + fact_sucursal + fact_numero = 
		item_tipo + item_sucursal + item_numero
	where fact_fecha <= @fecha 
		and @cod_articulo = item_producto
	
	select @stock_actual = isnull(stoc_cantidad,0) from STOCK
	where @cod_articulo = stoc_producto

	set @resultado = @stock_actual - @cantidad_vendido
	return @resultado
end

select dbo.fn_ej2('00000030', convert(DATETIME,'03-30-2017', 120))

--ej 3
/*
Cree el/los objetos de base de datos necesarios para corregir la tabla empleado 
en caso que sea necesario. Se sabe que debería existir un único gerente general 
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado 
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por 
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la 
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla 
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad 
de empleados que había sin jefe antes de la ejecución
Solucion: Recorrer la tabla de empleados, obtener todos los que no tienen jefe y guardar la cantidad para hacer el return.
Si hay uno solo no hago nada, si hay mas de uno filtro por mayor salario y por ultimo por antiguedad.
Al resto le asigno un jefe, el gerente general.
*/

CREATE PROCEDURE dbo.sp_ej3
AS
BEGIN
    DECLARE @resultado INT = 0;
    DECLARE @cod_gerente_general NUMERIC(6);
    DECLARE @max_salario DECIMAL(12, 2)
    DECLARE @cod_jefe NUMERIC(6);

    SELECT @resultado = COUNT(*)
    FROM Empleado
    WHERE empl_jefe IS NULL;

    IF @resultado > 1
    BEGIN
        SELECT TOP 1 @cod_gerente_general = empl_codigo
        FROM Empleado
        WHERE empl_jefe IS NULL
        ORDER BY empl_salario DESC, empl_ingreso ASC;

        UPDATE Empleado
        SET empl_jefe = @cod_gerente_general
        WHERE empl_jefe IS NULL
        AND empl_codigo != @cod_gerente_general;
    END

    RETURN @resultado;
END;

--Test
DECLARE @resultado INT;
EXEC @resultado = dbo.sp_ej3;
SELECT @resultado AS EmpleadosSinJefeAntes;

--Ej 4
/*
Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor 
que más vendió (en monto) a lo largo del último año
solucion: De Fact Total saco el total vendido, hay que hacerle un sum agrupando por fact vendedor.
recorro toda la tabla de empleados y para cada empl_codigo hago el sum y update en el year 2024
luego de todo los update con un select top 1 me alcanza 
*/

alter procedure dbo.sp_ej4_b 
as 
begin
	declare @cod numeric(6)
	
	declare cursor_ej4 cursor for
		select empl_codigo
		from Empleado
	open cursor_ej4
	
	fetch cursor_ej4 into @cod
	while @@FETCH_STATUS = 0
	begin
		declare @total_vendido decimal(12,2)
		select @total_vendido = isnull(SUM(fact_total),0)
		from Factura
		where fact_vendedor = @cod and year(fact_fecha) = 2024
		
		update Empleado set empl_comision = @total_vendido 
			where empl_codigo = @cod
		
		fetch cursor_ej4 into @cod
	end
	
	close cursor_ej4
	deallocate cursor_ej4 

	select top 1 empl_codigo
	from Empleado
	order by empl_comision desc
	
end

EXEC dbo.sp_ej4_b;

--Ej 5
/*
Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)
*/

/*
Solucion: de factura sale anio, mes y cliente, de producto sale rubro y familia, cantidad y monto de item factura
zona sale de fact vendedor y empleado depa y emple zona
*/

Create table Fact_table_ej5
(	
	anio char(4) NOT NULL,
	mes char(2) NOT NULL,
	familia char(3) NOT NULL,
	rubro char(4) NOT NULL,
	zona char(3) NOT NULL,
	cliente char(6) NOT NULL,
	producto char(8) NOT NULL,
	cantidad decimal(12,2),
	monto decimal(12,2)
)

Alter table Fact_table_ej5
Add constraint pk_fact primary key(anio,mes,familia,rubro,zona,cliente,producto)

alter procedure dbo.sp_ej5
as
begin

	delete Fact_table_ej5

	insert into dbo.Fact_table_ej5 (anio, mes, familia, rubro, zona, cliente, producto, cantidad, monto)
	select CAST(YEAR(fact.fact_fecha) AS CHAR(4)), CAST(MONTH(fact.fact_fecha) AS CHAR(2)), p.prod_familia, p.prod_rubro, depa.depa_zona, fact.fact_cliente, if1.item_producto, sum(if1.item_cantidad), sum(if1.item_precio * if1.item_cantidad)
	from Item_Factura if1
	inner join Factura fact
		on fact.fact_tipo + fact.fact_sucursal + fact.fact_numero = 
		   if1.item_tipo + if1.item_sucursal + if1.item_numero
	inner join Producto p 
		on p.prod_codigo = if1.item_producto
	inner join Empleado
		on empl_codigo = fact.fact_vendedor
	inner join Departamento depa
		on empl_departamento = depa.depa_codigo
	group by YEAR(fact.fact_fecha), MONTH(fact.fact_fecha), p.prod_familia, p.prod_rubro, depa.depa_zona, fact.fact_cliente, if1.item_producto
end

exec dbo.sp_ej5

select * from Fact_table_ej5

-- Ej 6
/*
Realizar un procedimiento que si en alguna factura se facturaron componentes 
que conforman un combo determinado (o sea que juntos componen otro 
producto de mayor nivel), en cuyo caso deberá reemplazar las filas 
correspondientes a dichos productos por una sola fila con el producto que 
componen con la cantidad de dicho producto que corresponda.
*/

create procedure ej_6
as
begin
	DECLARE @PRODUCTO CHAR(8)
	DECLARE @COMPONENTE CHAR(8)
	DECLARE @TIPO CHAR(1)
	DECLARE @SUCURSAL CHAR(4)
	DECLARE @NUMERO CHAR(8)
	DECLARE @CANTIDAD_VENDIDA DECIMAL(12,2)
	DECLARE @PRECIO_PRODUCTO DECIMAL(12,2)
	DECLARE @CANTIDAD_COMPONENTE DECIMAL(12,2)

	declare cursor_ej6 cursor for
		select item_tipo, item_sucursal, item_numero, item_cantidad, item_producto,
			   comp_cantidad, comp_producto, prod_precio
		from Item_Factura 
		join Composicion
			on item_producto = comp_componente
		join Producto
			on comp_producto = prod_codigo
			and item_cantidad % comp_cantidad = 0
	open cursor_ej6
	fetch next from cursor_ej6 into @TIPO, @SUCURSAL, @NUMERO, @CANTIDAD_VENDIDA, @COMPONENTE, @CANTIDAD_COMPONENTE, @PRODUCTO, @PRECIO_PRODUCTO
	
	while @@FETCH_STATUS = 0
	begin
		declare @cantidad DECIMAL(12,2)
		declare @componente2 char(8)

		set @cantidad = @CANTIDAD_VENDIDA / @CANTIDAD_COMPONENTE

		set @componente2 = 
		(
			select item_producto 
			from Item_Factura
			inner join Composicion
			on item_producto = comp_componente
			where item_tipo = @TIPO
			and item_sucursal = @SUCURSAL
			and item_numero = @NUMERO
			and item_producto <> @COMPONENTE
			and comp_producto = @PRODUCTO
			and item_cantidad % comp_cantidad = @CANTIDAD
		)
		if @COMPONENTE is not null and @componente2 is not null
		begin
			delete from Item_Factura
			where item_tipo = @TIPO
			and item_sucursal = @SUCURSAL
			and item_numero = @NUMERO
			and item_producto = @COMPONENTE 

			delete from Item_Factura
			where item_tipo = @TIPO
			and item_sucursal = @SUCURSAL
			and item_numero = @NUMERO
			and item_producto = @componente2

			insert into Item_Factura
			values (@TIPO, @SUCURSAL, @NUMERO, 
			@PRODUCTO, @CANTIDAD, @PRECIO_PRODUCTO)
	
	fetch next from cursor_ej6 into @TIPO, @SUCURSAL, @NUMERO, @CANTIDAD_VENDIDA, @COMPONENTE, @CANTIDAD_COMPONENTE, @PRODUCTO, @PRECIO_PRODUCTO

	end

	close cursor_ej6
	deallocate cursor_ej6
end
go;

-- EJ 7
/*
Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por 
las ventas entre esas fechas. La tabla se encuentra creada y vacía.
*/

CREATE TABLE ventas( 
	venta_codigo char(8),
	venta_detalle char(50),
	venta_movimientos INT,
	venta_precio DECIMAL(12,2),
	venta_renglon NUMERIC(6,0),
	venta_ganancia DECIMAL(12,2)
)
GO

create procedure ej7 (@fecha1 smalldatetime, @fecha2 smalldatetime)
as 
begin
	declare @codigo char(8)
	declare @detalle char(50)
	declare @movimientos int
	declare @precio_promedio decimal (12,2)
	declare @ganancia decimal (12,2)
	declare @renglon numeric(6,0) 

	declare cursor_ej7 cursor for
		select prod_codigo, prod_detalle, count(item_producto), avg(item_precio),
			sum(item_precio * item_cantidad) - sum(item_cantidad * prod_precio)
		from Item_Factura
		inner join Factura
			on item_numero = fact_numero
			and item_sucursal = fact_sucursal
			and item_tipo = fact_tipo
		inner join Producto 
			on prod_codigo = item_producto
		where fact_fecha between @fecha1 and @fecha2
		group by prod_codigo, prod_detalle

	open cursor_ej7
	fetch next from cursor_ej7 into @codigo, @detalle, @movimientos, @precio_promedio, @ganancia

	IF OBJECT_ID('VENTAS') IS NOT NULL
		SET @renglon = (SELECT MAX(@renglon) FROM VENTAS) + 1
	ELSE
		SET @renglon = 0

	while @@FETCH_STATUS = 0
	begin 
		insert into ventas
		(@codigo, @detalle, @movimientos, @precio_promedio, @renglon, @ganancia)
		set @renglon = @renglon + 1
		fetch next from cursor_ej7 into @codigo, @detalle, @movimientos, @precio_promedio, @ganancia	
	end
end
go

IF OBJECT_ID('VENTAS') IS NOT NULL
	DROP TABLE VENTAS
GO

--ej 8
/*
Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por 
cantidad de sus componentes, se aclara que un producto que compone a otro, 
también puede estar compuesto por otros y así sucesivamente, la tabla se debe 
crear y está formada por las siguientes columnas
*/

create table diferecia_precios
(
	articulo_cod char(8),
	articulo_detalle char(50),
	composicion_cant decimal(12,2),
	precio_total decimal(12,2),
	precio_facturado decimal(12,2)
)
go;

create function dbo.funcion_ej8 (@producto char(8))
returns decimal(12,2)
as 
begin
	declare @precio decimal(12,2)

	set @precio = 
	(
	select sum(dbo.funcion_ej8(comp_componente) * comp_cantidad)
	from Composicion 
	where @producto = comp_producto
	)

	if @precio = null
	begin
		set @precio = 
		(
			select prod_precio 
			from Producto
			where @producto = prod_codigo
		)
	end

	return @precio
end


create procedure dbo.ej8 
as 
begin
	insert into diferecia_precios
	select prod_codigo, 
	       prod_detalle,
		   count(distinct comp_componente),
		   dbo.funcion_ej8(comp_producto),
		   prod_precio
	from Item_Factura
	inner join Composicion
		on item_producto = comp_producto
	inner join Producto
		on comp_producto = prod_codigo
end
go

-- Ej 9
/*
Crear el/los objetos de base de datos que ante alguna modificación de un ítem de 
factura de un artículo con composición realice el movimiento de sus 
correspondientes componentes.
*/
create trigger tr_ej9
on Item_Factura
after update 
as 
begin transaction
	declare @producto char(8)
	set @producto = 
		(select item_producto 
		 from inserted)

	if @producto in (select 1 from Composicion where @producto = comp_producto)
	begin
		declare @componente char(8)
		declare @cantidad decimal (12,2)

		declare cursor_ej9 cursor for
			select comp_componente, comp_cantidad
			from Composicion
			where comp_producto = @producto
		for update of stoc_cantidad
		open cursor_ej9
		fetch cursor_ej9 into @componente, @cantidad
		while @@FETCH_STATUS = 0
		begin
			update STOCK 
			set stoc_cantidad = 
				stoc_cantidad - @cantidad * (select item_cantidad from inserted) 
				+ (select item_cantidad from deleted) * @cantidad
			where stoc_producto = @componente
		end
	end
commit
go
-- ej11
/*
Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que 
tengan un código mayor que su jefe directo

resolucion: 
crear una funcion que me calcule los empleados de un empl codigo. contarlo si tiene el empl_codigo > al empl_jefe
crear un procedure para correr recursivamente la funcion para cada empl_codigo
*/
alter function dbo.funcion_ej11 (@empleado numeric(6,0))
returns int
as 
begin
	declare @cantidad_a_cargo int
	declare @fecha_nacimiento_jefe smalldatetime

	set @fecha_nacimiento_jefe = (
		select empl_nacimiento
		from Empleado
		where @empleado = empl_codigo
	)

	set @cantidad_a_cargo = (
		select isnull(sum(dbo.funcion_ej11(empl_codigo) + 1),0)
		from Empleado
		where @empleado	= empl_jefe
		and empl_nacimiento > @fecha_nacimiento_jefe
	)

	if @cantidad_a_cargo is null 
	set @cantidad_a_cargo = 0

	return @cantidad_a_cargo
end
go

select dbo.funcion_ej11(3);
go;

--Ej 12
/*
Cree el/los objetos de base de datos necesarios para que nunca un producto 
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se 
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos 
y tecnologías. No se conoce la cantidad de niveles de composición existentes.
*/
CREATE FUNCTION dbo.Ejercicio12Func(@Componente char(8))
RETURNS BIT
AS
BEGIN
    DECLARE @ProdAux char(8)
    DECLARE @Resultado BIT = 0

    -- Si el producto ya es un componente directo de sí mismo
    IF EXISTS (
        SELECT 1
        FROM Composicion
        WHERE comp_producto = @Componente
          AND comp_componente = @Componente
    )
    BEGIN
        RETURN 1
    END

    -- Cursor para recorrer múltiples componentes
    DECLARE cursor_componente CURSOR FOR
        SELECT comp_componente
        FROM Composicion
        WHERE comp_producto = @Componente

    OPEN cursor_componente
    FETCH NEXT FROM cursor_componente INTO @ProdAux

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Llamada recursiva para verificar ciclos
        IF dbo.Ejercicio12Func(@ProdAux) = 1
        BEGIN
            SET @Resultado = 1
            BREAK
        END

        FETCH NEXT FROM cursor_componente INTO @ProdAux
    END

    CLOSE cursor_componente
    DEALLOCATE cursor_componente

    RETURN @Resultado
END
GO

CREATE TRIGGER Ejercicio12 ON Composicion
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE dbo.Ejercicio12Func(comp_componente) = 1
    )
    BEGIN
        PRINT 'Un producto no puede componerse a sí mismo ni ser parte de un producto que se compone a sí mismo.'
        ROLLBACK TRANSACTION
    END
END
GO

--ej 15
/*
Cree el/los objetos de base de datos necesarios para que el objeto principal 
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de 
los componentes del mismo multiplicado por sus respectivas cantidades. No se 
conocen los nivles de anidamiento posibles de los productos. Se asegura que 
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto 
principal debe poder ser utilizado como filtro en el where de una sentencia 
select.*/

--ej 31
/*
 Desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda 
tener más de 20 empleados a cargo, directa o indirectamente, si esto ocurre 
debera asignarsele un jefe que cumpla esa condición, si no existe un jefe para 
asignarle se le deberá colocar como jefe al gerente general que es aquel que no 
tiene jefe.
*/