-- 1
-- a

CREATE PROCEDURE especialidad_abm(p_especialidad text, p_operacion text) AS $$
DECLARE
	existe boolean;
BEGIN
IF TRIM(p_especialidad) = '' OR p_especialidad IS NULL OR TRIM(p_operacion) = '' OR p_operacion IS NULL THEN
	RAISE EXCEPTION 'La especialidad y/o operacion ingresada no puede ser nula o vacía';
END IF;
SELECT EXISTS(SELECT 1 FROM especialidad WHERE especialidad = p_especialidad) INTO existe;
IF LOWER(p_operacion) = 'insert' THEN
	IF existe THEN
		RAISE EXCEPTION 'La especialidad que desea ingresar ya existe';
	END IF;
	INSERT INTO especialidad VALUES((SELECT COALESCE(MAX(id_especialidad), 0) + 1 FROM especialidad),  UPPER(p_especialidad));
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se pudo insertar la especialidad';
	ELSE
		RAISE NOTICE 'Se creó la especialidad % exitosamente', p_especialidad;
	END IF;
ELSIF LOWER(p_operacion) = 'delete' THEN
	IF NOT existe THEN
		RAISE EXCEPTION 'La especialidad que desea eliminar no existe';
	END IF;
	UPDATE empleado e 
	SET id_especialidad = (SELECT id_especialidad WHERE especialidad = 'SIN ESPECIALIDAD MEDICA')
	FROM especialidad es 
	WHERE es.id_especialidad = e.id_especialidad AND especialidad =  UPPER(p_especialidad);
	DELETE FROM especialidad WHERE especialidad = p_especialidad;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se pudo llevar a cabo la eliminación de la especialidad %', p_especialidad;
	ELSE
		RAISE NOTICE 'La especialidad se eliminó correctamente';
	END IF;
ELSE 
	IF NOT existe THEN
		RAISE EXCEPTION 'La especialidad que desea modificar no existe';
	END IF;
	UPDATE especialidad SET especialidad = operacion WHERE especialidad =  UPPER(p_especialidad);
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se pudo llevar a cabo la modificacion de la especialidad % por el nombre %', p_especialidad, p_operacion;
	ELSE
		RAISE NOTICE 'La especialidad se modificó correctamente';
	END IF;
END IF;
EXCEPTION 
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ language plpgsql;

-- b

CREATE PROCEDURE tablas_sistema_alta(tabla text, campo text) AS $$
BEGIN
IF TRIM(tabla) = '' OR tabla IS NULL OR TRIM(campo) = '' OR campo IS NULL THEN
	RAISE EXCEPTION 'La tabla o campo ingresado no puede ser nulo o vacío';
END IF;
IF LOWER(tabla) <> 'cargo' AND LOWER(tabla) <> 'clasificacion' AND LOWER(tabla) <> 'patologia' THEN
	RAISE EXCEPTION 'La tabla en la que desea insertar un registro no existe';
END IF;

IF LOWER(tabla) = 'cargo' THEN
	IF EXISTS(SELECT 1 FROM cargo WHERE cargo = campo) THEN
		RAISE EXCEPTION 'El cargo que desea ingresar ya existe';
	END IF;
	INSERT INTO cargo VALUES((SELECT COALESCE(MAX(id_cargo), 0) + 1 FROM cargo),  UPPER(campo));
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se pudo insertar el cargo';
	ELSE
		RAISE NOTICE 'Se creó el cargo % exitosamente', p_especialidad;
	END IF;
ELSIF LOWER(tabla) = 'clasificacion' THEN
	IF EXISTS(SELECT 1 FROM clasificacion WHERE clasificacion = campo) THEN
		RAISE EXCEPTION 'La clasificacion que desea ingresar ya existe';
	END IF;
	INSERT INTO clasificacion VALUES((SELECT COALESCE(MAX(id_clasificacion), 0) + 1 FROM clasificacion),  UPPER(campo));
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se pudo insertar la clasificación nueva';
	ELSE
		RAISE NOTICE 'Se creó la clasificacion % exitosamente', p_especialidad;
	END IF;
ELSIF LOWER(tabla) <> 'patologia' THEN
	IF EXISTS(SELECT 1 FROM patologia WHERE nombre = campo) THEN
		RAISE EXCEPTION 'La patologia que desea ingresar ya existe';
	END IF;
	INSERT INTO patologia VALUES((SELECT COALESCE(MAX(id_patologia), 0) + 1 FROM patologia),  UPPER(campo));
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se pudo insertar la patologia nueva';
	ELSE
		RAISE NOTICE 'Se creó la patologia % exitosamente', p_especialidad;
	END IF;
END IF;
EXCEPTION 
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ language plpgsql;

-- c
/*
Realice un SP que inserte un nuevo tratamiento, la misma recibirá 5 parámetros, el DNI del
paciente, el nombre del medicamento, el DNI del empleado (prescribe tratamiento), la
dosis y el costo. El costo y la dosis deben ser positivas y la fecha_indicacion debe ser la del
sistema. Si la dosis es mayor que el stock del medicamento prescripto, debe mostrar un
mensaje indicando que el stock es insuficiente, de lo contrario debe mostrar un mensaje
indicando si se realizó la inserción correctamente. Nombre sugerido: tratamiento_alta.
*/

CREATE PROCEDURE tratamiento_alta(p_dni_pac text, p_medicamento text, p_dni_emp text, p_dosis int, p_costo numeric) AS $$
DECLARE
	medicamento_selecc record;
BEGIN
IF p_dni_pac IS NULL OR p_dni_emp IS NULL OR TRIM(p_dni_pac) = '' OR TRIM(p_dni_emp) = '' THEN
	RAISE EXCEPTION 'El dni del paciente y/o del empleado no puede ser nulo o vacio';
END IF;
IF COALESCE(p_costo, 0) <= 0 OR COALESCE(p_dosis, 0) <= 0 THEN
    RAISE EXCEPTION 'El costo y/o dosis no pueden ser nulos, cero o negativos';
END IF;

IF NOT EXISTS(SELECT 1 FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE dni = p_dni_pac) THEN
	RAISE EXCEPTION 'El paciente de dni % no existe', p_dni_pac;
END IF;

IF NOT EXISTS(SELECT 1 FROM persona p INNER JOIN  empleado e ON p.id_persona = e.id_empleado WHERE dni = p_dni_emp) THEN
	RAISE EXCEPTION 'El empleado de dni % no existe', p_dni_pac;
END IF;

SELECT id_medicamento, nombre, descripcion, stock INTO medicamento_selecc FROM medicamento WHERE nombre = p_medicamento;
IF NOT FOUND THEN
	RAISE EXCEPTION 'El medicamento de nombre % no existe', p_medicamento;
END IF;

IF medicamento_selecc.stock < dosis THEN
	RAISE EXCEPTION 'No hay suficiente stock del medicamento';
END IF;

INSERT INTO tratamiento VALUES((SELECT id_persona FROM persona WHERE dni = p_dni_pac), medicamento_selecc.id_medicamento,
								CURRENT_DATE, (SELECT id_persona FROM persona WHERE dni = p_dni_emp),
								medicamento_selecc.nombre, medicamento_selecc.descripcion, p_dosis, p_costo);
IF NOT FOUND THEN
	RAISE EXCEPTION 'No se pudo insertar el tratamiento';
ELSE
	RAISE NOTICE 'La inserción se realizó correctamente';
END IF;
EXCEPTION 
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ language plpgsql;

-- 2
-- a
CREATE OR REPLACE FUNCTION pacientes_por_obra_social(p_nombre text) RETURNS SETOF personayobrasocial AS $$
DECLARE 
	registro record;
BEGIN
IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
	RAISE EXCEPTION 'El nombre de la obra social no puede ser nulo ni vacio';
END IF;

END IF;
FOR registro IN SELECT id_paciente, p.nombre, p.apellido, o.sigla, o.nombre FROM persona p
				INNER JOIN paciente pa ON pa.id_paciente = p.id_persona 
				INNER JOIN obra_social o USING(id_obra_social)
				WHERE o.nombre = UPPER(p_nombre) LOOP
	RETURN NEXT registro;
	END LOOP;
EXCEPTION 
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ language plpgsql;

SELECT * FROM obra_social;

SELECT * from pacientes_por_obra_social('OBRA SOCIAL PORTUARIOS ARGENTINOS DE MAR DEL PLATA');

-- b

CREATE OR REPLACE FUNCTION paciente_consultas(p_dni text) RETURNS SETOF informacion_consulta AS $$
DECLARE 
	registro record;
BEGIN
IF p_dni IS NULL OR TRIM(p_dni) = '' THEN
	RAISE EXCEPTION 'El dni del paciente no puede ser nulo ni vacio';
END IF;

IF NOT EXISTS(SELECT 1 FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE dni = p_dni) THEN
	RAISE EXCEPTION 'No existe el paciente con dni % ', p_dni;
END IF;
FOR registro IN
    SELECT 
        p.nombre AS nombre_paciente,
        p.apellido AS apellido_paciente,
        pe.nombre AS nombre_empleado,
        pe.apellido AS apellido_empleado,
        c.fecha,
		co.nombre
    FROM paciente pa
    INNER JOIN persona p ON pa.id_paciente = p.id_persona
    INNER JOIN consulta c ON c.id_paciente = pa.id_paciente
    INNER JOIN empleado e ON c.id_empleado = e.id_empleado
    INNER JOIN persona pe ON e.id_empleado = pe.id_persona
	INNER JOIN consultorio co USING(id_consultorio)
    WHERE p.dni = p_dni
LOOP
    RETURN NEXT registro;
END LOOP;
EXCEPTION 
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ language plpgsql;

SELECT * FROM paciente_consultas('6817575');

-- c
CREATE TYPE empleado_especialidad AS(
	nombre VARCHAR(100),
	apellido VARCHAR(100),
	especialidad VARCHAR(50)
);
CREATE FUNCTION empleados_trabajan_feriado() RETURNS SETOF empleado_especialidad AS $$
DECLARE 
	registro record;
BEGIN
FOR registro IN
    SELECT 
        p.nombre,
        p.apellido,
		especialidad
    FROM empleado e
    INNER JOIN persona p ON p.id_persona = e.id_empleado
	INNER JOIN especialidad USING(id_especialidad)
	INNER JOIN trabajan USING(id_empleado)
	INNER JOIN turno USING(id_turno)
    WHERE turno = 'Feriados'
	ORDER BY especialidad
LOOP
    RETURN NEXT registro;
END LOOP;
EXCEPTION 
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ language plpgsql;

SELECT * FROM empleados_trabajan_feriado();

-- d

CREATE TYPE public.factura_paciente_urgencia AS
(
	id_factura bigint,
	fecha date,
	monto numeric(10,2),
	nombre_paciente character varying(100),
	apellido_paciente character varying(100),
	estado text
);


CREATE FUNCTION informacion_facturas() RETURNS SETOF factura_paciente_urgencia AS $$
DECLARE 
	registro record;
BEGIN
FOR registro IN
    SELECT 
        f.id_factura,
		f.fecha,
		f.monto,
		p.nombre,
		p.apellido, 
		CASE 
	        WHEN saldo > 1000000 THEN 'Cobrar urgente'
	        WHEN saldo > 500000 THEN 'Cobrar prioridad'
       		ELSE 'El cobro puede esperar'
    		END AS estado
    FROM factura f
    INNER JOIN persona p ON p.id_persona = f.id_paciente
LOOP
    RETURN NEXT registro;
END LOOP;
EXCEPTION 
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ language plpgsql;

SELECT * FROM informacion_facturas();

-- e

CREATE OR REPLACE FUNCTION listar_tabla(tabla text)RETURNS table(id_tabla integer, nombre VARCHAR(50)) AS $$
DECLARE
    sql TEXT;
BEGIN
IF tabla IS NULL OR TRIM(tabla) = '' THEN
	RAISE EXCEPTION 'La tabla no puede ser nula o vacía';
END IF;
IF LOWER(tabla) <> 'cargo' AND LOWER(tabla) <> 'clasificacion' AND LOWER(tabla) <> 'patologia' AND LOWER(tabla) <> 'especialidad' AND LOWER(tabla) <> 'tipo_estudio' THEN
	RAISE EXCEPTION 'La tabla en la que desea insertar un registro no existe';
END IF;
sql := FORMAT('SELECT * FROM %I', LOWER(tabla));
RETURN QUERY EXECUTE sql;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM listar_tabla('cargo');

-- 3

CREATE PROCEDURE factura_alta(p_id_paciente integer, p_monto numeric) AS $$
BEGIN

IF p_id_paciente IS NULL OR p_id_paciente <= 0 THEN
	RAISE EXCEPTION 'El monto debe ser un número positivo y no nulo';
END IF;
IF p_monto IS NULL OR p_monto <= 0 THEN
	RAISE EXCEPTION 'El monto debe ser un número positivo y no nulo';
END IF;

IF NOT EXISTS(SELECT 1 FROM paciente pa WHERE id_paciente = p_id_paciente) THEN
	RAISE EXCEPTION 'No existe el paciente ingresado';
END IF;

INSERT INTO factura_alta VALUES((SELECT COALESCE(MAX(id_factura), 0) + 1 FROM factura), p_id_paciente, CURRENT_DATE,
							CURRENT_TIME, p_monto, 'N', p_monto);
IF NOT FOUND THEN
	RAISE EXCEPTION 'No se pudo crear la factura';
END IF;
EXCEPTION 
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ language plpgsql;

CREATE PROCEDURE paciente_alta(p_dni text, p_costo numeric) AS $$
DECLARE 
	reg record;
BEGIN
IF p_dni IS NULL OR TRIM(p_dni) = '' THEN
	RAISE EXCEPTION 'El dni del paciente no puede ser nulo ni vacío';
END IF;

IF p_costo IS NULL OR p_costo <= 0 THEN
	RAISE EXCEPTION 'El costo debe ser un número positivo y no nulo';
END IF;

SELECT * INTO reg FROM persona p INNER JOIN paciente pa ON p.id_persona = pa.id_paciente WHERE dni = p_dni;
IF NOT FOUND THEN
	RAISE EXCEPTION 'No existe el paciente con dni % ', p_dni;
END IF;

UPDATE internacion i
SET 
    fecha_alta = CURRENT_DATE,
    hora = CURRENT_TIME,
    costo = p_costo
FROM persona p
WHERE 
    p.id_persona = i.id_paciente
    AND p.dni = p_dni
    AND i.fecha_alta IS NULL;

IF NOT FOUND THEN
	RAISE EXCEPTION 'El paciente no tiene una internación vigente';
END IF;

CALL factura_alta(reg.id_paciente, p_costo);

RAISE NOTICE 'El alta fue exitosa';
EXCEPTION 
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ language plpgsql;
