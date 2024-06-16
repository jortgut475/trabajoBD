use buffalos;

-- consultas y multiconsultas

-- 1º consulta 
-- Obtener la cantidad total de productos vendidos por cada instituto, 
-- mostrando el nombre del instituto y 
-- la suma de las cantidades de productos vendidos.
SELECT I.NOMBRE AS INSTITUTO, SUM(LP.CANTIDAD) AS TOTAL_PRODUCTOS_VENDIDOS 
FROM INSTITUTOS I 
INNER JOIN BUFFALOS B ON I.ID_INSTITUTO = B.ID_INSTITUTO 
INNER JOIN PEDIDOS PE ON B.ID_PERSONA = PE.ID_PERSONA 
INNER JOIN LINEADEPEDIDOS LP ON PE.ID_PEDIDO = LP.ID_PEDIDO 
GROUP BY I.NOMBRE;

-- 2º consulta
-- Contar la cantidad de monitores por cada tipo de actividad que realizan, 
-- mostrando el nombre de la actividad y 
-- la cantidad de monitores.
SELECT A.NOMBRE AS ACTIVIDAD, COUNT(MA.ID_PERSONA) AS CANTIDAD_MONITORES 
FROM ACTIVIDADES A 
LEFT JOIN MONITORESACTIVIDADES MA ON A.ID_ACTIVIDAD = MA.ID_ACTIVIDAD 
GROUP BY A.NOMBRE;

-- 3º consulta
-- Encontrar el instituto que tiene el precio promedio 
-- más alto de los paquetes que ofrece, 
-- mostrando el nombre del instituto y el precio promedio.
SELECT I.NOMBRE AS INSTITUTO, AVG(P.PRECIO) AS PRECIO_PROMEDIO_PAQUETE 
FROM INSTITUTOS I
INNER JOIN PAQUETES P ON I.ID_PAQUETE = P.ID_PAQUETE 
GROUP BY I.NOMBRE 
ORDER BY PRECIO_PROMEDIO_PAQUETE 
DESC LIMIT 1;

-- 4º consulta
-- Obtener los nombres de los monitores que han adquirido productos con un precio 
-- superior al precio promedio de todos los productos, 
-- mostrando el nombre completo del monitor
SELECT DISTINCT P.NOMBRE, P.APELLIDOS 
FROM PERSONAS P 
INNER JOIN MONITORES M ON P.ID_PERSONA = M.ID_PERSONA 
INNER JOIN PEDIDOS PE ON P.ID_PERSONA = PE.ID_PERSONA 
INNER JOIN LINEADEPEDIDOS LP ON PE.ID_PEDIDO = LP.ID_PEDIDO 
INNER JOIN PRODUCTOS PR ON LP.ID_PRODUCTO = PR.ID_PRODUCTO 
WHERE PR.PRECIOPVP > (SELECT AVG(PRECIOPVP) FROM PRODUCTOS);

-- 5º consulta
-- Identificar el instituto que ha realizado la mayor cantidad de pedidos en un mes específico, 
-- mostrando el nombre del instituto 
-- y la cantidad de pedidos realizados.
SELECT I.NOMBRE AS INSTITUTO, COUNT(PE.ID_PEDIDO) AS CANTIDAD_PEDIDOS 
FROM INSTITUTOS I 
INNER JOIN BUFFALOS B ON I.ID_INSTITUTO = B.ID_INSTITUTO 
INNER JOIN PEDIDOS PE ON B.ID_PERSONA = PE.ID_PERSONA 
WHERE MONTH(PE.FECHAPEDIDO) = 3 -- Cambiar el número del mes según 
-- corresponda 
GROUP BY I.NOMBRE 
ORDER by CANTIDAD_PEDIDOS 
DESC LIMIT 1;

-- vistas 

-- 1ª vista 
-- Vista cantidad_monitores a través de Contar la cantidad de monitores 
-- por cada tipo de actividad que realizan, 
-- mostrando el nombre de la actividad y la cantidad de monitores.
create view cantidad_monitores as
SELECT A.NOMBRE AS ACTIVIDAD, COUNT(MA.ID_PERSONA) AS CANTIDAD_MONITORES
FROM ACTIVIDADES A
LEFT JOIN MONITORESACTIVIDADES MA ON A.ID_ACTIVIDAD = MA.ID_ACTIVIDAD
GROUP BY A.NOMBRE;

-- 2ª vista 
-- vista de cantidad_pedidos para identificar el instituto que 
-- ha realizado la mayor cantidad de pedidos en un mes específico, 
-- mostrando el nombre del instituto y la cantidad de pedidos realizados.
create view cantidad_pedidos as
SELECT I.NOMBRE AS INSTITUTO, COUNT(PE.ID_PEDIDO) AS CANTIDAD_PEDIDOS
FROM INSTITUTOS I
INNER JOIN BUFFALOS B ON I.ID_INSTITUTO = B.ID_INSTITUTO
INNER JOIN PEDIDOS PE ON B.ID_PERSONA = PE.ID_PERSONA
WHERE MONTH(PE.FECHAPEDIDO) = 3  -- Cambiar el número del mes según corresponda
GROUP BY I.NOMBRE
ORDER BY CANTIDAD_PEDIDOS DESC
LIMIT 1;

-- funciones 

-- 1ª funcion
-- Funcion que calcule el precio total de un pedido
delimiter $$
CREATE FUNCTION CalcularTotalPedido(ID_PEDIDO INT)
RETURNS FLOAT
deterministic 
BEGIN
    DECLARE Total FLOAT;
    SELECT SUM(CANTIDAD * PRECIO) INTO Total
    FROM LINEADEPEDIDOS
    WHERE ID_PEDIDO = ID_PEDIDO;
    RETURN Total;
END $$
delimiter ;

-- 2ª funcion
-- Función calculará el descuento aplicado a un pedido basado 
-- en el total de la compra y un porcentaje de descuento proporcionado
delimiter $$
CREATE FUNCTION CalcularTotalConDescuento(
    ID_PEDIDO INT,
    PorcentajeDescuento FLOAT
)
RETURNS FLOAT
deterministic 
BEGIN
    DECLARE Total FLOAT;
    DECLARE TotalConDescuento FLOAT;

    -- Calcular el total del pedido usando la función existente CalcularTotalPedido
	select CalcularTotalPedido(ID_PEDIDO) into Total;

    -- Aplicar el descuento
    SET TotalConDescuento = Total - (Total * PorcentajeDescuento / 100);

    RETURN TotalConDescuento;
end$$ 
delimiter ;


-- procedimientos(1 de ellos cursor)

-- 1º procedure 
--Procedimiento para listar todos los pedidos y 
-- sus totales usando la función “calcularTotalPedido”
DELIMITER $$
drop procedure if exists ListarPedidosYTotales$$
CREATE PROCEDURE ListarPedidosYTotales()
BEGIN
    DECLARE TotalPedidos DECIMAL(10,2);

    SELECT P.ID_PEDIDO, P.ID_PERSONA, P.FECHAPEDIDO, CalcularTotalPedido(P.ID_PEDIDO) AS Total
    FROM PEDIDOS P;

    SELECT SUM(CalcularTotalPedido(P.ID_PEDIDO)) INTO TotalPedidos
    FROM PEDIDOS P;

    SELECT 'Total Pedidos:' AS Mensaje, TotalPedidos AS Total;
END $$

DELIMITER ;

-- 2º procedure 
-- Procedimiento que muestra los detalles de un pedido específico. 
-- Este procedimiento seleccionará y mostrará la información 
-- de cada línea de pedido asociada con un pedido dado.

DELIMITER $$

CREATE PROCEDURE MostrarDetallesPedido(IN pedido_id INT)
BEGIN
    -- Mostrar los detalles del pedido
    SELECT 
        p.NOMBRE AS Producto,
        lp.CANTIDAD AS Cantidad,
        lp.PRECIO AS Precio,
        (lp.CANTIDAD * lp.PRECIO) AS Subtotal
    FROM 
        LINEADEPEDIDOS lp
    JOIN 
        PRODUCTOS p ON lp.ID_PRODUCTO = p.ID_PRODUCTO
    WHERE 
        lp.ID_PEDIDO = pedido_id;
END $$

DELIMITER ;

-- 3º procedure (Usando cursores)
-- Procedimiento que te muestre los productos 
-- con su id, nombre y descripción. (Cursor)
DELIMITER $$
drop procedure if exists MostrarProductos$$
CREATE PROCEDURE MostrarProductos()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE producto_id INT;
    DECLARE producto_nombre VARCHAR(50);
    DECLARE producto_descripcion VARCHAR(250);
	declare salida varchar(5000) default '';

    -- Declaro el cursor
    DECLARE productos_cursor CURSOR FOR
        SELECT ID_PRODUCTO, NOMBRE, DESCRIPCION
        FROM PRODUCTOS;

    -- Declaro el controlador
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;

   	set salida=concat(salida, '----Procesando productos chachis del campamento:----\n');
 	set salida=concat(salida, 'Id','\t\t','nombre','\t\t\t\t\t','descripcion','\n');
   
  -- Abro el cursor
    OPEN productos_cursor;

    -- Obtengo las filas por cada cursor
    fetch_loop: LOOP
        FETCH productos_cursor INTO producto_id, producto_nombre, producto_descripcion;

        IF done THEN
            LEAVE fetch_loop;
        END IF;

        -- agrego los detalles del producto a la salida
        set salida= CONCAT(salida, producto_id, '\t\t', producto_nombre, '\t\t\t\t', producto_descripcion, '\n');
    END LOOP;

    -- Cierro el cursor 
    CLOSE productos_cursor;

    -- muestro la salida 
    SELECT salida;
END $$

DELIMITER ;

-- triggers 

-- 1º trigger
-- Trigger que se ejecutará antes de insertar un nuevo registro en la tabla PERSONAS y realiza dos validaciones:
-- 		-Comprueba que el DNI no esté duplicado.
-- 		-Asegura que la fecha de nacimiento no sea anterior al 1 de enero de 1900.

delimiter $$
CREATE TRIGGER TR_INSERTAR_PERSONA
BEFORE INSERT ON PERSONAS
FOR EACH ROW
BEGIN
    -- Validar que el DNI no esté duplicado
    IF (SELECT COUNT(*) FROM PERSONAS WHERE DNI = NEW.DNI) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El DNI ingresado ya existe en la tabla PERSONAS.';
    END IF;

    -- Validar que la fecha de nacimiento sea mayor a 1900-01-01
    IF NEW.FECHANACIMIENTO < '1900-01-01' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de nacimiento no puede ser anterior a 1900-01-01.';
    END IF;
end$$
delimiter ;


-- 2º trigger
-- Trigger que actualiza el precio de los productos relacionados en la tabla LINEADEPEDIDOS 
-- cada vez que se actualiza el precio de un producto en la tabla PRODUCTOS. 
DELIMITER $$
drop trigger if exists ActualizarPrecioProductosRelacionados$$

CREATE TRIGGER ActualizarPrecioProductosRelacionados
AFTER UPDATE ON PRODUCTOS
FOR EACH ROW
BEGIN
    IF NEW.PRECIOPVP <> OLD.PRECIOPVP THEN
        UPDATE LINEADEPEDIDOS
        SET PRECIO = NEW.PRECIOPVP
        WHERE ID_PRODUCTO = NEW.ID_PRODUCTO;
    END IF;
END $$

DELIMITER ;



