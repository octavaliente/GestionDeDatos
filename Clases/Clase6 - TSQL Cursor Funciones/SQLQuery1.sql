BEGIN
	
	declare @var1 char(100)
	declare @var2 int 
	
	set @var2 = 1 + 2 
	set @var1 = 'Hola Mundo'
	
	print @var2
	print @var1 
	
END

BEGIN
	
	declare @v_cod char(5)
	declare @v_nombre char(100) 
	
	set @v_cod = '00000'
	
	select 
		 @v_nombre = clie_razon_social 
	from cliente 
	where 
		clie_codigo =  @v_cod
		
	print @v_nombre
	
END

CREATE view VIEW_EJEMPLO ( COD , NOMBRE, TOTAL  )
AS

	SELECT 
		c.clie_codigo ,
		c.clie_razon_social,
		sum(fact_total)
	FROM Cliente c JOIN Factura f 
		ON c.clie_codigo = f.fact_cliente 
	group by 
		c.clie_codigo ,
		c.clie_razon_social

create view VIEW_year_clie ( cod_clie , anio, total_anio  )
AS

	SELECT 
		fact_cliente ,
		year(fact_fecha),
		sum(fact_total)
	FROM Factura f 
	group by 
		fact_cliente,
		year(fact_fecha)

select * from VIEW_EJEMPLO 
			right  join cliente on clie_codigo = cod 
				   join VIEW_year_clie 
				   	on cod_clie = cod
order by 
	TOTAL desc

alter view VIEW_EJEMPLO ( COD , NOMBRE, TOTAL  )
AS

	SELECT 
		c.clie_codigo ,
		c.clie_razon_social,
		(fact_total)
	FROM Cliente c JOIN Factura f 
		ON c.clie_codigo = f.fact_cliente

update VIEW_EJEMPLO 
	set 
		nombre = 'Modificado por view'
	where 
		COD = '00000'

CREATE FUNCTION fnc_cuadrado(  @param1 decimal(12,2)  )
RETURNS decimal(14,4) 
AS
BEGIN
	declare @result decimal(12,2) 
	
	set @result = @param1 * @param1
	return @result 
	
	
END;

select dbo.fnc_cuadrado(12)


select 
	clie_codigo, 
	dbo.fnc_cuadrado(clie_limite_credito),
	clie_limite_credito
from Cliente c

create function fnc_tabla1 (@codigo char(6)) 
RETURNS TABLE 
AS 

	RETURN (SELECT * FROM CLIENTE WHERE clie_codigo != @codigo);
select * from dbo.fnc_tabla1('00000')
order by 
	clie_razon_social desc

--------------- CURSORES
--puntero a una fila. recorrer filas de consultas sql

DECLARE @cod char(5)
	DECLARE @nombre char(100)
	
	DECLARE mi_cursor CURSOR FOR 
		SELECT 
			clie_codigo ,
			clie_razon_social 
		FROM Cliente c 
		ORDER BY
			clie_codigo DESC 
			
	OPEN mi_cursor 
	fetch mi_cursor into @cod, @nombre
	
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		PRINT @NOMBRE
		fetch mi_cursor into @cod, @nombre
	END 
	CLOSE mi_cursor 
	DEALLOCATE mi_cursor

DECLARE @cod char(5)
	DECLARE @nombre char(100)
	
	DECLARE mi_cursor CURSOR  FOR 
		SELECT 
			clie_codigo ,
			clie_razon_social 
		FROM Cliente c 
		ORDER BY
			clie_codigo DESC 
	FOR UPDATE OF 
		clie_razon_social 
			
	OPEN mi_cursor 
	fetch mi_cursor into @cod, @nombre
	
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		IF @cod = '00000'
		BEGIN 
			UPDATE CLIENTE 
				SET clie_razon_social = 'CAMBIADO FOR UDPATE CURSOR'
			WHERE 
				CURRENT OF MI_CURSOR 
		END 	
		fetch mi_cursor into @cod, @nombre
	END 
	CLOSE mi_cursor 
	DEALLOCATE mi_cursor

-- Ejercicio 1

create function stock_tabla (@cod_prod decimal (12,2), @cod_depo decimal(12,2))
returns char(20) as 
begin
	select * from STOCK as s
	where s.stoc_producto = @cod_prod && s.stoc_deposito = @cod_depo
end