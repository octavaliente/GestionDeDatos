-- 1
SELECT c.clie_codigo, c.clie_razon_social, c.clie_limite_credito
FROM Cliente c
WHERE c.clie_limite_credito >= 1000
ORDER BY c.clie_codigo DESC

--2
-- Solucion mia
SELECT p.prod_codigo, p.prod_detalle, sum(i.item_cantidad) as cantidad_vendida
FROM Producto p 
join Item_Factura i
ON i.item_producto = p.prod_codigo
join Factura f
ON i.item_numero = f.fact_numero
WHERE YEAR(f.fact_fecha) = 2012
group by p.prod_codigo, p.prod_detalle
order by cantidad_vendida desc

--Solucion otra
select 
	Producto.prod_codigo,
	Producto.prod_detalle,
	sum(Item_factura.item_Cantidad) as cantidad_vendida
from Producto
inner join Item_Factura 
	on Producto.prod_codigo = Item_Factura.item_producto
inner join Factura 
	on Item_Factura.item_tipo = Factura.fact_tipo
	and Item_Factura.item_sucursal = Factura.fact_sucursal 
	and Item_Factura.item_numero = Factura.fact_numero
where YEAR(Factura.fact_fecha) = 2012
group by prod_codigo,prod_detalle
order by cantidad_vendida desc

--Solucion analizando la ejecucion
SELECT Producto.prod_codigo,
	Producto.prod_detalle,
	SUM(item_cantidad)
FROM Producto
JOIN Item_Factura 
	ON Item_Factura.item_producto = Producto.prod_codigo
JOIN Factura 
	ON 	Factura.fact_numero = Item_Factura.item_numero 
		AND Factura.fact_tipo = Item_Factura.item_tipo
		AND Factura.fact_sucursal = Item_Factura.item_sucursal
GROUP BY
	Producto.prod_codigo, 
	Producto.prod_detalle,
	YEAR(Factura.fact_fecha)
HAVING 
	YEAR(Factura.fact_fecha) = 2012

-- 3
-- Left join para que me muestre los cero
SELECT p.prod_codigo, p.prod_detalle, isnull(sum(s.stoc_cantidad),0) as cantidad_stock
FROM STOCK s
left join Producto p 
ON p.prod_codigo = s.stoc_producto
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY p.prod_detalle asc

--4 
select p.prod_codigo, p.prod_detalle, sum(c.comp_cantidad) as cantidad_que_lo_componen
from Producto p 
left join Composicion c 
on p.prod_codigo = c.comp_producto
join STOCK s 
on s.stoc_producto = p.prod_codigo
GROUP BY p.prod_codigo, p.prod_detalle, s.stoc_deposito
having avg(s.stoc_cantidad) > 100

--5 subselect
select p.prod_codigo, p.prod_detalle, sum(i.item_cantidad) as cantidad_egresos
from producto p 
join Item_Factura i 
	on p.prod_codigo = i.item_producto
JOIN Factura f
	ON 	f.fact_numero = i.item_numero	
	AND f.fact_tipo = i.item_tipo
	AND f.fact_sucursal = i.item_sucursal
WHERE year(f.fact_fecha) = 2012
GROUP BY
	p.prod_codigo, 
	p.prod_detalle
HAVING sum(i.item_cantidad) > 
(
	SELECT sum(i2.item_cantidad)
	from Item_Factura i2
	join Factura f2
	ON 	f2.fact_numero = i2.item_numero	
	AND f2.fact_tipo = i2.item_tipo
	AND f2.fact_sucursal = i2.item_sucursal
	where year(f2.fact_fecha) = 2011
	and i2.item_producto = p.prod_codigo
)

--6 
select r.rubr_id, 
	   r.rubr_detalle, 
	   count(distinct p.prod_codigo) as cant_articulos,
	   sum(s.stoc_cantidad) as stock
from Rubro r
	join Producto p on r.rubr_id = p.prod_rubro
	join Stock s on s.stoc_producto = p.prod_codigo
where (select sum(s1.stoc_cantidad) from Stock s1 where s1.stoc_producto = p.prod_codigo) >
	  (select s2.stoc_cantidad from stock s2 where s2.stoc_producto = '00000000' and s2.stoc_deposito = '00')
group by r.rubr_id, r.rubr_detalle

--7
select p.prod_codigo, p.prod_detalle, max(i.item_precio) as maximo, min(i.item_precio) as minimo,
CAST(((max(i.item_precio) - min(i.item_precio)) / min(i.item_precio) * 100) as decimal(10,2))
from Producto p
join Item_Factura i 
on p.prod_codigo = i.item_producto
join Stock s
on p.prod_codigo = s.stoc_producto
group by p.prod_codigo, p.prod_detalle
having sum(s.stoc_cantidad) > 0

--8
select p.prod_detalle, max(s.stoc_cantidad) as 'stock maximo en deposito'
from Producto p
join Stock s on p.prod_codigo = s.stoc_producto
where s.stoc_cantidad >= 0
group by p.prod_codigo, p.prod_detalle
having COUNT(DISTINCT s.stoc_deposito) = (SELECT COUNT(*) FROM DEPOSITO)

--9 
select e.empl_codigo, e.empl_jefe, 
(select count(distinct d.depo_codigo) from DEPOSITO d where d.depo_encargado = e.empl_codigo) as depo_empleado,
(select count(distinct d.depo_codigo) from DEPOSITO d where d.depo_encargado = e.empl_jefe) as depo_jefe,
(select count(distinct d.depo_codigo) from DEPOSITO d where d.depo_encargado = e.empl_codigo) +
(select count(distinct d.depo_codigo) from DEPOSITO d where d.depo_encargado = e.empl_jefe) as Total
from Empleado e

--Otra solucion del 9
SELECT 
    e.empl_codigo AS codigo_empleado,
    e.empl_jefe AS codigo_jefe,
    COUNT(DISTINCT d1.depo_codigo) AS depo_empleado,
    COUNT(DISTINCT d2.depo_codigo) AS depo_jefe,
    COUNT(DISTINCT d1.depo_codigo) + COUNT(DISTINCT d2.depo_codigo) AS total_depositos
FROM 
    Empleado e
LEFT JOIN 
    DEPOSITO d1 ON e.empl_codigo = d1.depo_encargado
LEFT JOIN 
    DEPOSITO d2 ON e.empl_jefe = d2.depo_encargado
GROUP BY 
    e.empl_codigo, e.empl_jefe;

--10
/*
10. Mostrar los 10 productos más vendidos en la historia y 
también los 10 productos menos vendidos en la historia. 
Además mostrar de esos productos, quien fue el cliente que mayor compra realizo.
*/
select p.prod_codigo, p.prod_detalle,
	(
	select top 1 f.fact_cliente
	from Item_Factura if1
	join Factura f on f.fact_numero = if1.item_numero and
							 f.fact_sucursal = if1.item_sucursal and
							 f.fact_tipo = if1.item_tipo
	where if1.item_producto = p.prod_codigo
	group by f.fact_cliente
	order by sum(if1.item_cantidad) desc
	) as 'Mejor Cliente'
from Producto p
where p.prod_codigo in 
	 (select top 10 if2.item_producto 
	 from Item_Factura if2
	 group by if2.item_producto
	 order by sum(if2.item_cantidad) desc)
or p.prod_codigo in 
	 (select top 10 if3.item_producto 
	 from Item_Factura if3
	 group by if3.item_producto
	 order by sum(if3.item_cantidad) asc)

--Otra solucion

select case when productos_mas_vendidos.item_producto is null THEN productos_menos_vendidos.item_producto ELSE productos_mas_vendidos.item_producto END as id_producto,
    case when productos_mas_vendidos.item_producto is null THEN productos_menos_vendidos.cantidad_vendida ELSE productos_mas_vendidos.cantidad_vendida END as cantidad_vendida from (select top 10 item_producto, sum(item_cantidad) as cantidad_vendida 
    from Item_Factura if2
group by item_producto 
order by sum(item_cantidad) desc ) as productos_mas_vendidos
full outer join (select top 10 item_producto, sum(item_cantidad) as cantidad_vendida from Item_Factura if2
group by item_producto 
order by sum(item_cantidad) asc) as productos_menos_vendidos on productos_menos_vendidos.item_producto = productos_mas_vendidos.item_producto
order by case when productos_mas_vendidos.item_producto is null THEN productos_menos_vendidos.cantidad_vendida ELSE productos_mas_vendidos.cantidad_vendida END DESC;

SELECT 
	p.prod_codigo,
	(
	SELECT TOP 1 
		fact_cliente 
	FROM Factura f2 join Item_Factura if2 
		on
			f2.fact_numero = if2.item_numero and 
			f2.fact_sucursal = if2.item_sucursal and 
			f2.fact_tipo = if2.item_tipo 
	where 
		item_producto = p.prod_codigo
	group by 
		fact_cliente
	order by 
		sum(if2.item_cantidad) DESC 
	)
FROM Producto p
WHERE 
	p.prod_codigo in   
				(
				SELECT TOP 10 
					item_producto
				FROM Item_Factura it1
				GROUP BY 
					item_producto
				ORDER BY 
					SUM(it1.item_cantidad) DESC
				)
OR	 p.prod_codigo in  (
				SELECT TOP 10 
					item_producto
				FROM Item_Factura it1
				GROUP BY 
					item_producto
				ORDER BY 
					SUM(it1.item_cantidad) ASC
				)

-- El OR es para una coleccion de datos. Mostrame los 10 mas vendidos o los 10 menos vendidos para p.prod_codigo

--11
select fami_detalle, count(distinct item_producto) as prod_dif_vendidos, sum(item_cantidad * item_precio) as total_sin_impuestos
from Familia
join Producto on fami_id = prod_familia
join Item_Factura on prod_codigo = item_producto
group by fami_id, fami_detalle
having (
select sum(item_cantidad * item_precio) 
from Producto
join Item_Factura on prod_codigo = item_producto
join Factura on item_numero + item_tipo + item_sucursal = 
fact_numero + fact_tipo + fact_sucursal
where year(fact_fecha) = 2012 and prod_familia = fami_id
)> 20000
order by 2 desc

--12
/*
Mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe 
promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del 
producto y stock actual del producto en todos los depósitos. Se deberán mostrar 
aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán 
ordenarse de mayor a menor por monto vendido del producto.
*/
select prod_detalle, 
	count(distinct fact_cliente) as 'Compradores diferentes',
	avg(item_precio) as 'Precio promedio',
	ISNULL((SELECT COUNT(DISTINCT stoc_deposito) 
	FROM STOCK
	WHERE stoc_producto = prod_codigo 
	AND stoc_cantidad > 0
	GROUP BY stoc_producto), 0) AS 'Depositos con stock',
	ISNULL((SELECT SUM(stoc_cantidad)
	FROM STOCK
	WHERE stoc_producto = prod_codigo
	GROUP BY stoc_producto), 0) AS 'Stock total actual'
from Producto 
join Item_Factura on prod_codigo = item_producto
join Factura on item_numero + item_tipo + item_sucursal = 
fact_numero + fact_tipo + fact_sucursal
join Stock on stoc_producto = prod_codigo
where exists (
select item_producto from
Item_Factura
join Factura on item_numero + item_tipo + item_sucursal = 
fact_numero + fact_tipo + fact_sucursal
where year(fact_fecha) = 2012 and item_producto = prod_codigo
)
group by prod_codigo, prod_detalle

/*
La función ISNULL () acepta dos argumentos:

expression es una expresión de cualquier tipo que se comprueba para NULL.
replacement es el valor que se devolverá si la expresión es NULL. El reemplazo debe ser convertible a un valor del tipo de expresión.
*/

-- 13 guia
/*
Realizar una consulta que retorne para cada producto que posea composición nombre 
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad 
de los productos que lo componen. Solo se deberán mostrar los productos que estén 
compuestos por más de 2 productos y deben ser ordenados de mayor a menor por 
cantidad de productos que lo componen.
*/
select p.prod_codigo,
	   p.prod_detalle,
	   sum(comp.comp_cantidad * p1.prod_precio) as precio_por_cantidad
from Producto p
inner join Composicion comp
	on comp.comp_producto = p.prod_codigo
inner join Producto p1
	on comp.comp_componente = p1.prod_codigo
group by p.prod_codigo, p.prod_detalle
having count(distinct comp.comp_componente) >= 2
order by count(distinct comp.comp_componente) desc


