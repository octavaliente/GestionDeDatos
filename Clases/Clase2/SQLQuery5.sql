/*
SELECT 
	clie_codigo CODIGO, 
	clie_codigo DOMI,
	1 + 1 as SUMA, -- No tiene logica, muestra un 2
	getdate() as FECHA_HORA,
	YEAR(GETDATE()),
	SUBSTRING('EDGARDO', 1, 3), -- No tiene logica, muestra un substring
	SUBSTRING ('clie_domicilio', 1, 5)
FROM CLIENTE


SELECT * FROM CLIENTE
WHERE --Expresion Booleana 
	clie_codigo = '00101' OR clie_codigo = '00102'

WHERE 
	clie_codigo BETWEEN '00101' AND '00110'
-- otras opciones >=, <=,AND 
*/

-- El WHERE y ORDER BY se pueden realizar por campos que no esten en el SELECT
SELECT clie_limite_credito FROM CLIENTE
WHERE clie_codigo <= '00109'
ORDER BY
	clie_domicilio ASC,
	clie_codigo DESC
	

/*SELECT 

	YEAR(fact_fecha),

	MONTH(fact_fecha),

	fact_cliente ,

	fact_total 

FROM Factura f 

WHERE 

	YEAR(fact_fecha) between 2010 and 2012 

order by 

	YEAR(fact_fecha) asc, MONTH(fact_fecha) asc
*/
SELECT *
FROM Factura f JOIN Cliente c
	ON f.fact_cliente = c.clie_codigo

SELECT 

	F.fact_cliente ,

	C.clie_domicilio ,

	F.fact_fecha ,

	F.fact_total 

FROM  Factura f JOIN Cliente c 

	ON F.fact_cliente = C.clie_codigo

SELECT 

	*

FROM Cliente c JOIN Empleado e 

	on c.clie_vendedor = e.empl_codigo

SELECT * 
FROM Item_Factura if2 JOIN Producto p
	ON if2.item_producto = p.prod_codigo

-- Es la forma correcta de vincular porque tiene pk de 3 campos
select * from Factura f join Item_Factura i 
on 
	f.fact_tipo = i.item_tipo 
	and f.fact_sucursal = i.item_sucursal 
	and f.fact_numero = i.item_numero;

-- Interseccion de 3. El resultado de un join, lo mando a otro join
select fact_tipo,fact_sucursal,fact_numero,fact_fecha,fact_total,item_producto,prod_detalle 
from Factura f join Item_Factura i 
	on 
		f.fact_tipo = i.item_tipo 
		and f.fact_sucursal = i.item_sucursal 
		and f.fact_numero = i.item_numero
	join Producto p
		on p.prod_codigo = i.item_producto

select fact_tipo,fact_sucursal,fact_numero,fact_fecha,fact_total,item_producto,prod_detalle, clie_razon_social
from Factura f join Item_Factura i 
	on 
		f.fact_tipo = i.item_tipo 
		and f.fact_sucursal = i.item_sucursal 
		and f.fact_numero = i.item_numero
	join Producto p
		on p.prod_codigo = i.item_producto
	join Cliente c on 
		c.clie_codigo = f.fact_cliente
where 
	year(fact_fecha) = 2012
order by 
	fact_total desc

--1:36;17

-- Producto Cartesiano ',' A X B Hace todas las combinatorias. Se le debe aplicar un WHERE para filtrar.
select 

	*

from Item_Factura i , Producto p 

where 

	p.prod_codigo = i.item_producto 

	

select * 

	from Item_Factura i join Producto p

		on p.prod_codigo = i.item_producto

-- Group By permite aplicar una operacion sobre un conjunto de filas. En este caso sobre el grupo cliente sumame total.

select  

	fact_cliente,

	sum(fact_total)

from Factura f join Cliente c

	on f.fact_cliente = c.clie_codigo 

group by 

	fact_cliente

/*
Funciones de grupo
SUM( NUMEROS )
AVG( NUMEROS )
COUNT( ) 
   COUNT(*)
   COUNT(CONSTANTE)
   COUNT(CAMPO)
   COUNT(DISTINCT CAMPO)
MIN( CAMPO )
MAX( CAMPO )
*/

SELECT 

	SUM(FACT_TOTAL) ,

	COUNT(*)

FROM Factura f

select  

	fact_cliente,

	sum(fact_total) as facturado,

	avg(fact_total) as promedio ,

	count(*) as filas

from Factura f join Cliente c

	on f.fact_cliente = c.clie_codigo 

group by 

	fact_cliente

-- Con distinct
select  

	fact_cliente,

	sum(fact_total) as facturado,

	avg(fact_total) as promedio ,

	count(*) as filas,

	count(distinct fact_vendedor) as count_distinct_vendedor

from Factura f join Cliente c

	on f.fact_cliente = c.clie_codigo 

group by 

	fact_cliente

-- Count(Constante) me cuenta todas las filas
-- Count(campo) Cantidad de valores, distintos de null.

-- Para filtrar grupos: Having. Es como el WHERE para las filas.
