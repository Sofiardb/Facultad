-- 1
/*a) Escriba un procedimiento para ingresar los estudios realizados. El procedimiento debe recibir como parámetros
el nombre y apellido de un paciente, el nombre del estudio, el nombre y la marca del equipo, el dni del
empleado que realiza el estudio y el precio del estudio, la fecha será la del sistema. Todos los otros campos se
insertarán en la tabla con el valor nulo. Una vez insertado el registro, el procedimiento debe mostrar un mensaje
indicando que se insertó bien el registro, mostrando además, el nombre del estudio, el nombre y apellido del
paciente y la fecha. Se recomienda usar la siguiente firma para el procedimiento
 create procedure sp_inserta_estudio(p_nom text, p_ape text, p_est text, p_equi text, p_marca text, p_dni text,
p_precio float)
*/

CREATE OR REPLACE PROCEDURE sp_inserta_estudio(p_nom text, p_ape text, p_est text, p_equi text, p_marca text, p_dni text,
p_precio float) AS $$
DECLARE
	id_paciente_s integer;
	id_empleado_s integer;
	id_estudio_s integer;
	id_equipo_s integer;
BEGIN
IF p_nom IS NULL OR TRIM(p_nom) = '' OR p_ape IS NULL OR TRIM(p_ape) = '' THEN
	RAISE EXCEPTION 'El nombre y/o apellido del paciente no pueden ser nulos o vacíos';
END IF;
IF p_est IS NULL OR TRIM(p_est) = '' OR p_equi IS NULL OR TRIM(p_equi) = '' OR p_marca IS NULL OR TRIM(p_marca) = '' THEN
	RAISE EXCEPTION 'El nombre del estudio, equipo y su marca y/o no pueden ser nulos o vacíos';
END IF;
IF p_dni IS NULL OR TRIM(p_dni) = '' THEN
	RAISE EXCEPTION 'El dni del empleado no puede ser nulo o vacío';
END IF;
IF p_precio IS NULL OR p_precio <= 0 THEN
	RAISE EXCEPTION 'El precio debe ser un numero positivo';
END IF;

SELECT id_paciente INTO id_paciente_s FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE p.nombre = p_nom AND p.apellido = p_ape LIMIT 1;
IF NOT FOUND THEN
	RAISE EXCEPTION 'No existe el paciente que ha ingresado';
END IF;
SELECT id_estudio INTO id_estudio_s FROM estudio e WHERE e.nombre = p_est;
IF NOT FOUND THEN
	RAISE EXCEPTION 'No existe el estudio que ha ingresado';
END IF;
SELECT id_equipo INTO id_equipo_s FROM equipo e WHERE e.nombre = p_equi AND e.marca = p_marca;
IF NOT FOUND THEN
	RAISE EXCEPTION 'No existe el equipo que ha ingresado';
END IF;
SELECT id_empleado INTO id_empleado_s FROM persona p INNER JOIN empleado e ON p.id_persona = e.id_empleado WHERE p.dni = p_dni;
IF NOT FOUND THEN
	RAISE EXCEPTION 'No existe el empleado con dni %', p_dni;
END IF;

IF EXISTS(SELECT 1 FROM estudio_realizado WHERE id_paciente = id_paciente_s AND id_estudio = id_estudio_s AND fecha = CURRENT_DATE) THEN
	RAISE EXCEPTION 'Un paciente no se puede realizar el estudio dos veces en un mismo dia';
END IF;

INSERT INTO estudio_realizado (id_paciente, id_estudio, fecha, id_equipo, id_empleado, precio) 
VALUES(id_paciente_s, id_estudio_s, CURRENT_DATE, id_equipo_s, id_empleado_s, p_precio);
IF NOT FOUND THEN
	RAISE EXCEPTION 'No se pudo realizar la inserción';
ELSE
	RAISE NOTICE 'Se realizó correctamente la inserción del estudio % para el paciente %, % en la fecha %', p_est, p_ape, p_nom, CURRENT_DATE;
END IF;
END;
$$ language plpgsql;
SELECT * from persona;
CALL sp_inserta_estudio('AUGUSTO CESAR', 'JUAREZ', 'MAPEO CEREBRAL COMPUTADO', 'ASPIRADOR', 'ABBOTT','36839130', 60000);

-- 2
-- a
/*Escriba una función que permita ingresar un nuevo pago o una nueva factura, reciba como parámetros el
número de factura, la fecha, el monto y el dni del paciente.
Si el número de factura ingresado ya existe en la tabla factura, controle que coincida con el paciente ingresado,
en caso de que paciente no coincida, debe mostrar un mensaje de error, pero si coincide, debe ingresar un
nuevo pago, con el número de factura, fecha y el monto ingresado, además, debe modificar el saldo de la factura
ingresada, y si el saldo da cero, también debe modificar el campo “pagada” de la tabla factura por ‘S’.
Si el número de factura no existe en la tabla factura, entonces debe insertar una nueva factura.
Finalmente, la función debe entregar un listado mostrando el número, fecha, el monto y el saldo de la factura, el
nombre y apellido del paciente y todos los montos de los pagos realizados para cada una de las facturas de dicho
paciente, también debe mostrar la fecha en la que se realizaron dichos pagos. Se recomienda usar la siguiente
firma para la función
 create function facturas_x_prestacion(p_fac bigint, p_fecha date, p_monto numeric, p_dni text)*/

CREATE TYPE pagos_factura AS ( 
	    id_factura bigint,
    fecha_factura date,
    monto_factura numeric(10,2),
	nombre_paciente VARCHAR(100),
	apellido_paciente VARCHAR(100),
	monto_pago numeric(10,2),
	fecha_pago date						
);
CREATE OR REPLACE FUNCTION facturas_x_prestacion(p_fac bigint, p_fecha date, p_monto numeric, p_dni text) returns setof pagos_factura AS $$
DECLARE
	factura_s record;
	existe boolean;
BEGIN
-- si P_FAC ES NULO CONSIDERO QUE NO EXISTE Y HAY QUE CREARLA
IF p_dni IS NULL OR TRIM(p_dni) = '' THEN
	RAISE EXCEPTION 'El dni del paciente no puede ser nulo o vacío';
END IF;
IF p_fecha IS NULL OR p_fecha > CURRENT_DATE THEN
	RAISE EXCEPTION 'La fecha debe ser menor o igual a la fecha actual';
END IF;
IF p_monto IS NULL OR p_monto <= 0 THEN
	RAISE EXCEPTION 'El monto ingresado debe ser un número positivo';
END IF;

SELECT EXISTS(SELECT 1 FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE p.dni = p_dni) INTO existe;
SELECT * INTO factura_s FROM factura WHERE id_factura = p_fac;
IF FOUND THEN
	IF NOT EXISTS(SELECT 1 FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE pa.id_paciente = factura_s.id_paciente AND p.dni = p_dni) THEN
		RAISE EXCEPTION 'El dni % no coincide con el indicado en la factura', p_dni;
	END IF;
	IF p_monto > factura_s.saldo THEN
		RAISE EXCEPTION 'El monto del pago no puede superar el saldo restante';
	END IF;
	INSERT INTO pago VALUES(p_fac, p_fecha, p_monto);
	IF (factura_s.saldo = p_monto) THEN
		UPDATE factura SET saldo = saldo - p_monto, pagada = 'S' WHERE id_factura = p_fac;
	ELSE
		UPDATE factura SET saldo = saldo - p_monto WHERE id_factura = p_fac;
	END IF;
ELSE
	IF NOT existe THEN
		RAISE EXCEPTION 'El paciente con dni % no existe', p_dni;
	END IF;
	INSERT INTO factura VALUES ((SELECT MAX(id_factura) + 1 FROM factura), (SELECT id_paciente FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE p.dni = p_dni),
								p_fecha, CURRENT_TIME, p_monto, 'N', p_monto);
END IF;
-- Dentro de los if ya me asegure que la persona existe
RETURN QUERY (SELECT id_factura, f.fecha ,f.monto, p.nombre, p.apellido, pa.monto, pa.fecha 
				FROM factura f
				INNER JOIN persona p ON f.id_paciente = p.id_persona
				LEFT JOIN pago pa USING (id_factura)
				WHERE p.dni = p_dni); 
END;
$$ language plpgsql;
SELECT * FROM factura f INNER JOIN persona p ON f.id_paciente = p.id_persona;
SELECT * FROM facturas_x_prestacion(2, CURRENT_DATE, 8000,'68858698');

-- b

/*Escriba una función que muestre un listado de los pacientes que hicieron una consulta, tratamiento o estudio en
un determinado rango de fechas. Para ello reciba como parámetros el dni del paciente y el nombre de la
práctica: consulta, tratamiento o estudio, cualquier otro nombre de tabla ingresado debe generar un mensaje de
error, y un rango de fechas (fecha de inicio y fecha de fin). La función debe retornar, según el nombre de la tabla
ingresada, un listado que contenga el nombre, apellido y dni del paciente, la fecha, el nombre y apellido del
empleado que atendió al paciente en las fechas indicadas y por último el nombre de la tabla que se ingresó
como parámetro. Se recomienda usar la siguiente firma para la función.
create function listado_x_prestacion(p_dni text, p_tabla text, fecha_inicio date, fecha_fin date)*/

CREATE TYPE paciente_practicas AS(
							nombre_paciente VARCHAR(100),
							apellido_paciente VARCHAR(100),
							dni_paciente VARCHAR(8),
							fecha DATE,
							nombre_empleado VARCHAR(100),
							apellido_empleado VARCHAR(100),
							tabla_consultada text
);

CREATE OR REPLACE FUNCTION listado_x_prestacion(p_dni text, p_tabla text, fecha_inicio date, fecha_fin date) RETURNS SETOF paciente_practicas AS $$
BEGIN
IF p_dni IS NULL OR TRIM(p_dni) = '' THEN
	RAISE EXCEPTION 'El dni ingresado no debe ser nulo ni vacio';
END IF;
IF NOT EXISTS(SELECT 1 FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE p.dni = p_dni) THEN
	RAISE EXCEPTION 'El paciente ingresado no existe';
END IF;
IF p_tabla NOT IN ('consulta', 'tratamiento', 'estudio') THEN
	RAISE EXCEPTION 'La tabla ingresada no es válida. Debe ser consulta, tratamiento o estudio';
END IF;
IF (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_inicio > CURRENT_DATE OR fecha_fin > CURRENT_DATE OR fecha_inicio > fecha_fin) THEN
	RAISE EXCEPTION 'Las fechas ingresadas no son válidas. Verifique que no sean mayor que la fecha actual o que la fecha de inicio sea menor o igual a la actual';
END IF;
CASE p_tabla
	WHEN 'consulta' THEN
		RETURN QUERY (SELECT pa.nombre, pa.apellido, pa.dni, fecha, pe.nombre, pe.apellido, 'consulta' AS tabla_consultada FROM consulta c
						INNER JOIN persona pa ON pa.id_persona = c.id_paciente
						INNER JOIN persona pe ON pe.id_persona = c.id_paciente
						WHERE pa.dni = p_dni AND fecha BETWEEN fecha_inicio AND fecha_fin);
	WHEN 'tratamiento' THEN 
		RETURN QUERY (SELECT pa.nombre, pa.apellido, pa.dni, fecha_indicacion, pe.nombre, pe.apellido, 'tratamiento' AS tabla_consultada FROM tratamiento t
						INNER JOIN persona pa ON pa.id_persona = t.id_paciente
						INNER JOIN persona pe ON pe.id_persona = t.id_paciente
						WHERE pa.dni = p_dni AND fecha_indicacion BETWEEN fecha_inicio AND fecha_fin);
	WHEN 'estudio' THEN 
		RETURN QUERY (SELECT pa.nombre, pa.apellido, pa.dni, fecha, pe.nombre, pe.apellido, 'estudio_realizado' AS tabla_consultada FROM estudio_realizado e
						INNER JOIN persona pa ON pa.id_persona = e.id_paciente
						INNER JOIN persona pe ON pe.id_persona = e.id_paciente
						WHERE pa.dni = p_dni AND fecha BETWEEN fecha_inicio AND fecha_fin);
END CASE;
END;
$$ language plpgsql;
SELECT * FROM consulta c INNER JOIN persona p ON p.id_persona = c.id_paciente;
SELECT * FROM listado_x_prestacion('38125966', 'estudio', '2021-08-01', '2024-03-01');

-- 3

/*a) Escriba un trigger para llevar un ranking de los empleados que más dinero han hecho ganar al hospital
realizando estudios o prescribiendo tratamientos. En la tabla ranking se guardarán el id, apellido y nombre
del empleado, el nombre de la tabla (tratamiento o estudio_realizado) y el total (suma de todos los costos en
el caso de los tratamientos y el precio en el caso de los estudios).
Cada vez que se inserte un tratamiento, debe controlar si existe un registro con el id_empleado y el nombre
de la tabla tratamiento, de ser así deberá modificar el total sumando el costo del nuevo tratamiento, por el
contrario, debe insertar un nuevo registro a la tabla ranking.
Cada vez que se realice un estudio, debe controlar si existe un registro con el id_empleado y el nombre de la
tabla estudio_realizado, de ser así deberá modificar el total sumando el precio del nuevo estudio, por el
contrario, debe insertar un nuevo registro a la tabla ranking.
También debe contemplar el caso de que se borre un tratamiento o estudio realizado, en estos casos deberá
descontar el total restándole el costo o precio de acuerdo a la tabla (tratamiento o estudio_realizado) al
registro del empleado correspondiente. Debe escribir una sola función.*/
CREATE TABLE ranking_empleados(
												id SERIAL,
												id_empleado integer NOT NULL,
												nombre VARCHAR(100) NOT NULL,
												apellido VARCHAR(100) NOT NULL,
												tabla VARCHAR(25) NOT NULL,
												total numeric(14, 2) NOT NULL, -- los precios son numeric(10,2)
												PRIMARY KEY(id)
);

CREATE OR REPLACE FUNCTION ranking_empleados_practicas() RETURNS TRIGGER AS $$
DECLARE
	reg record;
BEGIN
IF ( TG_OP = 'DELETE') THEN
	IF(tg_relname = 'tratamiento') THEN
		UPDATE ranking_empleados SET total = total - old.costo WHERE id_empleado = old.prescribe AND tabla = tg_relname;
		RETURN OLD;
	ELSIF (tg_relname = 'estudio_realizado') THEN
		UPDATE ranking_empleados SET total = total - old.precio WHERE id_empleado = old.id_empleado AND tabla = tg_relname;
		RETURN OLD;
	END IF;
ELSIF (TG_OP = 'INSERT') THEN
	IF(tg_relname = 'tratamiento') THEN
		IF EXISTS(SELECT 1 FROM ranking_empleados WHERE id_empleado = new.prescribe AND tabla = tg_relname) THEN
			UPDATE ranking_empleados SET total = total + new.costo WHERE id_empleado = new.prescribe AND tabla = tg_relname;
			RETURN NEW;
		ELSE
			SELECT nombre, apellido INTO reg FROM persona WHERE id_persona = new.prescribe; 
			INSERT INTO ranking_empleados VALUES(default, new.prescribe, reg.nombre, reg.apellido, tg_relname, new.costo);
			RETURN NEW;
		END IF;
	ELSIF(tg_relname = 'estudio_realizado') THEN
		IF EXISTS(SELECT 1 FROM ranking_empleados WHERE id_empleado = new.id_empleado AND tabla = tg_relname) THEN
			UPDATE ranking_empleados SET total = total + new.precio WHERE id_empleado = new.prescribe AND tabla = tg_relname;
			RETURN NEW;
		ELSE
			SELECT nombre, apellido INTO reg FROM persona WHERE id_persona = new.id_empleado; 
			INSERT INTO ranking_empleados VALUES(default, new.id_empleado, reg.nombre, reg.apellido, tg_relname, new.precio);
			RETURN NEW;
		END IF;
	END IF;
END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER ranking_empleados_tratamiento ON tratamiento;
CREATE TRIGGER ranking_empleados_tratamiento
BEFORE INSERT OR DELETE ON tratamiento
FOR EACH ROW
EXECUTE FUNCTION ranking_empleados_practicas();

CREATE TRIGGER ranking_empleados_estudios
AFTER INSERT OR DELETE ON estudio_realizado
FOR EACH ROW
EXECUTE FUNCTION ranking_empleados_practicas();


DELETE FROM tratamiento WHERE id_paciente = 34 AND id_medicamento = 26 AND fecha_indicacion = CURRENT_DATE;
INSERT INTO tratamiento VALUES(7, 26, CURRENT_DATE, 4, 'PANADOL MASTICABLE NINOS', 'CAJA X 100 TABLETAS', 2, 993.31); 