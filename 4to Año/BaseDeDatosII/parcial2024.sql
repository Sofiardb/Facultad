CREATE TYPE compras_realizadas AS (
									medicamento VARCHAR(50),
									cantidad smallint,
									fecha_compra DATE,
									precio numeric(10,2),
									proveedor VARCHAR(50)
);

CREATE OR REPLACE FUNCTION fn_compra(p_medicamento text, p_proveedor text, p_id_empleado int, p_precio numeric, p_cantidad int, p_op char) returns setof compras_realizadas AS $$
DECLARE 
	fila record;
BEGIN
IF(p_medicamento IS NULL OR TRIM(p_medicamento) = '') THEN
	RAISE EXCEPTION 'El nombre del medicamento no puede ser nulo ni vacío';
END IF;
IF(p_proveedor IS NULL OR TRIM(p_proveedor) = '') THEN
	RAISE EXCEPTION 'El nombre del proveedor no puede ser nulo ni vacío';
END IF;
IF(p_id_empleado IS NULL OR p_cantidad IS NULL OR p_precio IS NULL) THEN
	RAISE EXCEPTION 'El id del empleado, la cantidad y el precio ingresado no pueden ser nulos';
END IF;
IF (p_precio < 0 OR p_cantidad < 0) THEN
	RAISE EXCEPTION 'El precio y/o cantidad ingresada no pueden ser negativos';
END IF;
IF NOT EXISTS(SELECT 1 FROM medicamento WHERE nombre = p_medicamento) THEN
	RAISE EXCEPTION 'El medicamento que desea compra no existe';
END IF;
IF NOT EXISTS(SELECT 1 FROM proveedor WHERE proveedor = p_proveedor) THEN
	RAISE EXCEPTION 'El proveedor ingresado no está registrado';
END IF;
IF NOT EXISTS(SELECT 1 FROM empleado WHERE id_empleado = p_id_empleado) THEN
	RAISE EXCEPTION 'El empleado ingresado no existe';
END IF;
IF EXISTS(SELECT 1 FROM compra c INNER JOIN medicamento m USING (id_medicamento)
						INNER JOIN proveedor p USING (id_proveedor) WHERE m.nombre = p_medicamento AND p.proveedor = p_proveedor AND c.fecha = CURRENT_DATE) THEN
	RAISE EXCEPTION 'No es posible realizar la compra de un medicamento a un mismo proveedor dos veces en el mismo dia';
END IF;
INSERT INTO compra VALUES((SELECT id_medicamento FROM medicamento WHERE nombre = p_medicamento),
							(SELECT id_proveedor FROM proveedor WHERE proveedor = p_proveedor),
							CURRENT_DATE, p_id_empleado, p_precio, p_cantidad);

IF NOT FOUND THEN
	RAISE EXCEPTION 'No se pudo llevar a cabo la inserción';
END IF;

CASE p_op
	WHEN 'M' THEN
		RETURN QUERY (SELECT m.nombre, c.cantidad, c.fecha, c.precio_unitario, p.proveedor FROM compra c
						INNER JOIN medicamento m USING (id_medicamento)
						INNER JOIN proveedor p USING (id_proveedor) 
						WHERE m.nombre = p_medicamento
						ORDER BY c.fecha DESC);
	WHEN 'P' THEN
		RETURN QUERY (SELECT m.nombre, c.cantidad, c.fecha, c.precio_unitario, p.proveedor FROM compra c
						INNER JOIN medicamento m USING (id_medicamento)
						INNER JOIN proveedor p USING (id_proveedor) 
						WHERE p.proveedor = p_proveedor
						ORDER BY c.fecha DESC);
	ELSE
		RETURN QUERY (SELECT m.nombre, c.cantidad, c.fecha, c.precio_unitario, p.proveedor FROM compra c
						INNER JOIN medicamento m USING (id_medicamento)
						INNER JOIN proveedor p USING (id_proveedor)
						ORDER BY c.fecha DESC);
			
END CASE;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Ha ocurrido un error inesperado %', SQLERRM;
END;
$$ language plpgsql;
SELECT * FROM medicamento;
SELECT * FROM fn_compra('TREUPEL - N NIN', 'QUIMICA SUIZA S.A.', 1, 50000,60,'E');


CREATE TABLE practicas_x_paciente (
									id_paciente integer,
									nombre VARCHAR(100),
									apellido VARCHAR(100),
									practica VARCHAR(20),
									cantidad integer,
									fecha DATE);
CREATE FUNCTION registrar_practicas() RETURNS TRIGGER AS $$
BEGIN
IF(tg_relname = 'consulta') THEN
	IF EXISTS(SELECT 1 FROM practicas_x_paciente WHERE id_paciente = new.id_paciente AND practica = 'Consulta') THEN
		UPDATE practicas_x_paciente SET cantidad = cantidad + 1, fecha = CURRENT_DATE WHERE id_paciente = new.id_paciente AND practica = 'Consulta';
	ELSE
		INSERT INTO practicas_x_paciente VALUES(new.id_paciente, (SELECT nombre FROM persona WHERE id_persona = new.id_paciente), 
										(SELECT apellido FROM persona WHERE id_persona = new.id_paciente), 'Consulta', 1, new.fecha);
	END IF;
ELSIF (tg_relname = 'internacion') THEN
	IF EXISTS(SELECT 1 FROM practicas_x_paciente WHERE id_paciente = new.id_paciente AND practica = 'Internacion') THEN
		UPDATE practicas_x_paciente SET cantidad = cantidad + 1, fecha = CURRENT_DATE WHERE id_paciente = new.id_paciente AND practica = 'Internacion';
	ELSE
		INSERT INTO practicas_x_paciente VALUES(new.id_paciente, (SELECT nombre FROM persona WHERE id_persona = new.id_paciente), 
										(SELECT apellido FROM persona WHERE id_persona = new.id_paciente), 'Internacion', 1, new.fecha_inicio);
	END IF;
ELSIF (tg_relname = 'estudio_realizado') THEN
	IF EXISTS(SELECT 1 FROM practicas_x_paciente WHERE id_paciente = new.id_paciente AND practica = 'Estudio') THEN
		UPDATE practicas_x_paciente SET cantidad = cantidad + 1, fecha = CURRENT_DATE WHERE id_paciente = new.id_paciente AND practica = 'Estudio';
	ELSE
		INSERT INTO practicas_x_paciente VALUES(new.id_paciente, (SELECT nombre FROM persona WHERE id_persona = new.id_paciente), 
										(SELECT apellido FROM persona WHERE id_persona = new.id_paciente), 'Estudio', 1, new.fecha);
	END IF;
END IF;
	RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER inserta_consulta
AFTER INSERT ON consulta
FOR EACH ROW
EXECUTE PROCEDURE registrar_practicas();

CREATE TRIGGER inserta_estudio
AFTER INSERT ON estudio_realizado
FOR EACH ROW
EXECUTE PROCEDURE registrar_practicas();

CREATE TRIGGER inserta_internacion
AFTER INSERT ON internacion
FOR EACH ROW
EXECUTE PROCEDURE registrar_practicas();

CREATE TABLE personas_borradas(id SERIAL NOT NULL,
								id_persona integer NOT NULL,
								nombre VARCHAR(100) NOT NULL,
								apellido VARCHAR(100) NOT NULL,
								dni VARCHAR(8) NOT NULL,
								tipo VARCHAR(10) NOT NULL,
								fecha_eliminacion TIMESTAMP NOT NULL,
								usuario text NOT NULL);

CREATE OR REPLACE FUNCTION auditar_personas_borradas() RETURNS TRIGGER AS $$
BEGIN
IF EXISTS(SELECT 1 FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE id_persona = old.id_persona) THEN
	DELETE FROM pago p USING factura f WHERE p.id_factura = f.id_factura AND f.id_paciente = old.id_persona;
	DELETE FROM factura f WHERE id_paciente = old.id_persona;
	DELETE FROM diagnostico d WHERE d.id_paciente = old.id_persona;
	DELETE FROM consulta WHERE id_paciente = old.id_persona;
	DELETE FROM internacion WHERE id_paciente = old.id_persona;
	DELETE FROM estudio_realizado WHERE id_paciente = old.id_persona;
	DELETE FROM tratamiento WHERE id_paciente = old.id_persona;
	DELETE FROM paciente WHERE id_paciente = old.id_persona;
	INSERT INTO personas_borradas VALUES(default, old.id_persona, old.nombre, old.apellido, old.dni, 'Paciente', NOW(), USER);
END IF;
IF EXISTS(SELECT 1 FROM persona p INNER JOIN empleado e ON p.id_persona = e.id_empleado WHERE id_persona = old.id_persona) THEN
	DELETE FROM trabajan WHERE id_empleado = old.id_persona;
	DELETE FROM compra WHERE id_empleado = old.id_persona;
	DELETE FROM diagnostico d WHERE d.id_empleado = old.id_persona;
	DELETE FROM consulta WHERE id_empleado = old.id_persona;
	DELETE FROM internacion WHERE ordena_internacion = old.id_persona;
	DELETE FROM estudio_realizado WHERE id_empleado = old.id_persona;
	DELETE FROM tratamiento WHERE prescribe = old.id_persona;
	DELETE FROM empleado WHERE id_empleado = old.id_persona;
	INSERT INTO personas_borradas VALUES(default, old.id_persona, old.nombre, old.apellido, old.dni, 'Empleado', NOW(), USER);
END IF;
	RETURN OLD;
END;
$$ language plpgsql;

CREATE TRIGGER audita_personas_borradas 
BEFORE DELETE ON persona
FOR EACH ROW
EXECUTE PROCEDURE auditar_personas_borradas();

SELECT * FROM persona p INNER JOIN empleado pa ON p.id_persona = pa.id_empleado;

DELETE FROM persona WHERE id_persona = 146;