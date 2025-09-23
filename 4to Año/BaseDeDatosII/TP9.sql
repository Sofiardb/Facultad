-- a
DROP TABLE audita_factura;
CREATE TABLE audita_factura(id BIGSERIAL,
							usuario VARCHAR(50),
							fecha_aud DATE,
							operacion VARCHAR(10),
							id_paciente integer,
						    fecha date,
						    hora time without time zone,
						    monto numeric(10,2),
						    pagada character(10),
						    saldo numeric(10,2)
							);


CREATE OR REPLACE FUNCTION audita_factura() RETURNS TRIGGER AS $$
BEGIN
IF (tg_op = 'delete') THEN
	INSERT INTO audita_factura VALUES (default, USER, CURRENT_DATE, 'delete', old.id_paciente, old.fecha, old.hora,
	old.monto, old.pagada, old.saldo);
	RETURN OLD;
ELSIF (tg_op = 'insert') THEN
	INSERT INTO audita_factura VALUES (default, USER, CURRENT_DATE, 'insert', new.id_paciente, new.fecha, new.hora,
	new.monto, new.pagada, new.saldo);
	RETURN NEW;
ELSIF (tg_op = 'update') THEN
	INSERT INTO audita_factura VALUES (default, USER, CURRENT_DATE, 'antes', old.id_paciente, old.fecha, old.hora,
	old.monto, old.pagada, old.saldo);
	INSERT INTO audita_factura VALUES (default, USER, CURRENT_DATE, 'despues', new.id_paciente, new.fecha, new.hora,
	new.monto, new.pagada, new.saldo);
	RETURN NEW;
ELSIF (tg_op = 'truncate') THEN
	INSERT INTO audita_factura VALUES (default, USER, CURRENT_DATE);
	RETURN NULL;
END IF;
END;
$$ language plpgsql;

CREATE TRIGGER audita_factura
AFTER INSERT OR DELETE OR UPDATE ON factura
FOR EACH ROW EXECUTE PROCEDURE audita_factura();
CREATE TRIGGER audita_factura_truncate
AFTER TRUNCATE ON factura
FOR EACH STATEMENT EXECUTE PROCEDURE audita_factura();

-- b

CREATE TABLE audita_empleado_sueldo(id SERIAL NOT NULL,
									usuario VARCHAR(50) NOT NULL,
									fecha_aud TIMESTAMP NOT NULL,
									id_empleado integer NOT NULL,
									nombre_completo VARCHAR(200) NOT NULL,
									dni_empleado VARCHAR(8) NOT NULL,
									sueldo_viejo numeric(9,2) NOT NULL,
									sueldo_nuevo numeric(9,2) NOT NULL,
									porcentaje float NOT NULL,
									estado VARCHAR(9) NOT NULL
									);
CREATE OR REPLACE FUNCTION audita_sueldo_empleado() RETURNS TRIGGER AS $$
DECLARE
	porcentaje_cambio float;
BEGIN
porcentaje_cambio := (new.sueldo - old.sueldo)*100/old.sueldo;
INSERT INTO audita_empleado_sueldo VALUES(default, USER, CURRENT_DATE, new.id_empleado, 
									(SELECT CONCAT(apellido,',', nombre) FROM persona WHERE id_persona = new.id_empleado),
									(SELECT dni FROM persona WHERE id_persona = new.id_empleado),
									old.sueldo,
									new.sueldo,
									porcentaje_cambio,
									CASE WHEN porcentaje_cambio < 0 THEN 'descuento' ELSE 'aumento' END);
RETURN OLD;
END;
$$ language plpgsql;

CREATE TRIGGER audita_sueldo_empleado
AFTER UPDATE OF sueldo ON empleado
FOR EACH ROW 
WHEN (old.sueldo <> new.sueldo)
EXECUTE PROCEDURE audita_sueldo_empleado();

-- c

CREATE TABLE audita_tablas_sistema(id SERIAL NOT NULL,
									usuario_aud VARCHAR(50) NOT NULL,
									fecha_aud TIMESTAMP NOT NULL,
									id_paciente integer NOT NULL, 
									fecha_practica DATE NOT NULL,
									tabla_afectada VARCHAR(50) NOT NULL);
CREATE TABLE estudio_borrado(id_paciente integer NOT NULL,
    id_estudio smallint NOT NULL,
    fecha date NOT NULL,
    id_equipo smallint NOT NULL,
    id_empleado integer NOT NULL,
    resultado character varying(50),
    observacion character varying(100),
    precio numeric(10,2)
);

CREATE TABLE consulta_borrada(id_paciente integer NOT NULL,
    id_empleado integer NOT NULL,
    fecha date NOT NULL,
    id_consultorio smallint NOT NULL,
    hora time without time zone,
    resultado character varying(100));

CREATE TABLE tratamiento_borrado(    id_paciente integer NOT NULL,
    id_medicamento integer NOT NULL,
    fecha_indicacion date NOT NULL,
    prescribe integer NOT NULL,
    nombre character varying(50),
    descripcion character varying(100),
    dosis smallint,
    costo numeric(10,2));

CREATE OR REPLACE FUNCTION audita_tablas_sistema() RETURNS TRIGGER AS $$
BEGIN
IF(tg_relname = 'estudio_realizado') THEN
	INSERT INTO audita_tablas_sistema VALUES(default, USER, NOW(), old.id_paciente, old.fecha, tg_relname);
	INSERT INTO estudio_borrado VALUES(old.id_paciente, old.id_estudio, old.fecha, old.id_equipo, old.id_empleado, old.resultado,
	old.observacion, old.precio);
	RETURN OLD;
ELSIF(tg_relname = 'consulta') THEN
	INSERT INTO audita_tablas_sistema VALUES(default, USER, NOW(), old.id_paciente, old.fecha, tg_relname);
	INSERT INTO consulta_borrada VALUES(old.id_paciente, old.id_empleado, old.fecha, old.id_consultorio, old.hora, old.resultado);
	RETURN OLD;
ELSIF (tg_relname = 'tratamiento') THEN
	INSERT INTO audita_tablas_sistema VALUES(default, USER, NOW(), old.id_paciente, old.fecha_indicacion, tg_relname);
	INSERT INTO tratamiento_borrado VALUES(old.id_paciente, old.id_medicamento, old.fecha_indicacion, old.prescribe,
	old.nombre, old.descripcion, old.dosis, old.costo);
	RETURN OLD;
END IF;

END;
$$ language plpgsql;

CREATE TRIGGER audita_consulta_borrada
AFTER DELETE ON consulta
FOR EACH ROW
EXECUTE PROCEDURE audita_tablas_sistema();

CREATE TRIGGER audita_estudio_borrado
AFTER DELETE ON estudio
FOR EACH ROW
EXECUTE PROCEDURE audita_tablas_sistema();

CREATE TRIGGER audita_tratamiento_borrado
AFTER DELETE ON tratamiento
FOR EACH ROW
EXECUTE PROCEDURE audita_tablas_sistema();

-- d

/*Auditoría de personas: audite cada vez que se elimine una persona, en tal caso, se debe
insertar un registro en una nueva tabla llamada audita_personas_borradas cuyos campos
serán: id (serial), id_persona, nombre y apellido, dni y un campo en el cual se indicará si la
persona eliminada era empleado o paciente, la fecha y el usuario que eliminó a la persona.
Además, la función del trigger deberá realizar todas las tareas necesarias para la
eliminación de la persona (eliminar registros de las tablas que referencian a la persona
eliminada).*/

CREATE TABLE audita_persona_borrada (id SERIAL NOT NULL,
									usuario VARCHAR(50) NOT NULL,
									fecha_aud TIMESTAMP NOT NULL,
									id_persona integer NOT NULL,
									nombre_completo VARCHAR(200) NOT NULL,
									dni VARCHAR(8) NOT NULL,
									tipo VARCHAR(20) NOT NULL
									);
CREATE OR REPLACE FUNCTION audita_persona_eliminada() RETURNS TRIGGER AS $$
BEGIN
END;
IF EXISTS(SELECT 1 FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE id_persona = old.id_persona) THEN
	DELETE FROM pago p USING factura f WHERE p.id_factura = f.id_factura AND f.id_paciente = old.id_persona;
	DELETE FROM factura f WHERE id_paciente = old.id_persona;
	DELETE FROM diagnostico d WHERE d.id_paciente = old.id_persona;
	DELETE FROM consulta WHERE id_paciente = old.id_persona;
	DELETE FROM internacion WHERE id_paciente = old.id_persona;
	DELETE FROM estudio_realizado WHERE id_paciente = old.id_persona;
	DELETE FROM tratamiento WHERE id_paciente = old.id_persona;
	DELETE FROM paciente WHERE id_paciente = old.id_persona;
	INSERT INTO audita_persona_borrada VALUES(default, USER, NOW(), old.id_persona, CONCAT(old.apellido,', ', old.nombre), dni, 'Paciente');
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
	INSERT INTO audita_persona_borrada VALUES(default, USER, NOW(), old.id_persona, CONCAT(old.apellido,', ', old.nombre), dni, 'Empleado');
END IF;
	RETURN OLD;
$$ language plpgsql;

CREATE TRIGGER audita_persona_borrada
AFTER DELETE ON persona
FOR EACH ROW
EXECUTE PROCEDURE audita_persona_eliminada();

-- e

CREATE TABLE audita_pago(id BIGSERIAL NOT NULL,
							usuario VARCHAR(50) NOT NULL,
							fecha_aud DATE NOT NULL,
							operacion VARCHAR(10) NOT NULL,
							id_factura integer NOT NULL,
						    fecha date NOT NULL,
						    monto numeric(10,2) NOT NULL
							);


CREATE OR REPLACE FUNCTION audita_pagos() RETURNS TRIGGER AS $$
BEGIN
IF (tg_op = 'delete') THEN
	INSERT INTO audita_pago VALUES (default, USER, CURRENT_DATE, 'delete', old.id_factura, old.fecha, old.monto);
	RETURN OLD;
ELSIF (tg_op = 'insert') THEN
	INSERT INTO audita_pago VALUES (default, USER, CURRENT_DATE, 'insert', new.id_factura, new.fecha, new.monto);
	RETURN NEW;
ELSIF (tg_op = 'update') THEN
	INSERT INTO audita_pago VALUES (default, USER, CURRENT_DATE, 'antes', old.id_factura, old.fecha, old.monto);
	INSERT INTO audita_factura VALUES (default, USER, CURRENT_DATE, 'despues', new.id_factura, new.fecha,
	new.monto);
	RETURN NEW;
ELSIF (tg_op = 'truncate') THEN
	INSERT INTO audita_pago VALUES (default, USER, CURRENT_DATE);
	RETURN NULL;
END IF;
END;
$$ language plpgsql;



CREATE TRIGGER audita_pago
AFTER INSERT OR DELETE OR UPDATE ON pago
FOR EACH ROW EXECUTE PROCEDURE audita_pagos();

CREATE TRIGGER audita_pago_truncate
AFTER TRUNCATE ON pago
FOR EACH STATEMENT EXECUTE PROCEDURE audita_pagos();
