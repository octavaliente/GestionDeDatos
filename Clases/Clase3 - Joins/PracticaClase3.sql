-- Clase 7/9
-- Left Join / Right Join
-- https://www.bigbaydata.com/tipos-de-join-en-sql/

--dado cliente y factura, para todos los clientes la cantidad de facturas que tiene 

-- El count(campo) me saca los nulos.

SELECT 
	c.clie_codigo,
	c.clie_razon_social,
	count(f.fact_numero) as count_correcto,
	count(1) count_constante,
	count(*) count_asterisco
from cliente c left join Factura f 
		on c.clie_codigo = f.fact_cliente 
group by 
	c.clie_codigo,
	c.clie_razon_social
order by 
	3 desc


SELECT 
	CASE 
		WHEN c.clie_codigo = '00000' THEN 'cliente cero'
		WHEN c.clie_codigo = '00001' THEN 'cliente uno'
		ELSE 'RESTO CLIENTES'
	END, 
	COUNT(*)
FROM Cliente c 
GROUP BY 
	CASE 
		WHEN c.clie_codigo = '00000' THEN 'cliente cero'
		WHEN c.clie_codigo = '00001' THEN 'cliente uno'
		ELSE 'RESTO CLIENTES'
	END

--Guia 1,2,3,4

SELECT 	
	Producto.prod_codigo,
	Producto.prod_detalle,
	ISNULL(SUM(Composicion.comp_cantidad) / count(distinct stoc_deposito) ,0) AS num_componentes
FROM Producto
LEFT JOIN Composicion ON Composicion.comp_producto = Producto.prod_codigo
	 JOIN STOCK ON STOCK.stoc_producto = Producto.prod_codigo
GROUP BY
	Producto.prod_codigo, 
	Producto.prod_detalle
HAVING 
	AVG(STOCK.stoc_cantidad) > 100
ORDER BY 
	num_componentes 