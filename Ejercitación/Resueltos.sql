----------------------------------------------------------------

--						EJERCICIOS DE SQL

----------------------------------------------------------------



SELECT
	(e1.entr_apellido + ' ' + e1.entr_nombre) as "Apellido y Nombre",
	COUNT(ee1.enes_entrenador_id) AS "Cantidad especialidades",
	ISNULL(SUM(ee1.enes_hs_semanales), 0) AS "Cantidad Total de horas semanales",
	--
	ISNULL((e2.entr_apellido + ' ' + e2.entr_nombre), 'No posee entrenador') as "Apellido y Nombre del entrenador",
	ISNULL(COUNT(ee2.enes_entrenador_id), 0) AS "Cantidad especialidades del entrenador",
	ISNULL(SUM(ee2.enes_hs_semanales), 0) AS "Cantidad Total de horas semanales del entrenador"
FROM 
	Entrenador AS e1
	LEFT JOIN Entrenador_Especialidad as ee1 ON e1.entr_id = ee1.enes_entrenador_id
	LEFT JOIN Entrenador_Especialidad as ee2 ON e1.entrenado_por_id = ee2.enes_entrenador_id
	LEFT JOIN Entrenador as e2 ON e1.entrenado_por_id = e2.entr_id
GROUP BY e1.entr_id, e1.entr_nombre, e1.entr_apellido, e1.entrenado_por_id, e2.entr_id, e2.entr_nombre, e2.entr_apellido
	
	
/*
EJERCICIO N°1

Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea
mayor o igual a $ 1000 ordenado por código de cliente.
*/

SELECT 
	clie_codigo AS 'Codigo', 
	clie_razon_social AS 'Cliente' 
FROM Cliente
WHERE clie_limite_credito >= 1000
ORDER BY 1

/*
EJERCICIO N°2

Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados
por cantidad vendida.
*/

SELECT 
	prod_codigo AS 'Codigo', 
	prod_detalle AS 'Producto'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_numero = fact_numero 
AND item_tipo = fact_tipo 
AND item_sucursal = fact_sucursal
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY SUM(item_cantidad) DESC

/*
EJERCICIO N°3

Realizar una consulta que muestre código de producto, nombre de producto y el
stock total, sin importar en que deposito se encuentre, los datos deben ser ordenados
por nombre del artículo de menor a mayor.
*/

SELECT 
	prod_codigo AS 'Codigo', 
	prod_detalle AS 'Producto', 
	SUM(stoc_cantidad) AS 'Stock total' 
FROM Producto
JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle

/*
EJERCICIO N°4
 
Realizar una consulta que muestre para todos los artículos código, detalle y cantidad
de artículos que lo componen. Mostrar solo aquellos artículos para los cuales el
stock promedio por depósito sea mayor a 100. 
*/

SELECT 
	prod_codigo AS 'Codigo', 
	prod_detalle AS 'Producto', 
	COUNT(DISTINCT comp_componente) AS 'Componentes'
FROM Producto
LEFT JOIN Composicion ON prod_codigo = comp_producto
JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY prod_codigo, prod_detalle
HAVING AVG(stoc_cantidad) > 100

/*
EJERCICIO N°5

Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos
de stock que se realizaron para ese artículo en el año 2012 (egresan los productos
que fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.
*/

SELECT 
	P1.prod_codigo AS 'Codigo', 
	P1.prod_detalle AS 'Producto',
	SUM(I1.item_cantidad) AS 'Egresos'
FROM Producto P1
JOIN Item_Factura I1 ON P1.prod_codigo = I1.item_producto
JOIN Factura F1 ON I1.item_tipo + I1.item_sucursal + I1.item_numero = 
F1.fact_tipo + F1.fact_sucursal + F1.fact_numero
WHERE YEAR(F1.fact_fecha) = 2012
GROUP BY P1.prod_codigo, P1.prod_detalle
HAVING SUM(I1.item_cantidad) >
(SELECT SUM(I2.item_cantidad)
FROM Item_Factura I2
JOIN Factura F2 ON I2.item_tipo + I2.item_sucursal + I2.item_numero = 
F2.fact_tipo + F2.fact_sucursal + F2.fact_numero
WHERE YEAR(F2.fact_fecha) = 2011 AND I2.item_producto = P1.prod_codigo)

/* 
EJERCICIO N°6

Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de
ese rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos
artículos que tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.

ACLARACION: Si hubiera dicho "Solo tener en cuenta aquellos rubros..." habria utilizado
un HAVING SUM(stoc_cantidad) pero como dice que hay que tener en cuenta ARTICULOS utilizo
un WHERE.  
*/

SELECT 
	rubr_id AS 'Codigo', 
	rubr_detalle AS 'Rubro', 
	COUNT(DISTINCT prod_codigo) AS 'Articulos',
	SUM(stoc_cantidad) AS 'Stock total'
FROM Rubro
JOIN Producto ON rubr_id = prod_rubro
JOIN STOCK ON prod_codigo = stoc_producto
WHERE (SELECT SUM(stoc_cantidad) FROM STOCK WHERE stoc_producto = prod_codigo) >
(SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = '00000000' AND stoc_deposito = '00')
GROUP BY rubr_id, rubr_detalle

/*
EJERCICIO N°7

Generar una consulta que muestre para cada articulo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio= 10, 
mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean stock.

ACLARACION: Asumo que cuando dice "Mostrar solo aquellos articulos que posean stock"
se refiere a los que tienen stock en general no importa en que deposito, es decir el
stock total debe ser mayor a cero para que muestre ese producto.
*/

SELECT 
	prod_codigo AS 'Codigo',
	prod_detalle AS 'Producto', 
	MAX(item_precio) AS 'Precio maximo', 
	MIN(item_precio) AS 'Precio minimo',
	CAST(((MAX(item_precio) - MIN(item_precio)) / MIN(item_precio)) * 100 AS DECIMAL(10,2)) AS 'Diferencia'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY prod_codigo, prod_detalle
HAVING SUM(stoc_cantidad) > 0

/*
EJERCICIO N°8

Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene. 
*/

SELECT 
	prod_detalle AS 'Producto',
	MAX(stoc_cantidad) AS 'Mayor stock' 
FROM Producto
JOIN STOCK ON prod_codigo = stoc_producto
WHERE stoc_cantidad > 0
GROUP BY prod_codigo, prod_detalle
HAVING COUNT(DISTINCT stoc_deposito) = (SELECT COUNT(*) FROM DEPOSITO)

/*
EJERCICIO N°9

Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados.
*/

SELECT 
	empl_jefe AS 'Codigo jefe', 
	empl_codigo AS 'Codigo empleado', 
	(RTRIM(empl_nombre) + ' ' + empl_apellido) AS 'Empleado',
	(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado = empl_jefe) AS 'Depositos jefe', 
	(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado = empl_codigo) AS 'Depositos empleado'
FROM Empleado

/*
EJERCICIO N°10

Mostrar los 10 productos mas vendidos en la historia y también los 10 productos
menos vendidos en la historia. Además mostrar de esos productos, quien fue el
cliente que mayor compra realizo.
*/

SELECT 
	prod_codigo AS 'Codigo', 
	prod_detalle AS 'Producto',
	(SELECT TOP 1 fact_cliente
	FROM Item_Factura
	JOIN Factura ON item_numero + item_tipo + item_sucursal = 
	fact_numero + fact_tipo + fact_sucursal
	WHERE item_producto = prod_codigo 
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad) DESC) AS 'Mejor cliente'
FROM Producto
WHERE prod_codigo IN
	(SELECT TOP 10 item_producto
	FROM Item_Factura
	GROUP BY item_producto
	ORDER BY SUM(item_cantidad) DESC)
OR prod_codigo IN
	(SELECT TOP 10 item_producto
	FROM Item_Factura
	GROUP BY item_producto
	ORDER BY SUM(item_cantidad) ASC)

/* 
EJERCICIO N°11

Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
ordenar de mayor a menor, por la familia que más productos diferentes vendidos
tenga, solo se deberán mostrar las familias que tengan una venta superior a 20000
pesos para el año 2012
*/

SELECT 
	fami_detalle AS 'Familia', 
	COUNT(DISTINCT prod_codigo) AS 'Productos vendidos',
	SUM(item_precio * item_cantidad) AS 'Monto ventas'
FROM Familia
JOIN Producto ON fami_id = prod_familia
JOIN Item_Factura ON prod_codigo = item_producto
GROUP BY fami_id, fami_detalle
HAVING (SELECT SUM(item_cantidad * item_precio)
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_numero + item_tipo + item_sucursal = 
fact_numero + fact_tipo + fact_sucursal
WHERE YEAR(fact_fecha) = 2012 
AND prod_familia = fami_id) > 20000
ORDER BY 2 DESC

/*
EJERCICIO N°12

Mostrar nombre de producto, cantidad de clientes distintos que lo compraron
importe promedio pagado por el producto, cantidad de depósitos en lo cuales hay
stock del producto y stock actual del producto en todos los depósitos. Se deberán
mostrar aquellos productos que hayan tenido operaciones en el año 2012 y los datos
deberán ordenarse de mayor a menor por monto vendido del producto.
*/

SELECT 
	prod_detalle AS 'Producto',
	COUNT(DISTINCT fact_cliente) AS 'Clientes',
	AVG(item_precio) AS 'Precio promedio',
	ISNULL((SELECT COUNT(DISTINCT stoc_deposito) 
	FROM STOCK
	WHERE stoc_producto = prod_codigo 
	AND stoc_cantidad > 0
	GROUP BY stoc_producto), 0) AS 'Depositos con stock',
	ISNULL((SELECT SUM(stoc_cantidad)
	FROM STOCK
	WHERE stoc_producto = prod_codigo
	GROUP BY stoc_producto), 0) AS 'Stock total actual'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_numero + item_sucursal + item_tipo = 
fact_numero + fact_sucursal + fact_tipo
WHERE EXISTS 
(SELECT item_producto
FROM Item_Factura
JOIN Factura ON item_numero + item_sucursal + item_tipo = 
fact_numero + fact_sucursal + fact_tipo
WHERE YEAR(fact_fecha) = 2012 
AND item_producto = prod_codigo)
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle DESC

/*
EJERCICIO N°13

Realizar una consulta que retorne para cada producto que posea composición
nombre del producto, precio del producto, precio de la sumatoria de los precios por
la cantidad de los productos que lo componen. Solo se deberán mostrar los
productos que estén compuestos por más de 2 productos y deben ser ordenados de
mayor a menor por cantidad de productos que lo componen.

ACLARACION: Esta bien que no muestre nada ya que no hay productos que esten
compuestos por mas de 2 productos, si modifica el 2 del HAVING por un 1 se puede
ver los productos compuestos por mas de un producto que en este caso seria todos
los que existen en la BD actualmente
*/

SELECT 
	P1.prod_detalle AS 'Producto',  
	P1.prod_precio AS 'Precio',
	SUM(comp_cantidad * P2.prod_precio) AS 'Precio compuesto'
FROM Producto P1
JOIN Composicion ON P1.prod_codigo = comp_producto
JOIN Producto P2 ON comp_componente = P2.prod_codigo
GROUP BY P1.prod_codigo, P1.prod_detalle, P1.prod_precio
HAVING COUNT(DISTINCT comp_componente ) > 2
ORDER BY COUNT(DISTINCT comp_componente) DESC

/*
EJERCICIO N°14

Escriba una consulta que retorne una estadística de ventas por cliente. Los campos
que debe retornar son:
Código del cliente
Cantidad de veces que compro en el último año
Promedio por compra en el último año
Cantidad de productos diferentes que compro en el último año
Monto de la mayor compra que realizo en el último año
Se deberán retornar todos los clientes ordenados por la cantidad de veces que
compro en el último año.
No se deberán visualizar NULLs en ninguna columna
*/

SELECT 
	clie_codigo AS 'Cliente',
	ISNULL(COUNT(*), 0) AS 'Cantidad compras',
	ISNULL(AVG(fact_total), 0) AS  'Promedio compras',	
	ISNULL((SELECT ISNULL(COUNT(DISTINCT item_producto), 0) 
	FROM Item_Factura
	JOIN Factura ON item_numero + item_sucursal + item_tipo = 
	fact_numero + fact_sucursal + fact_tipo
	WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
	AND fact_cliente = clie_codigo
	GROUP BY fact_cliente), 0) AS 'Productos comprados',
	ISNULL(MAX(fact_total), 0) AS 'Maxima compra'
FROM Cliente
JOIN Factura ON clie_codigo = fact_cliente
WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura) 
GROUP BY clie_codigo
UNION
(SELECT clie_codigo, 0, 0, 0, 0 FROM Cliente
WHERE NOT EXISTS 
(SELECT fact_cliente FROM Factura 
WHERE fact_cliente = clie_codigo
AND YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)))
ORDER BY 2 DESC

/*
EJERCICIO N°15

Escriba una consulta que retorne los pares de productos que hayan sido vendidos
juntos (en la misma factura) más de 500 veces. El resultado debe mostrar el código
y descripción de cada uno de los productos y la cantidad de veces que fueron
vendidos juntos. El resultado debe estar ordenado por la cantidad de veces que se
vendieron juntos dichos productos. Los distintos pares no deben retornarse más de
una vez.
Ejemplo de lo que retornaría la consulta:
--------------------------------------------------------------------------------------
|  PROD1     |  DETALLE1            |  PROD2     |  DETALLE2               |  VECES  |
-------------------------------------------------------------------------------------|
|  00001731  |  MARLBORO KS         |  00001718  |  Linterna con pilas     |  507    |
|  00001718  |  Linterna con pilas  |  00001705  |  PHILIPS MORRIS BOX 10  |  562    |
--------------------------------------------------------------------------------------

ACLARACION: En el pdf en vez de decir "Linterna con pilas" dice "PHILIPS MORRIS KS", quizas
porque hicieron cambios en la BD, ni idea.
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

/*
EJERCICIO N°16

Con el fin de lanzar una nueva campaña comercial para los clientes que menos
compran en la empresa, se pide una consulta SQL que retorne aquellos clientes
cuyas ventas son inferiores a 1/3 del promedio de ventas del/los producto/s que más
se vendieron en el 2012. Además mostrar:
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.
Aclaraciones:
La composición es de 2 niveles, es decir, un producto compuesto solo se compone
de productos no compuestos.
Los clientes deben ser ordenados por código de provincia ascendente.

ACLARACION: Asumo que el producto mas vendido es el que tiene mas UNIDADES vendidas y no el que
que se vendio mas veces (es decir el que aparece mas veces en los items factura), por eso
utilizo SUM(item_cantidad) y no COUNT(item_producto). 
Como no encontre el campo "codigo de provincia" los ordeno por domicilio.
Cuando dice "Clientes cuyas ventas..." asumi que se refiere al total de unidades compradas
sin importar el producto y donde dice "1/3 del promedio de ventas del/los producto/s..."
agarre el producto que mas se vendio en CANTIDAD en 2012, es decir hice un SUM(item_cantidad)
aunque tambien quizas podria haber hecho un AVG(item_cantidad) ya que ahi dice promedio pero
si uso AVG la consulta no devuelve nada asi que le deje el SUM.
Cuando dice "La composicion es de 2 niveles..." no le di bola ya que nunca lo uso 
en la consulta
*/

SELECT
	clie_razon_social AS 'Cliente',
	ISNULL(SUM(item_cantidad), 0) AS 'Unidades compradas',
	ISNULL((SELECT TOP 1 item_producto FROM Factura
	JOIN Item_Factura ON fact_numero + fact_sucursal +fact_tipo = 
	item_numero + item_sucursal + item_tipo
	WHERE fact_cliente = clie_codigo
	GROUP BY fact_cliente, item_producto 
	ORDER BY SUM(item_cantidad) DESC, item_producto ASC), 0) AS 'Producto mas comprado'
FROM Cliente
JOIN Factura ON clie_codigo = fact_cliente
JOIN Item_Factura ON fact_numero + fact_sucursal + fact_tipo = 
item_numero + item_sucursal + item_tipo
WHERE YEAR(fact_fecha) = 2012
GROUP BY clie_codigo, clie_razon_social, clie_domicilio
HAVING SUM(item_cantidad) < (1.00/3) * 
(SELECT TOP 1 SUM(item_cantidad) FROM Factura
JOIN Item_Factura ON fact_numero + fact_sucursal +fact_tipo = 
item_numero + item_sucursal + item_tipo 
WHERE YEAR(fact_fecha) = 2012
GROUP BY item_producto
ORDER BY SUM(item_cantidad) DESC)
ORDER BY clie_domicilio ASC

/*
EJERCICIO N°17

Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.
La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA = Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT = Cantidad vendida del producto en el mismo mes del
periodo pero del año anterior
CANT_FACTURAS = Cantidad de facturas en las que se vendió el producto en el periodo.
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar
ordenada por periodo y código de producto.
*/

SELECT 
	CONCAT(YEAR(F1.fact_fecha), RIGHT('0' + RTRIM(MONTH(F1.fact_fecha)), 2)) AS 'Periodo',
	prod_codigo AS 'Codigo',
	ISNULL(prod_detalle, 'SIN DESCRIPCION') AS 'Producto',
	ISNULL(SUM(item_cantidad), 0) AS 'Cantidad vendida',
	ISNULL((SELECT SUM(item_cantidad) FROM Item_Factura
	JOIN Factura F2 ON item_numero + item_sucursal + item_tipo =
	F2.fact_numero + F2.fact_sucursal + F2.fact_tipo  
	WHERE item_producto = prod_codigo 
	AND YEAR(F2.fact_fecha) = YEAR(F1.fact_fecha) - 1
	AND MONTH(F2.fact_fecha) = MONTH(F1.fact_fecha)), 0) AS 'Cantidad vendida anterior',
	ISNULL(COUNT(*) , 0) AS 'Cantidad de facturas'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura F1 ON item_numero + item_sucursal + item_tipo =
F1.fact_numero + F1.fact_sucursal + F1.fact_tipo
GROUP BY prod_codigo, prod_detalle, YEAR(F1.fact_fecha), MONTH(F1.fact_fecha)
ORDER BY 1, 2

/*
EJERCICIO N°18

Escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30 días.
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar
ordenada por cantidad de productos diferentes vendidos del rubro

ACLARACION: Si cambio por un el >= en donde dice WHERE fact_fecha > 
el cliente de "YERBAS Y TE" cambia de 01413 a 02137
*/

SELECT 
	ISNULL(rubr_detalle, 'Sin descripcion') AS 'Rubro',
	ISNULL(SUM(item_cantidad * item_precio), 0) AS 'Ventas',
	ISNULL((SELECT TOP 1 item_producto
	FROM Producto
	JOIN Item_Factura ON prod_codigo = item_producto
	WHERE prod_rubro = rubr_id
	GROUP BY item_producto
	ORDER BY SUM(item_cantidad) DESC), 0) AS '1° Producto',
	ISNULL((SELECT TOP 1 item_producto FROM Producto
	JOIN Item_Factura ON prod_codigo = item_producto
	WHERE prod_rubro = rubr_id
	AND item_producto NOT IN
		(SELECT TOP 1 item_producto FROM Producto
		JOIN Item_Factura ON prod_codigo = item_producto
		WHERE prod_rubro = rubr_id
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC) 
	GROUP BY item_producto
	ORDER BY SUM(item_cantidad) DESC), '--------') AS '2° Producto',
	ISNULL((SELECT TOP 1 fact_cliente
	FROM Producto
	JOIN Item_Factura ON prod_codigo = item_producto
	JOIN Factura ON item_numero + item_sucursal + item_tipo =
	fact_numero + fact_sucursal + fact_tipo
	WHERE fact_fecha >
	(SELECT DATEADD(DAY, -30, MAX(fact_fecha)) FROM Factura)
	AND prod_rubro = rubr_id
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad) DESC), '--------') AS 'Cliente'
FROM Rubro
JOIN Producto ON rubr_id = prod_rubro
JOIN Item_Factura ON prod_codigo = item_producto
GROUP BY rubr_id, rubr_detalle
ORDER BY COUNT(DISTINCT prod_codigo)


----------------------------------------------------------------

--						EJERCICIOS DE T-SQL

----------------------------------------------------------------

/*
EJERCICIO N°1

Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es menor
al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el % de
ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.
*/

IF OBJECT_ID('FX_OCUPACION_DEL_DEPOSITO') IS NOT NULL
	DROP FUNCTION FX_OCUPACION_DEL_DEPOSITO
GO

CREATE FUNCTION FX_OCUPACION_DEL_DEPOSITO (@PRODUCTO CHAR(8), @DEPOSITO CHAR(2))
	RETURNS CHAR(255)
BEGIN
	DECLARE @MENSAJE CHAR(255)
	DECLARE @STOCK DECIMAL(12,2)
	DECLARE @LIMITE DECIMAL(12,2)
	DECLARE @PORCENTAJE DECIMAL(12,2)
	
	SELECT 
	@STOCK = stoc_cantidad,
	@LIMITE = stoc_stock_maximo
	FROM STOCK
	WHERE stoc_producto = @PRODUCTO
	AND stoc_deposito = @DEPOSITO
		
	IF @LIMITE IS NOT NULL AND 
		@LIMITE > 0 AND
		@STOCK < @LIMITE
	BEGIN
		SET @PORCENTAJE = (@STOCK / @LIMITE) * 100 
		SET @MENSAJE = CONCAT('OCUPACION DEL DEPOSITO ', @PORCENTAJE, '%')
	END
	ELSE
		SET @MENSAJE = 'DEPOSITO COMPLETO'

	RETURN @MENSAJE
END
GO

--PRUEBA

-- Elijo una fila de STOCK para probar la funcion, en este caso elijo la fila
-- que tiene el producto 00000030 en el deposito 00.

SELECT * 
FROM STOCK 
WHERE stoc_producto = '00000030'
AND stoc_deposito = '00'

-- Veo que la cantidad ocupada es 10 y el stock maximo es 50 por lo tanto la funcion
-- deberia devolver un valor de 20% ya que 50 * 0.2 = 10

SELECT DBO.FX_OCUPACION_DEL_DEPOSITO('00000030', '00')

-- Pruebo con otra fila, por ejemplo la que tiene el producto 00001491 en el deposito 16.

SELECT * 
FROM STOCK
WHERE stoc_producto = '00001491'
AND stoc_deposito = '16'

-- Veo que la cantidad ocupada es 4 y el stock maximo es 100 por lo tanto la funcion
-- deberia devolver un valor de 20% ya que 100 * 0.04 = 4

SELECT DBO.FX_OCUPACION_DEL_DEPOSITO('00001491', '16')

-- Ahora pruebo un producto que tenga una cantidad ocupada igual al maximo permitido
-- como no hay un ejemplo como este en la BD lo genero por mi cuenta

INSERT INTO Producto VALUES('99999999', 'PRUEBA', 0.1, '001', '0001', 1)
INSERT INTO STOCK VALUES(100, 0, 100, NULL, NULL, '99999999', '00')

-- Como la cantidad ocupada es 100 y el limite es 100 la funcion me tiene que avisar
-- que el deposito esta completo

SELECT DBO.FX_OCUPACION_DEL_DEPOSITO('99999999', '00')

-- Borro los inserts de prueba

ALTER TABLE STOCK NOCHECK CONSTRAINT R_11
ALTER TABLE PRODUCTO DISABLE TRIGGER ALL 

DELETE 
FROM Producto 
WHERE prod_codigo = '99999999'

DELETE 
FROM STOCK 
WHERE stoc_producto = '99999999'
AND stoc_deposito = '00'

ALTER TABLE PRODUCTO ENABLE TRIGGER ALL
ALTER TABLE STOCK WITH CHECK CHECK CONSTRAINT R_11 


/*
EJERCICIO N°2

Realizar una función que dado un artículo y una fecha, retorne el stock que existía a
esa fecha.
 
ACLARACION: Según la profesora que tuvimos en la práctica en el laboratorio faltan datos
en el enunciado, por lo tanto en este ejercicio solo se pide el stock que se vendio desde la
fecha que se pasa por parametro en adelante.
*/

IF OBJECT_ID('FX_STOCK_VENDIDO_DESDE_FECHA') IS NOT NULL
	DROP FUNCTION FX_STOCK_VENDIDO_DESDE_FECHA
GO

CREATE FUNCTION FX_STOCK_VENDIDO_DESDE_FECHA(@PRODUCTO CHAR(8), @FECHA SMALLDATETIME)
	RETURNS DECIMAL(12,2)
BEGIN
	DECLARE @STOCK_VENDIDO DECIMAL(12,2)

	SET @STOCK_VENDIDO = 
	(SELECT SUM(item_cantidad) 
	FROM Item_Factura
	JOIN Factura 
	ON item_numero + item_sucursal + item_tipo =
	fact_numero + fact_sucursal + fact_tipo
	WHERE fact_fecha >= @FECHA
	AND item_producto = @PRODUCTO 
	GROUP BY item_producto)

	RETURN @STOCK_VENDIDO
END
GO

-- PRUEBA

-- Por ejemplo veo para el producto 00000102 veo cuanto se vendio desde el 17/06/2012

SELECT * 
FROM Item_Factura
JOIN Factura 
ON item_numero + item_sucursal + item_tipo =
fact_numero + fact_sucursal + fact_tipo
WHERE item_producto = '00000102'
AND fact_fecha >= '2012-06-17'

-- La consulta devuelve 5 filas en las cuales en cada una se vendio una sola unidad
-- dando como total 5 unidades vendidas desde esa fecha por lo tanto la funcion me
-- deberia devolver un valor de 5

SELECT DBO.FX_STOCK_VENDIDO_DESDE_FECHA('00000102', '2012-06-17')

/*
EJERCICIO N°3

Cree el/los objetos de base de datos necesarios para corregir la tabla empleado en
caso que sea necesario. Se sabe que debería existir un único gerente general (debería
ser el único empleado sin jefe). Si detecta que hay más de un empleado sin jefe
deberá elegir entre ellos el gerente general, el cual será seleccionado por mayor
salario. Si hay más de uno se seleccionara el de mayor antigüedad en la empresa.
Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla de un único
empleado sin jefe (el gerente general) y deberá retornar la cantidad de empleados
que había sin jefe antes de la ejecución.
*/

IF OBJECT_ID('PR_BUSCAR_GERENTE') IS NOT NULL
	DROP PROCEDURE PR_BUSCAR_GERENTE
GO

CREATE PROCEDURE PR_BUSCAR_GERENTE(@CANTIDAD_EMPLEADOS_SIN_JEFE INT OUTPUT)
AS
BEGIN
	SET @CANTIDAD_EMPLEADOS_SIN_JEFE = 
	(SELECT COUNT(*)
	FROM Empleado
	WHERE empl_jefe IS NULL)

	IF @CANTIDAD_EMPLEADOS_SIN_JEFE = 0
	BEGIN
		RAISERROR('NO HAY EMPLEADOS SIN JEFE', 16, 1)
		RETURN
	END

	IF @CANTIDAD_EMPLEADOS_SIN_JEFE > 1
	BEGIN
		DECLARE @GERENTE NUMERIC(6,0) 
		
		SET @GERENTE =
		(SELECT TOP 1 
		empl_codigo
		FROM Empleado
		WHERE empl_jefe IS NULL 
		ORDER BY empl_salario DESC, empl_ingreso ASC)
	
	UPDATE Empleado 
	SET empl_jefe = @GERENTE
	WHERE empl_jefe IS NULL
	AND empl_codigo != @GERENTE

	UPDATE Empleado 
	SET empl_tareas = 'Gerente General'
	WHERE empl_codigo = @GERENTE
	END
END
GO

--PRUEBA

-- Hago un insert de un empleado de prueba ya que en la BD hay uno solo que no tiene jefe

INSERT INTO Empleado VALUES (99, 'Armando', 'Barreda', '1985-01-01', '1999-01-03', NULL, 10000, 0, NULL, 1)

-- Al hacer un listado con los empleados que no tiene jefe ahora aparecen el empleado 1 y 99 

SELECT *
FROM Empleado
WHERE empl_jefe IS NULL

-- El stored procedure deberia devolver un valor de 2 ya que es la cantidad 
-- de empleados que no tienen jefe (el 1 y el 99).

DECLARE @RESULTADO INT
EXEC PR_BUSCAR_GERENTE @RESULTADO OUTPUT
SELECT @RESULTADO
GO

-- Como hay dos empleados sin jefe primero se desempata por quien tiene mayor salario,
-- en este caso el gerente general deberia ser empleado 1 ya que 25000 > 10000
-- Por lo tanto el empleado 99 deberia ser empleado del 1 y este ultimo no deberia 
-- tener jefes ya que es el gerente general (el campo estaria en NULL)

SELECT *
FROM Empleado
WHERE empl_codigo = 1
OR empl_codigo = 99

-- Ahora reseteo los valores y modifico al empleado 99 para que tenga el mismo 
-- salario que el 1

UPDATE Empleado SET empl_jefe = NULL, empl_tareas = 'Gerente' WHERE empl_codigo = 1
UPDATE Empleado SET empl_jefe = NULL, empl_salario = 25000 WHERE empl_codigo = 99

-- Como ahora ambos tienen el mismo salario se desempata por el de mayor antiguedad,
-- el mas antiguo es el empleado 99 ya que ingreso en el año 1999 mientras que el 
-- empleado 1 en el año 2000, por lo tanto el empleado 99 deberia ser el nuevo gerente
-- y el 1 pasa a ser empleado del 99

DECLARE @RESULTADO INT
EXEC PR_BUSCAR_GERENTE @RESULTADO OUTPUT
SELECT @RESULTADO
GO

SELECT *
FROM Empleado
WHERE empl_codigo = 1
OR empl_codigo = 99

-- Dejo todo como estaba antes

UPDATE Empleado SET empl_jefe = NULL, empl_tareas = 'Gerente' 
WHERE empl_codigo = 1
DELETE FROM Empleado WHERE empl_codigo = 99

/*
EJERCICIO N°4

Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese empleado
a lo largo del último año. Se deberá retornar el código del vendedor que más vendió
(en monto) a lo largo del último año.

ACLARACION: Cuando dice "a lo largo del ultimo año" asumo que se refiere al ultimo año
que figura en la BD (en este caso es 2012) y donde dice "monto" asumi que se refiere al
monto total sin impuestos (que seria el campo 'fact_total').
*/

IF OBJECT_ID('PR_ACTUALIZAR_COMISIONES') IS NOT NULL
	DROP PROCEDURE PR_ACTUALIZAR_COMISIONES
GO

CREATE PROCEDURE PR_ACTUALIZAR_COMISIONES(@EMPLEADO_MAS_VENDEDOR NUMERIC(6,0) OUTPUT)
AS
BEGIN
	DECLARE @ULTIMO_ANIO INT

	SET @ULTIMO_ANIO = (SELECT YEAR((SELECT MAX(fact_fecha) FROM Factura)))

	UPDATE Empleado SET empl_comision =
	ISNULL((SELECT SUM(fact_total)
	FROM Factura
	WHERE fact_vendedor = empl_codigo
	AND YEAR(fact_fecha) = @ULTIMO_ANIO), 0)

	SET @EMPLEADO_MAS_VENDEDOR =
	(SELECT TOP 1 fact_vendedor 
	FROM Factura
	WHERE YEAR(fact_fecha) = @ULTIMO_ANIO
	GROUP BY fact_vendedor
	ORDER BY SUM(fact_total) DESC)
END
GO

-- PRUEBA

-- Primero me fijo las comisiones de los empleados y veo que algunas estan nulas
-- o con valores, despues de ejecutar el SP esto deberia actualizarse para el ejemplo
-- voy a elegir al empleado 5 que tiene una comision de 0.15

SELECT * FROM Empleado

-- Para obtener el ultimo año ejecuto la siguiente consulta, en este caso seria 2012

SELECT YEAR((SELECT MAX(fact_fecha) FROM Factura))

-- Como el SP actualiza la comision con el valor de la suma del total de las ventas
-- realizadas por el empleado en el ultimo año, para el empleado 5 la nueva comision
-- deberia ser de 88749,57

SELECT SUM(fact_total)
FROM Factura
WHERE fact_vendedor = 5
AND YEAR(fact_fecha) = 2012 

-- Antes de ejecutar el SP veo cual es el empleado que mas vendio el ultimo año
-- para ver si el SP me va a devolver lo mismo

SELECT fact_vendedor 
FROM Factura
WHERE YEAR(fact_fecha) = 2012
GROUP BY fact_vendedor
ORDER BY SUM(fact_total) DESC

-- Como la anterior consulta me dice que el empleado 4 fue el que mas vendio, esto
-- deberia ser lo que me tendria que devolver el Stored Procedure y a su vez actualizar
-- las comisiones y en el caso del empleado 5 la comision deberia ser de 88749,57

DECLARE @RESULTADO INT
EXEC PR_ACTUALIZAR_COMISIONES @RESULTADO OUTPUT
SELECT @RESULTADO
GO

-- Finalmente compruebo si se actualizaron las comisiones

SELECT empl_codigo, empl_comision FROM Empleado


/*
EJERCICIO N°5

Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:

Create table Fact_table
(	anio char(4),
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

IF OBJECT_ID('FACT_TABLE') IS NOT NULL
	DROP TABLE FACT_TABLE
GO

CREATE TABLE FACT_TABLE( 
	fact_anio char(4),
	fact_mes char(2),
	fact_familia char(3),
	fact_rubro char(4),
	fact_zona char(3),
	fact_cliente char(6),
	fact_producto char(8),
	fact_cantidad decimal(12,2),
	fact_monto decimal(12,2)
	CONSTRAINT PK_FACT_TABLE 
	PRIMARY KEY(fact_anio, fact_mes, fact_familia, 
	fact_rubro, fact_zona, fact_cliente, fact_producto)
)
GO

IF OBJECT_ID('PR_COMPLETAR_FACT_TABLE') IS NOT NULL
	DROP PROCEDURE PR_COMPLETAR_FACT_TABLE
GO

CREATE PROCEDURE PR_COMPLETAR_FACT_TABLE
AS
BEGIN
	INSERT INTO FACT_TABLE
	SELECT 
	YEAR(fact_fecha), 
	MONTH(fact_fecha), 
	prod_familia, 
	prod_rubro, 
	depa_zona, 
	fact_cliente, 
	prod_codigo, 
	SUM(ISNULL(item_cantidad, 0)),
	SUM(ISNULL(item_cantidad * item_precio, 0))  
	FROM Item_Factura
	JOIN Factura ON item_numero + item_sucursal + item_tipo =
	fact_numero + item_sucursal + item_tipo
	JOIN Producto ON item_producto = prod_codigo 
	JOIN Empleado ON fact_vendedor = empl_codigo
	JOIN Departamento ON empl_departamento = depa_codigo
	GROUP BY 
	YEAR(fact_fecha), 
	MONTH(fact_fecha), 
	prod_familia, 
	prod_rubro,
	depa_zona, 
	fact_cliente, 
	prod_codigo
END
GO

-- PRUEBA

-- Primero veo que productos se vendieron y tomo uno para probar el SP como por ejemplo
-- par el producto 00001415 del rubro 0010 y familia 101 durante el mes de junio en el 
-- año 2012 al cliente 00656 correspondiente a la zona 004

SELECT
SUM(item_cantidad) AS 'Cantidad vendida',
SUM (item_cantidad * item_precio) AS 'Monto'
FROM Item_Factura
JOIN Factura ON item_numero + item_sucursal + item_tipo =
fact_numero + item_sucursal + item_tipo
JOIN Producto ON item_producto = prod_codigo 
JOIN Empleado ON fact_vendedor = empl_codigo
JOIN Departamento ON empl_departamento = depa_codigo
WHERE item_producto = '00001415' AND
YEAR(fact_fecha) = 2012 AND
MONTH(fact_fecha) = 6 AND
fact_cliente = '00656' AND
depa_zona = '004' AND
prod_familia = '101' AND
prod_rubro = '0010'


-- Segun la consulta anterior se vendieron en junio de 2012 unas 10 unidades del 
-- producto 00001415 por un monto de 13.30, por lo tanto estos dos valores
-- deberian aparecer en la tabla FACT_TABLE junto con los otros campos cuando
-- ejecute el SP

EXEC PR_COMPLETAR_FACT_TABLE

-- Compruebo si aparecen esos valores en la tabla FACT_TABLE

SELECT * FROM FACT_TABLE
WHERE fact_producto = '00001415' AND
fact_mes = 6 AND
fact_anio = 2012 AND
fact_cliente = '00656' AND
fact_zona = '004' AND
fact_familia = '101' AND
fact_rubro = '0010'

-- Elimino la tabla para dejar todo como estaba

IF OBJECT_ID('FACT_TABLE') IS NOT NULL
	DROP TABLE FACT_TABLE
GO

/*
EJERCICIO N°6

Realizar un procedimiento que si en alguna factura se facturaron componentes que
conforman un combo determinado (o sea que juntos componen otro producto de
mayor nivel), en cuyo caso deberá reemplazar las filas correspondientes a dichos
productos por una sola fila con el producto que componen con la cantidad de dicho
producto que corresponda.

ACLARACION: Intente hacerlo para que funcione con varios niveles de composicion
pero se me hizo muy complejo asi que asumi que un producto a lo sumo estara compuesto
por 2 productos simples (es decir, estos no son compuestos).
*/

IF OBJECT_ID('PR_UNIFICAR_PRODUCTOS') IS NOT NULL
	DROP PROCEDURE PR_UNIFICAR_PRODUCTOS
GO

CREATE PROCEDURE PR_UNIFICAR_PRODUCTOS
AS
BEGIN
	DECLARE @PRODUCTO CHAR(8)
	DECLARE @COMPONENTE CHAR(8)
	DECLARE @TIPO CHAR(1)
	DECLARE @SUCURSAL CHAR(4)
	DECLARE @NUMERO CHAR(8)
	DECLARE @CANTIDAD_VENDIDA DECIMAL(12,2)
	DECLARE @PRECIO_PRODUCTO DECIMAL(12,2)
	DECLARE @CANTIDAD_COMPONENTE DECIMAL(12,2)

	DECLARE C_COMPONENTE CURSOR FOR
	SELECT item_tipo, item_sucursal, item_numero,
	item_producto, item_cantidad, comp_cantidad,
	comp_producto, prod_precio
	FROM Item_Factura
	JOIN Composicion ON item_producto = comp_componente
	JOIN Producto ON comp_producto = prod_codigo
	AND item_cantidad % comp_cantidad = 0
	
	OPEN C_COMPONENTE

	FETCH NEXT FROM C_COMPONENTE INTO @TIPO, @SUCURSAL, @NUMERO,
	@COMPONENTE, @CANTIDAD_VENDIDA, @CANTIDAD_COMPONENTE,
	@PRODUCTO, @PRECIO_PRODUCTO

	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @COMPONENTE2 CHAR(8)
		DECLARE @CANTIDAD DECIMAL(12,2)

		SET @CANTIDAD = @CANTIDAD_VENDIDA / @CANTIDAD_COMPONENTE

		SET @COMPONENTE2 = 
		(SELECT item_producto
		FROM Item_Factura
		JOIN Composicion ON item_producto = comp_componente
		WHERE item_tipo = @TIPO 
		AND item_sucursal = @SUCURSAL 
		AND item_numero = @NUMERO 
		AND item_producto != @COMPONENTE 
		AND (item_cantidad / comp_cantidad) = @CANTIDAD)

		IF @COMPONENTE IS NOT NULL
		AND @COMPONENTE2 IS NOT NULL
		BEGIN
			DELETE FROM Item_Factura 
			WHERE item_tipo = @TIPO
			AND item_sucursal = @SUCURSAL
			AND item_numero = @NUMERO
			AND item_producto = @COMPONENTE

			DELETE FROM Item_Factura 
			WHERE item_tipo = @TIPO
			AND item_sucursal = @SUCURSAL
			AND item_numero = @NUMERO
			AND item_producto = @COMPONENTE2
		
			INSERT INTO Item_Factura 
			VALUES (@TIPO, @SUCURSAL, @NUMERO, 
			@PRODUCTO, @CANTIDAD, @PRECIO_PRODUCTO)
		END

	FETCH NEXT FROM C_COMPONENTE INTO @TIPO, @SUCURSAL, @NUMERO,
	@COMPONENTE, @CANTIDAD_VENDIDA, @CANTIDAD_COMPONENTE,
	@PRODUCTO, @PRECIO_PRODUCTO
	
	END
	
	CLOSE C_COMPONENTE
	DEALLOCATE C_COMPONENTE
END
GO

-- PRUEBA

-- Inserto un producto de prueba un compuesto por dos productos e inserto sus
-- correspondientes items factura

INSERT INTO Producto VALUES ('99999999', 'PROD1', 15, '001', '0001', 1)
INSERT INTO Producto VALUES ('99999998', 'COMP1', 10, '001', '0001', 1)
INSERT INTO Producto VALUES ('99999997', 'COMP2', 10, '001', '0001', 1)
INSERT INTO Composicion VALUES (1, '99999999', '99999998')
INSERT INTO Composicion VALUES (2, '99999999', '99999997')
INSERT INTO Factura VALUES ('A', '0003', '99999999', GETDATE(), 1, 0, 0, NULL)
INSERT INTO Item_Factura VALUES ('A', '0003', '99999999', '99999998', 2, 10)
INSERT INTO Item_Factura VALUES ('A', '0003', '99999999', '99999997', 4, 20)

-- Me fijo los items factura para asegurarme que fueron insertados

SELECT * FROM Item_Factura 
WHERE item_tipo = 'A' AND
item_sucursal = '0003' AND
item_numero = '99999999' 

-- Ahora ejecuto ejecuto el SP

EXEC PR_UNIFICAR_PRODUCTOS

-- Me fijo que se hayan eliminado las dos filas de sus componentes

SELECT * FROM Item_Factura 
WHERE item_tipo = 'A' AND
item_sucursal = '0003' AND
item_numero = '99999999' AND
item_producto = '99999998'

SELECT * FROM Item_Factura 
WHERE item_tipo = 'A' AND
item_sucursal = '0003' AND
item_numero = '99999997' AND
item_producto = '99999996'

-- Finalmente me fijo que para el producto 99999999 se haya insertado un item factura 
-- con cantidad 2

SELECT * FROM Item_Factura 
WHERE item_tipo = 'A' AND
item_sucursal = '0003' AND
item_numero = '99999999' AND
item_producto = '99999999'

-- Elimino los inserts de prueba

ALTER TABLE Producto DISABLE TRIGGER ALL

DELETE FROM Item_Factura WHERE item_tipo = 'A' AND item_numero = '99999999'
AND item_sucursal = '0003' AND item_producto = '99999999'

DELETE FROM Factura WHERE fact_tipo = 'A' AND fact_numero = '99999999'
AND fact_sucursal = '0003'

DELETE FROM Composicion WHERE comp_producto = '99999999' AND comp_componente = '99999998'
DELETE FROM Composicion WHERE comp_producto = '99999999' AND comp_componente = '99999997'

DELETE FROM Producto WHERE prod_codigo = '99999999'
DELETE FROM Producto WHERE prod_codigo = '99999998'
DELETE FROM Producto WHERE prod_codigo = '99999997'

ALTER TABLE Producto ENABLE TRIGGER ALL

/*
EJERCICIO N°7

Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock realizados entre
esas fechas. La tabla se encuentra creada y vacía.

TABLA DE VENTAS 
------------------------------------------------------------------------------------------------------------
|  Código	|  Detalle  |  Cant. Mov.  |  Precio de Venta  |  Renglon  |           Ganancia              |  
------------------------------------------------------------------------------------------------------------
|  Código	|  Detalle	|  Cantidad de |    Precio  	   |  Nro. de  |  Precio de venta * Cantidad     |
|  del		|  del      |  movimientos |    promedio 	   |  linea de |  -							     |
|  articulo |  articulo	|  de ventas   |    de venta	   |  la tabla |  Precio de producto * Cantidad  |
------------------------------------------------------------------------------------------------------------

ACLARACION: Asumo que 'Cantidad de movimientos' es la cantidad de veces que se vendio
ese producto, es decir la cantidad de veces que el producto aparece en la tabla
Item_Factura
*/

IF OBJECT_ID('VENTAS') IS NOT NULL
	DROP TABLE VENTAS
GO

CREATE TABLE VENTAS( 
	venta_codigo char(8),
	venta_detalle char(50),
	venta_movimientos INT,
	venta_precio DECIMAL(12,2),
	venta_renglon NUMERIC(6,0),
	venta_ganancia DECIMAL(12,2)
)
GO

IF OBJECT_ID('PR_COMPLETAR_VENTAS') IS NOT NULL
	DROP PROCEDURE PR_COMPLETAR_VENTAS
GO

CREATE PROCEDURE PR_COMPLETAR_VENTAS(@FECHA1 SMALLDATETIME, @FECHA2 SMALLDATETIME)
AS
BEGIN
	DECLARE @CODIGO CHAR(8)
	DECLARE @PRODUCTO CHAR(50)
	DECLARE @MOVIMIENTOS INT
	DECLARE @PRECIO DECIMAL(12,2)
	DECLARE @RENGLON INT
	DECLARE @GANANCIA DECIMAL(12,2)

	DECLARE C_VENTA CURSOR FOR
	SELECT 
	prod_codigo, 
	prod_detalle, 
	COUNT(item_producto), 
	AVG(item_precio),
	SUM(item_cantidad * item_precio) - SUM(item_cantidad * prod_precio)
	FROM Producto
	JOIN Item_Factura ON prod_codigo = item_producto
	JOIN Factura ON item_numero + item_sucursal + item_tipo =
	fact_numero + fact_sucursal + fact_tipo
	WHERE fact_fecha BETWEEN @FECHA1 AND @FECHA2
	GROUP BY prod_codigo, prod_detalle
	
	OPEN C_VENTA
	
	FETCH NEXT FROM C_VENTA INTO @CODIGO, @PRODUCTO, @MOVIMIENTOS, 
	@PRECIO, @GANANCIA
	
	IF OBJECT_ID('VENTAS') IS NOT NULL
		SET @RENGLON = (SELECT MAX(@RENGLON) FROM VENTAS) + 1
	ELSE
		SET @RENGLON = 0

	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO VENTAS VALUES
		(@CODIGO, @PRODUCTO, @MOVIMIENTOS,
		@PRECIO, @RENGLON, @GANANCIA)

		SET @RENGLON = @RENGLON + 1

		FETCH NEXT FROM C_VENTA INTO @CODIGO, @PRODUCTO, @MOVIMIENTOS, 
		@PRECIO, @GANANCIA			
	END
	
	CLOSE C_VENTA
	DEALLOCATE C_VENTA
END
GO

-- PRUEBA

-- Para el ejemplo veo cuantas veces se vendio y el monto de venta total para el
-- producto 00001415 entre las fechas 01/01/2012 y 01/06/2012

SELECT item_producto, 
COUNT(*) AS 'VECES QUE SE VENDIO',
SUM(item_cantidad * item_precio) AS 'MONTO TOTAL VENDIDO'
FROM Item_Factura
JOIN Factura ON item_numero + item_sucursal + item_tipo =
fact_numero + fact_sucursal + fact_tipo
WHERE item_producto = '00001415' AND
fact_fecha BETWEEN '2012-01-01' AND '2012-06-01' 
GROUP BY item_producto

-- La consulta anterior devolvio que se vendio 30 veces el producto 00001415 y el monto
-- total de venta fue de 436.82 ahora veo de cuanto fue el costo de venta total

SELECT item_producto,
SUM(item_cantidad * prod_precio) AS 'COSTO DE VENTA TOTAL'
FROM Item_Factura
JOIN Producto ON item_producto = prod_codigo
JOIN Factura ON item_numero + item_sucursal + item_tipo =
fact_numero + fact_sucursal + fact_tipo
WHERE item_producto = '00001415' AND
fact_fecha BETWEEN '2012-01-01' AND '2012-06-01' 
GROUP BY item_producto

-- Ejecuto el SP para que complete la tabla VENTAS

EXEC PR_COMPLETAR_VENTAS '2012-01-01', '2012-06-01' 

-- De las consultas anteriores obtuve que el monto de venta total fue de 436.82 y
-- que el costo de venta total fue de 366.30 por lo tanto
-- la ganancia total es de 70.52 (436.82 - 366.30) y el producto se vendio 30 veces.
-- Por lo tanto compruebo si esos valores figuran en la tabla VENTAS

SELECT * 
FROM VENTAS
WHERE venta_codigo = '00001415'

-- Borro la tabla de VENTAS

IF OBJECT_ID('VENTAS') IS NOT NULL
	DROP TABLE VENTAS
GO


/* 
EJERCICIO N°8

Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por cantidad
de sus componentes, se aclara que un producto que compone a otro, también puede
estar compuesto por otros y así sucesivamente, la tabla se debe crear y está formada
por las siguientes columnas:

TABLA DE DIFERENCIAS 
------------------------------------------------------------------------------------
|  Código	|  Detalle  |    Cantidad     |  Precio generado  |  Precio facturado  |  
------------------------------------------------------------------------------------
|  Código	|  Detalle	|  Cantidad de    |  Precio que se    |  Precio del        |
|  del		|  del      |  productos que  |  se compone a 	  |  producto		   | 
|  articulo |  articulo	|  conforman el   |  traves de sus    |					   |
|           |           |  combo          |  componentes      |					   |
------------------------------------------------------------------------------------
*/

IF OBJECT_ID('DIFERENCIAS') IS NOT NULL
	DROP TABLE DIFERENCIAS
GO

CREATE TABLE DIFERENCIAS ( 
	dif_codigo char(8),
	dif_detalle char(50),
	dif_cantidad NUMERIC(6,0),
	dif_precio_generado DECIMAL(12,2),
	dif_precio_facturado DECIMAL(12,2),
)
GO

IF OBJECT_ID('FX_PRODUCTO_COMPUESTO_PRECIO') IS NOT NULL
	DROP FUNCTION FX_PRODUCTO_COMPUESTO_PRECIO
GO

CREATE FUNCTION FX_PRODUCTO_COMPUESTO_PRECIO(@PRODUCTO CHAR(8))
	RETURNS DECIMAL(12,2)
AS
BEGIN
	DECLARE @PRECIO DECIMAL(12,2)
	
	SET @PRECIO =
	(SELECT SUM(DBO.FX_PRODUCTO_COMPUESTO_PRECIO(comp_componente) * comp_cantidad) 
	FROM Composicion
	WHERE comp_producto = @PRODUCTO)

	IF @PRECIO IS NULL
		SET @PRECIO = 
		(SELECT prod_precio 
		FROM Producto 
		WHERE prod_codigo = @PRODUCTO)
	
	RETURN @PRECIO
END
GO

IF OBJECT_ID('PR_COMPLETAR_DIFERENCIAS') IS NOT NULL
	DROP PROCEDURE PR_COMPLETAR_DIFERENCIAS
GO

CREATE PROCEDURE PR_COMPLETAR_DIFERENCIAS
AS
BEGIN
	INSERT INTO DIFERENCIAS
	SELECT 
	P1.prod_codigo, 
	P1.prod_detalle, 
	COUNT(DISTINCT comp_componente),
	DBO.FX_PRODUCTO_COMPUESTO_PRECIO(prod_codigo),
	P1.prod_precio
	FROM Producto P1
	JOIN Composicion ON P1.prod_codigo = comp_producto
	GROUP BY prod_codigo, prod_detalle, prod_precio
END
GO

--PRUEBA

-- Elijo un producto compuesto como por ejemplo el 00001707 y veo que tiene
-- un precio facturado de 27.20

SELECT *
FROM Producto
WHERE prod_codigo = '00001707'

-- El producto 00001707 esta compuesto por dos 2 productos, 1 unidad del 00001491 y 
-- 2 unidades del 00014003 

SELECT * 
FROM Composicion
JOIN Producto ON comp_componente = prod_codigo
WHERE comp_producto = '00001707'

-- Como los dos productos que componen al 00001707 no son compuestos solo hay que
-- sumar sus costos para obtener el costo del producto 00001707, haciendo la cuenta
-- me da que el costo de 00001707 es de 27.62 ya que el costo del producto 00001491 es
-- de 15.92 (15.92 * 1) y el costo del producto 00014003 es de 11.7 (5.85 * 2).
-- Ejecuto el SP para completar la tabla de DIFERENCIAS

EXEC PR_COMPLETAR_DIFERENCIAS

-- Por lo tanto en la tabla DIFERENCIAS en la columna de productos que lo componen 
-- deberia figurar un 2 para el producto 00001707, un precio generado de 27.62 y un
-- precio facturado de 27.20

SELECT *
FROM DIFERENCIAS
WHERE dif_codigo = '00001707'

/*
EJERCICIO N°9

Hacer un trigger que ante alguna modificación de un ítem de factura de un artículo
con composición realice el movimiento de sus correspondientes componentes.

ACLARACION: Como el enunciado dice "ante alguna modificacion" asumo que tengo que validar
este caso solo para UPDATE y que lo unico que puedo modificar de un item factura es la 
cantidad vendida de ese producto (item_cantidad), por lo tanto una vez modificado ese
campo, el trigger deberia ir a la tabla stock y modificar el stock disponible de los
componentes de ese producto. Como hay stocks negativos en la BD no valido que este tengo 
que ser mayor a 0, lo unico que valido es que no supere el limite de stock. El trigger
solo se activa si hay actualizaciones en la columna item_cantidad 
*/

IF OBJECT_ID('PR_ACTUALIZAR_COMPONENTES_ITEM_FACTURA') IS NOT NULL
	DROP PROCEDURE PR_ACTUALIZAR_COMPONENTES_ITEM_FACTURA
GO

CREATE PROCEDURE PR_ACTUALIZAR_COMPONENTES_ITEM_FACTURA (@NUMERO CHAR(8), @TIPO CHAR(1), @SUCURSAL CHAR(4), 
@PRODUCTO CHAR(8), @DIFERENCIA DECIMAL(12,2), @RESULTADO INT OUTPUT)
AS
BEGIN
	IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @PRODUCTO)
	BEGIN
		DECLARE @COMPONENTE CHAR(8)
		DECLARE @CANTIDAD DECIMAL(12,2)
		
		SET @RESULTADO = 1
		
		DECLARE C_ITEM_FACTURA_PR CURSOR FOR
		SELECT comp_componente, comp_cantidad 
		FROM Composicion 
		WHERE comp_producto = @PRODUCTO 
		
		OPEN C_ITEM_FACTURA_PR
		FETCH NEXT FROM C_ITEM_FACTURA_PR INTO @COMPONENTE, @CANTIDAD
		
		BEGIN TRANSACTION
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @LIMITE DECIMAL(12,2)	
			DECLARE @DEPOSITO CHAR(2)
			DECLARE @STOCK_ACTUAL DECIMAL(12,2)
			DECLARE @STOCK_RESULTANTE DECIMAL(12,2)
				
			SELECT TOP 1
			@STOCK_ACTUAL = stoc_cantidad,
			@LIMITE = ISNULL(stoc_stock_maximo, 0),
			@DEPOSITO = stoc_deposito
			FROM STOCK
			WHERE stoc_producto = @COMPONENTE
			ORDER BY stoc_cantidad ASC

			SET @STOCK_RESULTANTE = @STOCK_ACTUAL +  @DIFERENCIA * @CANTIDAD
		 		 
			IF @STOCK_RESULTANTE <= @LIMITE
			BEGIN
				UPDATE STOCK SET stoc_cantidad = @STOCK_RESULTANTE
				WHERE stoc_producto = @COMPONENTE
				AND stoc_deposito = @DEPOSITO
			END
			ELSE
			BEGIN
				SET @RESULTADO = 0
				RAISERROR('EL ITEM FACTURA CON NUMERO: %s, TIPO: %s, SUCURSAL: %s, PRODUCTO: %s NO CUMPLE CON LOS LIMITES DE STOCK', 16, 1, @NUMERO, @TIPO, @SUCURSAL, @PRODUCTO)
				BREAK				
			END
		FETCH NEXT FROM C_ITEM_FACTURA_PR INTO @COMPONENTE, @CANTIDAD
		END

		IF @RESULTADO = 1
			COMMIT TRANSACTION
		ELSE
			ROLLBACK TRANSACTION

		CLOSE C_ITEM_FACTURA_PR
		DEALLOCATE C_ITEM_FACTURA_PR
	END
	
	ELSE
		RAISERROR('EL PRODUCTO %s NO ES COMPUESTO', 16, 1, @PRODUCTO)
END
GO

IF OBJECT_ID('TR_MOVER_COMPONENTES') IS NOT NULL
	DROP TRIGGER TR_MOVER_COMPONENTES
GO

CREATE TRIGGER TR_MOVER_COMPONENTES
ON Item_Factura INSTEAD OF UPDATE
AS
BEGIN
	IF UPDATE(item_cantidad)
	BEGIN
		DECLARE @NUMERO CHAR(8)
		DECLARE @TIPO CHAR(1)
		DECLARE @SUCURSAL CHAR(4)
		DECLARE @PRODUCTO CHAR(8)
		DECLARE @DIFERENCIA DECIMAL(12,2)
		DECLARE @RESULTADO INT
		
		DECLARE C_ITEM_FACTURA CURSOR FOR
		SELECT
		inserted.item_numero, 
		inserted.item_tipo,
		inserted.item_sucursal,
		inserted.item_producto,
		deleted.item_cantidad - inserted.item_cantidad 	  
		FROM inserted 
		JOIN deleted ON  
		inserted.item_tipo + inserted.item_sucursal + 
		inserted.item_numero + inserted.item_producto = 
		deleted.item_tipo + deleted.item_sucursal +
		deleted.item_numero + deleted.item_producto
	
		OPEN C_ITEM_FACTURA
	
		FETCH NEXT FROM C_ITEM_FACTURA INTO @NUMERO, @TIPO, @SUCURSAL, 
		@PRODUCTO, @DIFERENCIA

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC PR_ACTUALIZAR_COMPONENTES_ITEM_FACTURA @NUMERO, @TIPO, @SUCURSAL,
			@PRODUCTO, @DIFERENCIA, @RESULTADO OUTPUT

			IF @RESULTADO = 1
			BEGIN
				UPDATE Item_Factura SET item_cantidad = item_cantidad - @DIFERENCIA
				WHERE item_numero = @NUMERO
				AND item_sucursal = @SUCURSAL
				AND item_tipo = @TIPO
				AND item_producto = @PRODUCTO
			END

			FETCH NEXT FROM C_ITEM_FACTURA INTO @NUMERO, @TIPO, @SUCURSAL, 
			@PRODUCTO, @DIFERENCIA
		END

		CLOSE C_ITEM_FACTURA
		DEALLOCATE C_ITEM_FACTURA
	END
END
GO

--PRUEBA

-- Si el producto del item_factura no es un producto compuesto el trigger
-- mostrara un aviso por pantalla, por ejemplo el producto '00001415' no es
-- compuesto

UPDATE Item_Factura SET item_cantidad = 10
WHERE item_producto = '00001415'
AND item_numero = '00092441'
AND item_sucursal = '0003'
AND item_tipo = 'A'

-- Busco un producto que sea compuesto como por ejemplo el producto con codigo '00001707'
-- para verificarlo ejecuto la siguiente instruccion y observo que esta
-- compuesto por 1 unidad del producto '00001491' y 2 unidades del producto '00014003'

SELECT *
FROM Composicion
WHERE comp_producto = '00001707' 

-- Ahora agarro un item factura de prueba con ese producto y se puede ver que la cantidad 
-- vendida fue de 10 unidades

SELECT *
FROM Item_Factura
WHERE item_producto = '00001707'
AND item_numero = '00068711'
AND item_sucursal = '0003'
AND item_tipo = 'A'

-- Agarro los depositos que tenga menos cantidad de esos productos, en
-- este caso  para el producto '00001491' es el deposito 16 y tiene 
-- una cantidad de 2 unidades y para el producto '00014003' es el deposito
-- 03 y tiene una cantidad de 14 unidades

SELECT TOP 1 *
FROM STOCK
WHERE stoc_producto = '00001491'
ORDER BY stoc_cantidad ASC

SELECT TOP 1 *
FROM STOCK
WHERE stoc_producto = '00014003'
ORDER BY stoc_cantidad ASC

-- Antes de hacer el update en item factura actualizo el stock maximo para 
-- el producto '00001419' ya que actualmente tiene valor NULL por lo tanto si no 
-- ejecutamos esta instruccion no va a querer hacer el update

UPDATE STOCK SET stoc_stock_maximo = 100
WHERE stoc_producto = '00001491'
AND stoc_deposito = '16'

-- Actualizo la cantidad vendida en vez de ser 10 ahora es 8, es decir
-- tengo que agregar al stock disponible 2 unidades de '00001491'
-- y 4 unidades de '00014003'

UPDATE Item_Factura SET item_cantidad = 8
WHERE item_producto = '00001707'
AND item_numero = '00068711'
AND item_sucursal = '0003'
AND item_tipo = 'A'

-- Despues de realizar el update deberia quedar para el producto '00001491' 
-- una cantidad de 4 (2 + 2 * 1) unidades  y para el producto '00014003' es el deposito
-- 03 y tiene una cantidad de 18 (14 + 2 * 2) unidades

SELECT TOP 1 *
FROM STOCK
WHERE stoc_producto = '00001491'
AND stoc_deposito = '16'

SELECT TOP 1 *
FROM STOCK
WHERE stoc_producto = '00014003'
AND stoc_deposito = '03'

-- Finalmente vemos que el item factura quedo modificado ahora figura una cantidad
-- vendida de 8 unidades 

SELECT *
FROM Item_Factura
WHERE item_producto = '00001707'
AND item_numero = '00068711'
AND item_sucursal = '0003'
AND item_tipo = 'A'

/*
EJERCICIO N°10

Hacer un trigger que ante el intento de borrar un artículo verifique que no exista
stock y si es así lo borre en caso contrario que emita un mensaje de error.
*/

IF OBJECT_ID('TR_ELIMINAR_PRODUCTO') IS NOT NULL
	DROP TRIGGER TR_ELIMINAR_PRODUCTO
GO

CREATE TRIGGER TR_ELIMINAR_PRODUCTO
ON Producto INSTEAD OF DELETE
AS
BEGIN
	DECLARE @PRODUCTO CHAR(8)
	
	DECLARE C_PRODUCTO CURSOR FOR 
	SELECT prod_codigo FROM deleted
	
	OPEN C_PRODUCTO
	FETCH NEXT FROM C_PRODUCTO INTO @PRODUCTO
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @STOCK DECIMAL(12,2)
		
		SET @STOCK =
		(SELECT SUM(stoc_cantidad) 
		FROM STOCK
		WHERE stoc_producto = @PRODUCTO
		GROUP BY stoc_producto)
		
		IF @STOCK <= 0
			DELETE FROM Producto WHERE prod_codigo = @PRODUCTO
		ELSE
			RAISERROR('NO SE PUDO BORRAR EL PRODUCTO %s YA QUE TIENE STOCK', 16, 1, @PRODUCTO)
			 
		FETCH NEXT FROM C_PRODUCTO INTO @PRODUCTO
	END

	CLOSE C_PRODUCTO
	DEALLOCATE C_PRODUCTO
END
GO

--PRUEBA

-- Hago un listado de los productos con stock y agarro la primer fila que corresponde
-- al producto 00010417 con un stock total de 191767 unidades por lo tanto el trigger
-- no me deberia dejar borrarlo ya que el producto tiene stock

SELECT stoc_producto, SUM(stoc_cantidad) AS 'Total stock' 
FROM STOCK
GROUP BY stoc_producto
ORDER BY SUM(stoc_cantidad) DESC 

-- Cuando ejecuto el trigger me tira un mensaje de error que no se pudo realizar la accion
-- ya que el producto tiene stock

DELETE FROM Producto
WHERE prod_codigo = '00010417'

-- Verifico que el producto siga en la tabla de Productos

SELECT * 
FROM Producto
WHERE prod_codigo = '00010417'

-- Ahora inserto un producto de prueba sin stock disponible para eliminarlo y ver si el
-- trigger deja realizar la accion

INSERT INTO Producto VALUES('99999999', 'PRUEBA', 0.1, '001', '0001', 1)
INSERT INTO STOCK VALUES(0, 0, 100, NULL, NULL, '99999999', '00')

-- Verifico que se hayan realizado mis inserts

SELECT * 
FROM Producto
WHERE prod_codigo = '99999999'

SELECT * 
FROM STOCK
WHERE stoc_producto = '99999999'
AND stoc_deposito = '00'

-- Para ejecutar el DELETE primero desactivo la FK en stock ya que sino no me va a dejar
-- borrar el producto.

ALTER TABLE STOCK NOCHECK CONSTRAINT R_11

-- Hecho esto veo que cuando ejecuto el trigger me sale que una fila fue afectada y de paso
-- borro tambien la fila que habia creado en la tabla STOCK

DELETE FROM Producto
WHERE prod_codigo = '99999999'

DELETE FROM STOCK
WHERE stoc_producto = '99999999'
AND stoc_deposito = '00'

-- Vuelvo a activar la FK en la tabla STOCK para dejarlo como estaba

ALTER TABLE STOCK WITH CHECK CHECK CONSTRAINT R_11

-- Finalmente verifico que el producto ya no este en la tabla de Productos

SELECT * 
FROM Producto
WHERE prod_codigo = '99999999'

/*
EJERCICIO N°11

Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que sean
menores que su jefe directo.
*/

IF OBJECT_ID('FX_CANTIDAD_EMPLEADOS') IS NOT NULL
	DROP FUNCTION FX_CANTIDAD_EMPLEADOS
GO

CREATE FUNCTION FX_CANTIDAD_EMPLEADOS(@EMPLEADO NUMERIC(6,0))
	RETURNS INT
AS
BEGIN
	DECLARE @CANTIDAD_EMPLEADOS INT
	DECLARE @FECHA_NACIMIENTO_JEFE SMALLDATETIME

	SET @FECHA_NACIMIENTO_JEFE = 
	(SELECT empl_nacimiento 
	FROM Empleado
	WHERE empl_codigo = @EMPLEADO)

	SET @CANTIDAD_EMPLEADOS = 
	(SELECT 
	ISNULL(SUM(DBO.FX_CANTIDAD_EMPLEADOS(empl_codigo) + 1), 0)
	FROM Empleado
	WHERE empl_jefe = @EMPLEADO
	AND empl_nacimiento > @FECHA_NACIMIENTO_JEFE)
		
	RETURN @CANTIDAD_EMPLEADOS
END
GO

--PRUEBA

-- Hago un lista para ver los empleados directos y veo que los unicos empleados 
-- que son jefes son el empleado 1, 2 y 3. Primero voy a probar la funcion para
-- el empleado 1

SELECT empl_jefe, COUNT(*) AS 'Empleados directos'
FROM Empleado
WHERE empl_jefe IS NOT NULL
GROUP BY empl_jefe

-- Me fijo quienes son empleados directos del empleado 1 y a su vez son menores a el

SELECT * 
FROM Empleado
WHERE empl_jefe = 1
AND empl_nacimiento > '1978-01-01'

-- La consulta me devuelve que el unico que cumple con ambas condiciones es el 2
-- por lo tanto ahora veo los empleados directos y menores del 2 y los empleados 
--que me devuelva los voy a tener que sumar con los de la consulta anterior

SELECT * 
FROM Empleado
WHERE empl_jefe = 2
AND empl_nacimiento > '1979-01-05'

-- La consulta devolvio un solo empleado que es el 6. Por lo tanto hasta ahora el empleado 1
-- tiene un empleado directo que es el 2 y un indirecto que es el 6, ahora veo lo mismo para
-- el empleado 6

SELECT * 
FROM Empleado
WHERE empl_jefe = 6
AND empl_nacimiento > '1990-01-14'

-- Como no hay empleados que sean menores y directos del 6 entonces la funcion debera
-- devolver para el empleado 1 un valor igual a 2 que serian el empleado 2 (directo) y el
-- empleado 6 (indirecto del 1 y directo del 2). 

SELECT DBO.FX_CANTIDAD_EMPLEADOS(1)

-- Siguiendo esa logica para el empleado 2 la funcion deberia devolver uno que seria
-- solo el empleado directo 6

SELECT DBO.FX_CANTIDAD_EMPLEADOS(2)

-- Finalmente para el empleado 6 deberia devolver 0 ya que no tiene empleados

SELECT DBO.FX_CANTIDAD_EMPLEADOS(6)

/*
EJERCICIO N°12

Cree el/los objetos de base de datos necesarios para que nunca un producto pueda
ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se cumple y
que la base de datos es accedida por n aplicaciones de diferentes tipos y tecnologías.
No se conoce la cantidad de niveles de composición existentes.

ACLARACION: El trigger solo va a actuar cuando se realiza un INSERT. 
Si bien lo recomendable es que la PK nunca tenga que cambiar quise intentar que el trigger
tambien actue en caso de un UPDATE pero se hace bastante complejo ya que en caso
de que cambien la PK entera (comp_producto y comp_componente) no tengo forma de relacionar
las tablas inserted y deleted entre si a menos que cree una nueva PK asegurandome de que
esta nunca cambie, por lo tanto solo considero el evento INSERT, lo cual simplifico
mucho, igual dejo por las dudas el codigo del trigger que contemplaba INSERT y UPDATE 
comentado por si alguien quiere ojearlo.
*/

IF OBJECT_ID('TR_CONTROLAR_COMPOSICION') IS NOT NULL
	DROP TRIGGER TR_CONTROLAR_COMPOSICION
GO

CREATE TRIGGER TR_CONTROLAR_COMPOSICION
ON Composicion
INSTEAD OF INSERT
AS
	DECLARE @PRODUCTO_NUEVO CHAR(8)
	DECLARE @COMPONENTE_NUEVO CHAR(8)
	
	DECLARE C_COMPOSICION CURSOR FOR 
	SELECT inserted.comp_producto, inserted.comp_componente
	FROM inserted

	OPEN C_COMPOSICION
	FETCH NEXT FROM C_COMPOSICION INTO @PRODUCTO_NUEVO, @COMPONENTE_NUEVO

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @COMPONENTE_NUEVO != @PRODUCTO_NUEVO
		BEGIN
			INSERT INTO Composicion
			SELECT * FROM inserted
			WHERE comp_producto = @PRODUCTO_NUEVO
			AND comp_componente = @COMPONENTE_NUEVO
		END
		ELSE
			RAISERROR('EL PRODUCTO %s NO PUEDE ESTAR COMPUESTO POR SI MISMO', 16, 1, @PRODUCTO_NUEVO)
			
	FETCH NEXT FROM C_COMPOSICION INTO @PRODUCTO_NUEVO, @COMPONENTE_NUEVO
	END
	CLOSE C_COMPOSICION
	DEALLOCATE C_COMPOSICION
GO 

--PRUEBA

-- Elijo un producto compuesto como por ejemplo el producto 00001707 esta compuesto 
-- por dos 2 productos, el producto 00001491 y el 00014003 

SELECT * 
FROM Composicion
WHERE comp_producto = '00001707'

-- Primero pruebo con intentar insertar el producto 00001707 como componente
-- de si mismo, no me deberia dejar ya que no puede estar compuesto por si mismo 

INSERT INTO Composicion VALUES (2, '00001707', '00001707')

-- Compruebo que no se haya insertado el componente

SELECT * FROM Composicion WHERE comp_producto = '00001707'

-- Ahora pruebo con intentar insertar un componente distinto a si mismo 
-- para el producto 00001707 lo cual me deberia dejar hacer 

INSERT INTO Composicion VALUES (2, '00001707', '00001708')

-- Compruebo que se haya insertado el componente

SELECT * FROM Composicion WHERE comp_producto = '00001707'

-- Borro el componente de prueba

DELETE FROM Composicion 
WHERE comp_producto = '00001707' 
AND comp_componente = '00001708'

/* SOLUCION CONTEMPLANDO INSERT Y UPDATE (INCOMPLETO)

CREATE TRIGGER TR_CONTROLAR_COMPOSICION
ON Composicion
INSTEAD OF INSERT, UPDATE
AS
	DECLARE @PRODUCTO_NUEVO CHAR(8)
	DECLARE @COMPONENTE_NUEVO CHAR(8)
	DECLARE @ESTADO CHAR(1)

	IF EXISTS (SELECT * FROM deleted)
		SET @ESTADO = 'U'
	ELSE
		SET @ESTADO = 'I'
	
	DECLARE C_COMPOSICION CURSOR FOR 
	SELECT inserted.comp_producto, inserted.comp_componente,
	(SELECT deleted.comp_producto FROM deleted) 
	FROM inserted

	OPEN C_COMPOSICION
	FETCH NEXT FROM C_COMPOSICION INTO @PRODUCTO_NUEVO, @COMPONENTE_NUEVO

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @ESTADO = 'I'
		BEGIN	
			IF @COMPONENTE_NUEVO != @PRODUCTO_NUEVO
			BEGIN
				INSERT INTO Composicion
				SELECT * FROM inserted
				WHERE comp_producto = @PRODUCTO_NUEVO
				AND comp_componente = @COMPONENTE_NUEVO
			END
			ELSE
				RAISERROR('EL PRODUCTO %s NO PUEDE ESTAR COMPUESTO POR SI MISMO', 16, 1, @PRODUCTO_NUEVO)
		END
		ELSE
		BEGIN
			IF UPDATE(comp_producto) AND UPDATE(comp_componente)
				IF @PRODUCTO_NUEVO != @COMPONENTE_NUEVO
				BEGIN
					PRINT 'PROXIMAMENTE'
				END
			ELSE
			BEGIN
				DECLARE @PRODUCTO_ACTUAL CHAR(8)
				DECLARE @COMPONENTE_ACTUAL CHAR(8)
				IF UPDATE(comp_producto)
				BEGIN
					SET @PRODUCTO_ACTUAL = 
					(SELECT deleted.comp_producto 
					FROM deleted WHERE
					deleted.comp_producto = @PRODUCTO_NUEVO
					deleted.comp_componente = @COMPONENTE_NUEVO	
					IF @PRODUCTO_NUEVO != @COMPONENTE_NUEVO
					BEGIN
						UPDATE Composicion 
						SET comp_producto = @PRODUCTO_NUEVO					
						WHERE comp_producto = @PRODUCTO_ACTUAL AND
						comp_componente = @COMPONENTE_ACTUAL
					END
					ELSE
						RAISERROR('EL PRODUCTO %s NO PUEDE ESTAR COMPUESTO POR SI MISMO', 16, 1, @COMPONENTE_ACTUAL)
				END
				ELSE
					IF UPDATE(comp_componente)
						IF @PRODUCTO_ACTUAL != @COMPONENTE_NUEVO
						BEGIN
							UPDATE Composicion 
							SET comp_componente = @COMPONENTE_NUEVO					
							WHERE comp_producto = @PRODUCTO_ACTUAL AND
							comp_componente = @COMPONENTE_ACTUAL
						END
						ELSE
							RAISERROR('EL PRODUCTO %s NO PUEDE ESTAR COMPUESTO POR SI MISMO', 16, 1, @PRODUCTO_ACTUAL)
			END
		END
			
		FETCH NEXT FROM C_COMPOSICION INTO @PRODUCTO_NUEVO, @COMPONENTE_NUEVO
	END
	CLOSE C_COMPOSICION
	DEALLOCATE C_COMPOSICION
GO 
*/

/*
EJERCICIO N°13

Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de sus
empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha regla
se cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos y
tecnologías

ACLARACION: Solo contemple para el caso de UPDATES en la columna emp_salario por lo
tanto el trigger no tiene en cuenta si se modifica el jefe de un empleado y quizas
eso puede provocar que ese jefe este ganando mas del 20 % del total de los salarios de
sus empleados.
*/

IF OBJECT_ID('FX_SALARIO_EMPLEADOS') IS NOT NULL
	DROP FUNCTION FX_SALARIO_EMPLEADOS
GO

CREATE FUNCTION FX_SALARIO_EMPLEADOS(@EMPLEADO NUMERIC(6,0))
RETURNS DECIMAL(12,2)
AS
BEGIN
	DECLARE @SALARIO_EMPLEADOS DECIMAL(12,2)
	
	SET @SALARIO_EMPLEADOS = 
	ISNULL((SELECT SUM(DBO.FX_SALARIO_EMPLEADOS(empl_codigo) + empl_salario)
	FROM Empleado
	WHERE empl_jefe = @EMPLEADO), 0)
	
	RETURN @SALARIO_EMPLEADOS
END
GO

IF OBJECT_ID('TR_CONTROLAR_SALARIO') IS NOT NULL
	DROP TRIGGER TR_CONTROLAR_SALARIO
GO

CREATE TRIGGER TR_CONTROLAR_SALARIO
ON Empleado
INSTEAD OF UPDATE
AS
BEGIN
	IF UPDATE(empl_salario)
	BEGIN
		DECLARE @EMPLEADO NUMERIC(6,0)
		DECLARE @SALARIO_EMPLEADO DECIMAL(12,2)
		DECLARE @NUEVO_SALARIO_EMPLEADO DECIMAL(12,2)

		DECLARE C_EMPLEADO CURSOR FOR 
		SELECT d.empl_codigo, d.empl_salario, i.empl_salario 
		FROM deleted d
		JOIN inserted i ON d.empl_codigo = i.empl_codigo
		
		OPEN C_EMPLEADO
		
		FETCH NEXT FROM C_EMPLEADO INTO @EMPLEADO, @SALARIO_EMPLEADO, @NUEVO_SALARIO_EMPLEADO
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @NUEVO_SALARIO_EMPLEADO <= DBO.FX_SALARIO_EMPLEADOS(@EMPLEADO) * 0.2 OR
			(SELECT COUNT(*) FROM Empleado WHERE empl_jefe = @EMPLEADO) = 0
			BEGIN
				UPDATE Empleado
				SET empl_salario = @NUEVO_SALARIO_EMPLEADO
				WHERE empl_codigo = @EMPLEADO
			END
			ELSE
			BEGIN
				DECLARE @MENSAJE VARCHAR(10) = (SELECT CAST(@EMPLEADO AS VARCHAR(10)))
				RAISERROR('EL EMPLEADO %s NO PUEDE TENER UN SALARIO TAN ELEVADO RESPECTO DE SUS EMPLEADOS', 16, 1, @MENSAJE)
			END
		FETCH NEXT FROM C_EMPLEADO INTO @EMPLEADO, @SALARIO_EMPLEADO, @NUEVO_SALARIO_EMPLEADO
		END

		CLOSE C_EMPLEADO
		DEALLOCATE C_EMPLEADO
	END
END
GO 

--PRUEBA

-- Los unicos empleados que son jefes son el 1, 2 y el 3 y a la vez el 1 es jefe de 2 y 3
-- por lo tanto los empleados 2 y 3 no tienen empleados directos asi que me fijo cuanto
-- da la suma de los salarios de todos los empleados del 3 para probar la funcion

SELECT SUM(empl_salario) 
FROM Empleado
WHERE empl_jefe = 3

-- Como todos los empleados del 3 no tiene otros empleados la funcion deberia devolver 
-- 43700 que era la suma de los salarios de todos los empleados de 3

SELECT DBO.FX_SALARIO_EMPLEADOS(3)

-- Hago lo mismo para el empleado 2

SELECT SUM(empl_salario) 
FROM Empleado
WHERE empl_jefe = 1

-- Como todos los empleados del 2 no tiene otros empleados la funcion deberia devolver 
-- 3500 que era la suma de los salarios de todos los empleados de 2

SELECT DBO.FX_SALARIO_EMPLEADOS(2)

-- Por ultimo pruebo la funcion para el empleado 1 la cual deberia devolver la suma
-- de los salarios de los empleados 2 y 3 (da 25000) y a la vez la suma de los 
-- salarios de los empleados de estos dos ultimos por lo tanto la funcion deberia 
-- devolver 72200 (25000 + 43700 + 3500)

SELECT DBO.FX_SALARIO_EMPLEADOS(1)

-- Primero me fijo el salario de un empleado por ejemplo el del 3 y veo que cumple con la
-- condicion ya que 10000 es menor al 20% de 43700

SELECT * FROM Empleado
WHERE empl_codigo = 3

-- Para probar el trigger actualizo el salario del empleado 3 en uno que sea menor a
-- al 20% de la suma de los salarios de sus empleados (43700.00), es decir deberia
-- ser menor a 8740 (0.2 * 43700) y el trigger deberia dejarme hacer el cambio

UPDATE Empleado
SET empl_salario = 8740
WHERE empl_codigo = 3

-- Me fijo que se haya actualizado

SELECT * FROM Empleado
WHERE empl_codigo = 3

-- Ahora pruebo con una mayor a 8740 y el trigger no me deberia dejar

UPDATE Empleado
SET empl_salario = 8741
WHERE empl_codigo = 3

-- Me fijo que se haya actualizado

SELECT * FROM Empleado
WHERE empl_codigo = 3

-- Ahora pruebo con un empleado que no tenga empleados y el trigger me deberia dejar

UPDATE Empleado
SET empl_salario = 999999
WHERE empl_codigo = 6

-- Me fijo que se haya actualizado

SELECT * FROM Empleado
WHERE empl_codigo = 6

