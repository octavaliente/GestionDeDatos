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

-- Clase de repaso
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

-- SQL 2024 
/*
realizar una consulta sql que muestre la siguiente informacion para los clientes que hayan comprado productos en mas de tres rubros dif en el 2012
y que no compro en años impares
- numero de fila
- codigo cliente
- nombre cliente
- cantidad total comprada en 2012
- categoria mas comprada en 2012
ordenar por cantidad total comprada de mayor a menor
*/
-- Solucion de otro 
-- 10

SELECT
    ROW_NUMBER() over (ORDER BY SUM(if1.item_cantidad) DESC) as numero_fila,
    c1.clie_codigo as codigo_cliente,
    c1.clie_razon_social as nombre_cliente,

    SUM(if1.item_cantidad) as cantidad_total_comprada,

    (
        SELECT TOP 1
            r1.rubr_detalle     -- Categoria más comprada (agarre el detalle pero también podría haber agarrado el id)
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

        ) > 3       -- Compro en más de 3 rubros diferentes en el 2012
        AND
        NOT EXISTS( SELECT                      -- No existe una factura de ese cliente que haya sido emitida en un año impar (o sea, todas las compras fueron en años pares)
                        1
                    FROM Factura f3
                    WHERE f3.fact_cliente = c1.clie_codigo AND YEAR(f3.fact_fecha) % 2 != 0)

ORDER BY SUM(if1.item_cantidad) DESC

-- yo
-- 6, esta corregido no es exactamente lo que mandé
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
        -- que no esté dentro de compradores de años impares
        select distinct f2.fact_cliente from Factura f2
        where year(f2.fact_fecha) % 2 <> 0
    )
group by c.clie_codigo, c.clie_razon_social
having count(distinct p.prod_rubro) > 3 