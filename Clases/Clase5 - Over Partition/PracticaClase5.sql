/*repasar subselect
plan de ejecucion para performance
*/

-- over / partition
-- Dada la tabla cliente realizar consulta sql que al cliente que numere
-- de menor a mayor cada fila agregando el num de fila de la tabla, 
-- Considerando el num mas chico como 1
/*
cliente
nro_fila id nombre
   1     A  juan
   2     B  pepe
*/

SELECT c.clie_codigo as id, c.clie_razon_social as nombre, (SELECT COUNT(*) FROM Cliente c1 WHERE c1.clie_codigo <= c.clie_codigo) AS nro_fila 
FROM Cliente c 
ORDER BY c.clie_codigo

SELECT 
    ROW_NUMBER() OVER (ORDER BY c.clie_codigo ASC) AS num_fila,
    *
FROM Cliente c;

select ROW_NUMBER() over (order by c.clie_codigo desc) as num, *
from Cliente c;

/* Sintaxis de OVER
<función_de_ventana>() OVER ([PARTITION BY columna1, columna2, ...] [ORDER BY columna ASC|DESC])
Una particion es un conjunto de filas, conocido como grupo. Si se deja vacio selecciona todo

Permite aplicar funciones de grupo, sin que devuelva un grupo como group by. No altera los registros.
*/

SELECT 
    SUM(fact_total) OVER 
    		(
    		PARTITION BY 
    			fact_cliente
    		) AS SUMA,
    fact_cliente,
    fact_fecha 
FROM 
    Factura f 
ORDER BY 
	fact_cliente asc

-- Ejercicio de clase (10 de la guia)
