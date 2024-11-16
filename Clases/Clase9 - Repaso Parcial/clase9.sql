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

--yo

select f.fact_cliente,
	   (
	   select top 1 prod_detalle from Item_Factura if2
	   inner join Factura f2
	   on if2.item_numero + if2.item_sucursal + if2.item_tipo = 
			f2.fact_numero + f2.fact_sucursal + f2.fact_tipo
	   inner join Producto
			on prod_codigo = item_producto
	   where f2.fact_cliente = f.fact_cliente and year(f2.fact_fecha) = 2024
	   group by fact_cliente,prod_detalle
	   having count(distinct month(fact_fecha)) >= 6
	   order by sum(item_cantidad) asc
	   ) as 'prod mas comprado',
	   sum(if1.item_cantidad) as 'cantidad comprada'
from Item_Factura if1
inner join Factura f
	on if1.item_numero + if1.item_sucursal + if1.item_tipo = 
		f.fact_numero + f.fact_sucursal + f.fact_tipo
where year(fact_fecha) = 2012
group by fact_cliente
having count(distinct month(fact_fecha)) >= 6

--juan

select clie_codigo,
	(select top 1 item_producto
	from Item_Factura items2
	inner join Factura f2 on item_tipo = fact_tipo and item_sucursal = fact_sucursal and item_numero = fact_numero
	where f2.fact_cliente = clie_codigo
		and f2.fact_fecha >= dateadd(year, -1, getdate())
	group by item_producto
	having count(distinct month(f2.fact_fecha)) >=6
	order by sum(item_cantidad) desc
	) as 'producto mas comprado',
	sum(items1.item_cantidad) as 'cantidad comprada'
from cliente 
inner join factura f on fact_cliente = clie_codigo and fact_fecha >= dateadd(year, -1, getdate())
inner join Item_Factura items1 on item_tipo = fact_tipo and item_sucursal = fact_sucursal and item_numero = fact_numero
group by clie_codigo
having count(distinct month(fact_fecha)) >=6

-- Otra solucion

SELECT 
    c.clie_codigo AS codigo_del_cliente,
    c.clie_razon_social AS nombre,
    (SELECT TOP 1 
      p.prod_detalle 
     FROM Factura f2
  JOIN item_factura ifact2 ON f2.fact_tipo = ifact2.item_tipo 
      AND f2.fact_sucursal = ifact2.item_sucursal 
      AND f2.fact_numero = ifact2.item_numero
  JOIN producto p ON p.prod_codigo = ifact2.item_producto 
   WHERE  
    f2.fact_cliente = c.clie_codigo
   GROUP BY 
    ifact2.item_producto , p.prod_detalle 
   ORDER BY  
    sum(ifact2.item_cantidad) desc
    ),
    SUM(ifact.item_cantidad) AS cantidad
FROM Factura f
JOIN cliente c ON f.fact_cliente = c.clie_codigo
JOIN item_factura ifact ON f.fact_tipo = ifact.item_tipo 
    AND f.fact_sucursal = ifact.item_sucursal 
    AND f.fact_numero = ifact.item_numero
JOIN producto p ON ifact.item_producto = p.prod_codigo
WHERE 
 YEAR(f.fact_fecha) = 2012  
  GROUP BY 
   c.clie_codigo,
   c.clie_razon_social 
HAVING 
 COUNT(DISTINCT MONTH(f.fact_fecha)) >= 6

-- Otra solucion
select 
  c.clie_codigo, 
  (select top 1 p.prod_detalle
   from item_factura if2 
   inner join Factura f2
   on f2.fact_cliente = c.clie_codigo and f2.fact_tipo = if2.item_tipo and f2.fact_sucursal = if2.item_sucursal and f2.fact_numero = if2.item_numero 
   inner join Producto p
   on p.prod_codigo = if2.item_producto
   group by p.prod_detalle
   order by sum(if2.item_cantidad) DESC) as prod_mas_comprado,
(select sum(if1.item_cantidad)) as cantidad_comprada_total_del_cliente
from Factura f 
inner join Item_Factura if1
on f.fact_tipo = if1.item_tipo and f.fact_sucursal = if1.item_sucursal and f.fact_numero = if1.item_numero 
inner join Cliente c
on f.fact_cliente = c.clie_codigo 
where YEAR(f.fact_fecha) in (2011) -- para que hayan datos
group by c.clie_codigo, c.clie_razon_social
HAVING (count(DISTINCT if1.item_producto) * count(DISTINCT MONTH(f.fact_fecha))) >= 6
order by c.clie_razon_social ASC;
go
-- Ejercicio 2 
/*
1. Implementar una restricción que no deje realizar operaciones masivas
sobre la tabla cliente. En caso de que esto se intente se deberá
registrar que operación se intentó realizar , en que fecha y hora y sobre
que datos se trató de realizar.
*/

create table op_masivas (operacion varchar(50), fecha timestamp, campos int);
go;

create trigger tr_parcial24
on Cliente instead of insert
as
begin
begin transaction
	if (select count(*) from inserted) > 1 
	begin 
		insert into op_masivas (operacion, fecha, campos)
		select 'insert', 
				CURRENT_TIMESTAMP,
				@@ROWCOUNT from inserted
		rollback transaction
	end
	else
	begin
		insert into Cliente
		select * from inserted
		commit transaction
	end
end
go
create table op_masivas (operacion varchar(50), fecha timestamp, campos int);
go;

create trigger tr_parcial24
on Cliente instead of insert, delete, update
as
begin
begin transaction

	declare @operacion VARCHAR(50)
	declare @campos INT

	if (select count(*) from inserted) > 1 and (select count(*) from deleted) > 1
	begin 
		set @operacion = 'UPDATE'
		set @campos =  (select count(*) from inserted)
	end
	else if (select count(*) from inserted) > 1
	begin 
		set @operacion = 'INSERT'
		set @campos =  (select count(*) from inserted)
	end
	else if (select count(*) from deleted) > 1
	begin
		set @operacion = 'DELETE'
		set @campos =  (select count(*) from deleted)
	end
	else if  (select count(*) from inserted) = 1
	begin
		insert into Cliente
		select * from inserted
		commit transaction
	end
	else if  (select count(*) from deleted) = 1
	begin 
		delete from Cliente
		where clie_codigo in (select clie_codigo from deleted)
		commit transaction
	end
	insert into op_masivas (operacion, fecha, campos)
		select @operacion, 
				CURRENT_TIMESTAMP,
				@campos
	commit transaction
end

--Otra solucion 

ALTER trigger trigger_before_ops_on_cliente
ON cliente
INSTEAD OF DELETE, INSERT, UPDATE
AS 
BEGIN 
   BEGIN TRANSACTION
   
   declare @operation varchar(255)
   Declare @cantidad_a_deletear int 
   Declare @cantidad_a_insertar int 
   Declare @cantidad_a_updatear int 


   
    if ((select count(*) from inserted) >= 1 and (select count(*) from inserted) = (select count(*) from deleted))
     BEGIN
      select @cantidad_a_updatear = count(*) from inserted
      set @operation = 'UPDATE'
     END
    else if (select count(*) from inserted) >= 1
      BEGIN
       select @cantidad_a_updatear = count(*) from inserted
       set @operation = 'INSERT'
      END
    else 
     BEGIN
      if (select count(*) from deleted) >= 1
      BEGIN
       select @cantidad_a_deletear = count(*) from deleted
       set @operation = 'DELETE'
      END
     END
if @cantidad_a_deletear > 1 or @cantidad_a_insertar > 1 or @cantidad_a_updatear > 1
       BEGIN
        Declare @codigo varchar(255)
        Declare @razon_social varchar(255)
     
        DECLARE mi_cursor_ops CURSOR FOR 
         SELECT clie_codigo, clie_razon_social from deleted
        
        OPEN mi_cursor_ops
        FETCH mi_cursor_ops INTO 
           @codigo,
           @razon_social
		WHILE @@FETCH_STATUS = 0 
        BEGIN
            print('Realizacion de ' + @operation + ' invalido sobre tabla cliente at ' + CAST(GETDATE() AS NVARCHAR) + ' codigo: ' + @codigo + ' raz_soc: ' + @razon_social);
            insert into operation (operacion, clie_codigo, clie_razon_social, fecha)
            values (@operation, @codigo, @razon_social, GETDATE());
            FETCH mi_cursor_ops INTO 
            @codigo,
            @razon_social
        END
        CLOSE mi_cursor_ops
        DEALLOCATE mi_cursor_ops
        ROLLBACK TRANSACTION
        RETURN
       END
 
 if @operation = 'INSERT'
  BEGIN
   INSERT INTO Cliente (clie_codigo, clie_razon_social, clie_telefono, clie_domicilio, clie_limite_credito, clie_vendedor)
      SELECT * FROM INSERTED
      COMMIT TRANSACTION
  END
 
 if @operation = 'DELETE'
  BEGIN
   DELETE FROM Cliente where clie_codigo = (select clie_codigo from DELETED)
      COMMIT TRANSACTION
  END
if @operation = 'UPDATE'
  BEGIN
   
   UPDATE Cliente 
      SET clie_codigo = (select clie_codigo from inserted),
      clie_razon_social = (select clie_razon_social from inserted),
      clie_telefono = (select clie_telefono from inserted),
      clie_domicilio = (select clie_domicilio from inserted),
      clie_limite_credito = (select clie_limite_credito from inserted),
      clie_vendedor = (select clie_vendedor from inserted)
      COMMIT TRANSACTION
     END 
   COMMIT TRANSACTION
END;

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

--otra solucion

select p.prod_codigo,
	   p.prod_detalle, 
	   isnull(
	   (
		select max(if2.item_precio) from Item_Factura if2
		inner join Factura f
		on if2.item_tipo = f.fact_tipo and if2.item_sucursal = f.fact_sucursal and if2.item_numero = f.fact_numero 
		where if2.item_producto = p.prod_codigo
		AND YEAR(f.fact_fecha) = 2011
		),0) as precio_maximo_en_2011
from Producto p 
inner join Composicion c 
	on c.comp_producto = p.prod_codigo 
group by p.prod_codigo, p.prod_detalle
having 
	(select count (distinct comp_componente)) between 2 and 4 
	AND
	(select count(distinct c2.comp_componente) from Composicion c2
	inner join Item_Factura if2 
		on if2.item_producto = c2.comp_componente 
	inner join Factura f 
		on if2.item_tipo = f.fact_tipo and if2.item_sucursal = f.fact_sucursal and if2.item_numero = f.fact_numero 
	where YEAR(f.fact_fecha) = 2012 AND c2.comp_producto = p.prod_codigo) <> (select count (distinct comp_componente)
	)
	AND
	(select count(distinct c2.comp_componente) from Composicion c2
	inner join Item_Factura if2 
		on if2.item_producto = c2.comp_componente 
	inner join Factura f 
		on if2.item_tipo = f.fact_tipo and if2.item_sucursal = f.fact_sucursal and if2.item_numero = f.fact_numero 
	where YEAR(f.fact_fecha) = 2011
		AND c2.comp_producto = p.prod_codigo) = (select count (distinct comp_componente)
	)
order by (select sum(if2.item_cantidad)
from Item_Factura if2
	inner join Factura f 
on if2.item_tipo = f.fact_tipo and if2.item_sucursal = f.fact_sucursal and if2.item_numero = f.fact_numero 
where if2.item_producto = p.prod_codigo and YEAR(f.fact_fecha) = 2011) DESC