-- 1ª funcion
delimiter $$
CREATE FUNCTION CalcularTotalPedido(ID_PEDIDO INT)
RETURNS FLOAT
BEGIN
    DECLARE Total FLOAT;
    SELECT Total = SUM(CANTIDAD * PRECIO)
    FROM LINEADEPEDIDOS
    WHERE ID_PEDIDO = ID_PEDIDO;
    RETURN Total;
end $$ 
delimiter ;

-- ----------------------------------------------------------------------------------------------
-- 2ª funcion 
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
    SET Total = dbo.CalcularTotalPedido(ID_PEDIDO);

    -- Aplicar el descuento
    SET TotalConDescuento = @Total - (Total * PorcentajeDescuento / 100);

    RETURN TotalConDescuento;
end $$ 
delimiter ;

-- ----------------------------------------------------------------------------------------------
-- 1º procedimiento 
delimiter $$
CREATE PROCEDURE ObtenerEdadPersona
    ID_PERSONA INT,
    Edad INT OUTPUT
BEGIN
    declare FechaNacimiento DATE;
    SELECT FechaNacimiento = FECHANACIMIENTO 
    FROM PERSONAS 
    WHERE ID_PERSONA = ID_PERSONA;
    
    SET Edad = dbo.CalcularEdad(@FechaNacimiento);
end $$ 
delimiter ;

-- ----------------------------------------------------------------------------------------------

-- 2º procedimiento 
delimiter $$
CREATE TRIGGER ActualizarPrecioProductosRelacionados
ON PRODUCTOS
AFTER UPDATE
AS
BEGIN
    UPDATE LINEADEPEDIDOS
    SET PRECIO = inserted.PRECIOPVP * LINEADEPEDIDOS.CANTIDAD
    FROM LINEADEPEDIDOS
    INNER JOIN inserted ON LINEADEPEDIDOS.ID_PRODUCTO = inserted.ID_PRODUCTO
end $$ 
delimiter ;

-- 3º procedimiento
delimiter $$
CREATE PROCEDURE ListarPedidosYTotales
AS
BEGIN
    SELECT P.ID_PEDIDO, P.ID_PERSONA, P.FECHAPEDIDO, dbo.CalcularTotalPedido(P.ID_PEDIDO) AS Total
    FROM PEDIDOS P;
end $$ 
delimiter ;

-- ----------------------------------------------------------------------------------------------
-- 1º trigger 
delimiter $$
CREATE TRIGGER RegistroCambiosInstitutos
ON INSTITUTOS
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted)  -- Comprueba si se ha realizado una inserción o actualización
    BEGIN
        INSERT INTO RegistroCambiosInstitutos (Accion, FechaHora)
        VALUES ('Insercion/Actualizacion', GETDATE());
    END
    ELSE IF EXISTS (SELECT * FROM deleted)  -- Comprueba si se ha realizado una eliminación
    BEGIN
        INSERT INTO RegistroCambiosInstitutos (Accion, FechaHora)
        VALUES ('Eliminacion', GETDATE());
    END
end $$ 
delimiter ;

-- ----------------------------------------------------------------------------------------------
-- 2º trigger 
delimiter $$
CREATE TRIGGER ActualizarPrecioProductosRelacionados
ON PRODUCTOS
AFTER UPDATE
AS
BEGIN
    UPDATE LINEADEPEDIDOS
    SET PRECIO = inserted.PRECIOPVP * LINEADEPEDIDOS.CANTIDAD
    FROM LINEADEPEDIDOS
    INNER JOIN inserted ON LINEADEPEDIDOS.ID_PRODUCTO = inserted.ID_PRODUCTO
end $$ 
delimiter ;


