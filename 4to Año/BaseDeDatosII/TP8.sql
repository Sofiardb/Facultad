CREATE OR REPLACE FUNCTION modifica_stock( ) RETURNS TRIGGER AS $calcula_stock$
BEGIN
IF (tg_relname = 'tratamiento' ) THEN
	UPDATE medicamento SET stock = stock - new.dosis WHERE id_medicamento = new.id_medicamento;
ELSE
	UPDATE medicamento SET stock = stock + new.cantidad WHERE id_medicamento = new.id_medicamento;
END IF;
	RETURN NEW;
END;
$calcula_stock$ LANGUAGE plpgsql;


CREATE TRIGGER calcula_stock
BEFORE INSERT ON tratamiento FOR EACH ROW
EXECUTE PROCEDURE modifica_stock();

CREATE TRIGGER calcula_stock
BEFORE INSERT ON compra FOR EACH ROW
EXECUTE PROCEDURE modifica_stock();

SELECT * FROM proveedor;
INSERT INTO compra VALUES(3,2, CURRENT_DATE,1, 50000,60);

CREATE OR REPLACE FUNCTION actualiza_pago_factura( ) RETURNS TRIGGER AS $pago_factura$
DECLARE
	saldo_restante numeric(10,2);
BEGIN
SELECT saldo INTO saldo_restante FROM factura WHERE id_factura = new.id_factura;
IF(saldo_restante < new.monto) THEN
	RAISE EXCEPTION 'El monto no puede ser mayor al saldo adeudado';
ELSIF(saldo_restante = new.monto) THEN 
	UPDATE factura SET saldo = saldo - new.monto, pagada = 'S' WHERE id_factura = new.id_factura;
	RETURN NEW;
ELSE
	UPDATE factura SET saldo = saldo - new.monto WHERE id_factura = new.id_factura;
	RETURN NEW;
END IF;
END;
$pago_factura$ LANGUAGE plpgsql;

CREATE TRIGGER pago_factura
BEFORE INSERT ON pago 
FOR EACH ROW
EXECUTE PROCEDURE actualiza_pago_factura();

-- d

CREATE TABLE medicamento_reponer(
							id_medicamento integer,
							nombre VARCHAR(50),
							presentacion VARCHAR(50),
							stock integer,
							precio_ultimo NUMERIC(8,2),
							proveedor_ultimo VARCHAR(50)
);


CREATE OR REPLACE FUNCTION modifica_stock_medicamento( ) RETURNS TRIGGER AS $stock_medicamento_modificado$
DECLARE
	reg_control record;
	reg_compra record;
BEGIN
SELECT * INTO reg_control FROM medicamento_reponer WHERE id_medicamento = new.id_medicamento;
IF(new.stock < 50) THEN
	IF(reg_control.id_medicamento IS NULL) THEN
		SELECT precio_unitario, proveedor INTO reg_compra FROM compra INNER JOIN proveedor USING(id_proveedor) 
		WHERE id_medicamento = new.id_medicamento ORDER BY fecha DESC LIMIT 1;
		INSERT INTO medicamento_reponer 
		VALUES(new.id_medicamento, new.nombre, new.presentacion, new.stock, reg_compra.precio_unitario, reg_compra.proveedor);
	ELSE 
		UPDATE medicamento_reponer SET stock = new.stock WHERE id_medicamento = new.id_medicamento;
	END IF;
END IF;
RETURN NEW;
END;
$stock_medicamento_modificado$ LANGUAGE plpgsql;

CREATE TRIGGER stock_medicamento_modificado
AFTER UPDATE OF stock ON medicamento
FOR EACH ROW
WHEN (new.stock < old.stock)
EXECUTE PROCEDURE modifica_stock_medicamento();

-- e



CREATE OR REPLACE FUNCTION reposicion_medicamento() RETURNS TRIGGER AS $stock_medicamento_modificado$
DECLARE
	reg_control record;
	reg_compra record;
BEGIN
SELECT * INTO reg_control FROM medicamento_reponer WHERE id_medicamento = new.id_medicamento;
IF(reg_control.id_medicamento IS NOT NULL) THEN		
	IF(new.stock  > 50) THEN
		DELETE FROM medicamento_reponer WHERE id_medicamento = new.id_medicamento;
	ELSE 
		UPDATE medicamento_reponer SET stock = new.stock WHERE id_medicamento = new.id_medicamento;
	END IF;
END IF;
RETURN NEW;
END;
$stock_medicamento_modificado$ LANGUAGE plpgsql;

CREATE TRIGGER stock_medicamento_aumento
AFTER UPDATE OF stock ON medicamento
FOR EACH ROW
WHEN (new.stock > old.stock)
EXECUTE PROCEDURE reposicion_medicamento();

-- e

CREATE TABLE facturacion_pendiente(
				id_paciente integer,
				nombre VARCHAR(100),
				apellido VARCHAR(100),
				practica text,
				costo NUMERIC(11,2),
				fecha DATE
);


CREATE OR REPLACE FUNCTION facturacion_paciente() RETURNS TRIGGER AS $agregar_factura_pendiente$
DECLARE
	reg_control record;
	reg_persona record;
BEGIN
IF(tg_relname = 'tratamiento') THEN
	SELECT * INTO reg_control FROM facturacion_pendiente WHERE id_paciente = new.id_paciente AND practica = 'tratamiento'; 
	IF reg_control.id_paciente IS NULL THEN
		SELECT id_persona, nombre, apellido INTO reg_persona FROM persona WHERE id_persona = new.id_paciente;
		INSERT INTO facturacion_pendiente VALUES(new.id_paciente, reg_persona.nombre, reg_persona.apellido, 'tratamiento', new.costo, CURRENT_DATE);
	ELSE
		UPDATE facturacion_pendiente SET costo = costo + new.costo WHERE id_paciente = new.id_paciente AND practica = 'tratamiento';
	END IF;
ELSIF(tg_relname = 'estudio_realizado') THEN
	SELECT * INTO reg_control FROM facturacion_pendiente WHERE id_paciente = new.id_paciente AND practica = 'estudio'; 
	IF reg_control.id_paciente IS NULL THEN
		SELECT id_persona, nombre, apellido INTO reg_persona FROM persona WHERE id_persona = new.id_paciente;
		INSERT INTO facturacion_pendiente VALUES(new.id_paciente, reg_persona.nombre, reg_persona.apellido, 'estudio', new.precio, CURRENT_DATE);
	ELSE
		UPDATE facturacion_pendiente SET costo = costo + new.precio WHERE id_paciente = new.id_paciente AND practica = 'estudio';
	END IF;
ELSE
	SELECT * INTO reg_control FROM facturacion_pendiente WHERE id_paciente = new.id_paciente AND practica = 'internación'; 
	IF reg_control.id_paciente IS NULL THEN
		SELECT id_persona, nombre, apellido INTO reg_persona FROM persona WHERE id_persona = new.id_paciente;
		INSERT INTO facturacion_pendiente VALUES(new.id_paciente, reg_persona.nombre, reg_persona.apellido, 'internación', new.costo, CURRENT_DATE);
	ELSE
		UPDATE facturacion_pendiente SET costo = costo + new.costo WHERE id_paciente = new.id_paciente AND practica = 'internación';
	END IF;
END IF;
RETURN NEW;
END;
$agregar_factura_pendiente$ LANGUAGE plpgsql;

CREATE TRIGGER facturacion_tratamiento
AFTER INSERT ON tratamiento
FOR EACH ROW EXECUTE PROCEDURE facturacion_paciente();

CREATE TRIGGER facturacion_internacion
AFTER INSERT ON internacion
FOR EACH ROW EXECUTE PROCEDURE facturacion_paciente();

CREATE TRIGGER facturacion_estudio
AFTER INSERT ON estudio_realizado
FOR EACH ROW EXECUTE PROCEDURE facturacion_paciente();

-- g

CREATE OR REPLACE PROCEDURE paciente_factura_nueva(p_dni text) AS $$
DECLARE
	id_paciente_s integer;
BEGIN
IF p_dni IS NULL OR TRIM(p_dni) = '' THEN
	RAISE EXCEPTION 'El dni del paciente no puede ser nulo o vacio';
END IF;
SELECT id_persona INTO id_paciente_s FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE p.dni = p_dni;
IF NOT FOUND THEN
	RAISE EXCEPTION 'No existe el paciente al que desea realizarle la factura';
END IF;

IF EXISTS(SELECT 1 FROM facturacion_pendiente WHERE id_paciente = id_paciente_s) THEN
	INSERT INTO factura VALUES((SELECT MAX(id_factura) + 1 FROM factura), id_paciente_s,
								CURRENT_DATE, CURRENT_TIME, (SELECT SUM(costo) FROM facturacion_pendiente WHERE id_paciente = id_paciente_s),
								'N', (SELECT SUM(costo) FROM facturacion_pendiente WHERE id_paciente = id_paciente_s));
ELSE
	RAISE NOTICE 'El paciente no tiene facturas pendientes';
END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Ocurrió un error inesperado %', SQLERRM;
END;
$$ LANGUAGE plpgsql;