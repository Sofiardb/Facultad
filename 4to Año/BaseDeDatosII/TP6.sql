-- 1
-- a
CREATE OR REPLACE PROCEDURE especialidad_alta(text) as $$
DECLARE 
	fila_especialidad especialidad%ROWTYPE;
BEGIN
IF $1 IS NULL OR TRIM($1) = '' THEN
	RAISE EXCEPTION 'La especialidad no puede ser nula o vacía';
END IF;
SELECT * INTO fila_especialidad FROM especialidad WHERE especialidad = $1;
IF FOUND THEN
	RAISE exception 'Ya existe la especialidad.';
ELSE
	INSERT INTO especialidad VALUES ((SELECT MAX(id_especialidad) + 1 FROM especialidad), $1);
	IF NOT FOUND THEN
		RAISE exception 'No se pudo crear la especialidad.';
	ELSE
		RAISE notice 'Se creó la especialidad con éxito';
	END IF;
END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;
CALL especialidad_alta('NEUROCIRUGÍA 2');
-- b
CREATE OR REPLACE PROCEDURE crear_persona(
    IN p_nombre TEXT,
    IN p_apellido TEXT,
    IN p_dni TEXT,
    IN p_fecha_nacimiento DATE,
    IN p_domicilio TEXT,
    IN p_telefono TEXT
)
AS $$
DECLARE
    existe INTEGER;
BEGIN
    SELECT COUNT(*) INTO existe FROM persona WHERE dni = p_dni;
    IF existe > 0 THEN
        RAISE EXCEPTION 'Ya existe una persona con ese DNI.';
    END IF;

    INSERT INTO persona(id_persona, nombre, apellido, dni, fecha_nacimiento, domicilio, telefono)
    VALUES (
        (SELECT COALESCE(MAX(id_persona), 0) + 1 FROM persona),
        p_nombre, p_apellido, p_dni, p_fecha_nacimiento, p_domicilio, p_telefono
    );
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se pudo crear la persona';
	END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE empleado_alta(
    IN nombre TEXT,
    IN apellido TEXT,
    IN dni TEXT,
    IN fecha_nacimiento DATE,
    IN domicilio TEXT,
    IN telefono TEXT,
    IN fecha_ingreso DATE,
    IN sueldo NUMERIC(9,2),
    IN cargo TEXT,
    IN especialidad TEXT
)
AS $$
DECLARE 
    fila_cargo cargo%ROWTYPE;
    fila_especialidad especialidad%ROWTYPE;
    nuevo_id_persona INTEGER;
BEGIN
    -- Validaciones
    IF nombre IS NULL OR nombre = ''
       OR apellido IS NULL OR apellido = ''
       OR dni IS NULL OR dni = ''
       OR sueldo IS NULL OR sueldo <= 0
       OR fecha_ingreso IS NULL OR fecha_ingreso >= CURRENT_DATE
       OR cargo IS NULL OR cargo = ''
       OR especialidad IS NULL OR especialidad = '' THEN
        RAISE EXCEPTION 'Revise los datos ingresados. Recuerde que no deben ser vacíos';
    END IF;

    -- Verificar existencia de cargo y especialidad
    SELECT * INTO fila_cargo FROM cargo c WHERE c.cargo = empleado_alta.cargo;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el cargo ingresado.';
    END IF;

    SELECT * INTO fila_especialidad FROM especialidad e WHERE e.especialidad = empleado_alta.especialidad;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la especialidad ingresada.';
    END IF;

    -- Llamar al procedimiento modularizado
    CALL crear_persona(nombre, apellido, dni, fecha_nacimiento, domicilio, telefono);

    -- Obtener el id de la nueva persona
    SELECT MAX(id_persona) INTO nuevo_id_persona FROM persona;

    -- Insertar en empleado
    INSERT INTO empleado(id_empleado, id_especialidad, id_cargo, fecha_ingreso, sueldo)
    VALUES (nuevo_id_persona, fila_especialidad.id_especialidad, fila_cargo.id_cargo, fecha_ingreso, sueldo);
	IF NOT FOUND THEN
		DELETE FROM persona WHERE id_persona = nuevo_id_persona;
		RAISE EXCEPTION 'No se pudo crear el empleado';
	END IF;
	RAISE NOTICE 'Se ha creado el empleado correctamente';
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CALL empleado_alta('Persona nueva', 'empleado_alta', '4444444', '2004-06-22', 'ddd', 'ttt', '2024-06-23', 99999, 'JEFE SALA', 'CLINICA');
-- c
CREATE OR REPLACE PROCEDURE factura_modifica_saldo(p_id_factura int, p_saldo numeric(10, 2)) as $$
DECLARE 
	fila_factura factura%ROWTYPE;
BEGIN
IF  p_id_factura IS NULL OR p_id_factura < 0 OR p_saldo IS NULL OR p_saldo <= 0 THEN
	RAISE EXCEPTION 'Error. El numero de factura no puede ser nulo ni menor que 0, o el saldo no puede ser nulo ni menor o igual a 0';
END IF;
SELECT * INTO fila_factura FROM factura WHERE id_factura = p_id_factura;
IF NOT FOUND THEN
	RAISE EXCEPTION 'La factura ingresada no existe';
ELSE
	IF fila_factura.saldo < p_saldo THEN
		RAISE EXCEPTION 'El saldo ingresado es mayor que el adeudado';
	END IF;
END IF;
IF fila_factura.saldo = p_saldo THEN
	UPDATE factura SET saldo = saldo - p_saldo, pagada = 'S' WHERE id_factura = p_id_factura;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se pudo actualizar el saldo';
	ELSE
		RAISE NOTICE 'Actualización completa';
	END IF;
ELSE 
	UPDATE factura SET saldo = saldo - p_saldo WHERE id_factura = p_id_factura;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se pudo actualizar el saldo';
	ELSE
		RAISE NOTICE 'Actualización completa';
	END IF;
END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

-- d

CREATE OR REPLACE PROCEDURE medicamento_cambia_precio(p_nombre text, p_tipocambio char, porcentaje float) AS $$
DECLARE 
	fila_verificacion record;
BEGIN
IF (p_nombre IS NULL OR p_nombre = '') THEN
	RAISE EXCEPTION 'El nombre del medicamento no puede ser nulo ni vacio';
END IF;
IF porcentaje <= -100 THEN
	RAISE EXCEPTION 'Porcentaje no válido';
END IF;
IF p_tipocambio = 'M' THEN
	SELECT * INTO fila_verificacion FROM medicamento WHERE nombre = p_nombre;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'El medicamento que desea modificar no existe';
	END IF;
	UPDATE medicamento SET precio = precio*(1+(porcentaje/100)) WHERE nombre = p_nombre;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'El medicamento no se pudo modificar';
	ELSE
		RAISE NOTICE 'Modificación realizada exitosamente';
	END IF;
ELSIF p_tipocambio = 'L' THEN
	SELECT * INTO fila_verificacion FROM laboratorio WHERE laboratorio = p_nombre;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'El laboratorio ingresado no existe';
	END IF;
	UPDATE medicamento m SET precio = precio*(1+(porcentaje/100)) FROM laboratorio l 
		WHERE m.id_laboratorio = fila_verificación.id_laboratorio AND l.laboratorio = p_nombre;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No existen medicamentos para modificar';
	ELSE
		RAISE NOTICE 'Modificación realizada exitosamente';
	END IF;
ELSIF p_tipocambio = 'C' THEN
	SELECT * INTO fila_verificacion FROM clasificacion WHERE clasificacion = p_nombre;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'La clasificacion ingresada no existe';
	END IF;
	UPDATE medicamento m SET precio = precio*(1+(porcentaje/100)) FROM clasificacion c  
		WHERE m.clasificacion = fila_verificación.clasificacion AND c.clasificacion = p_nombre;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No existen medicamentos para modificar';
	ELSE
		RAISE NOTICE 'Modificación realizada exitosamente';
	END IF;
ELSE
	RAISE EXCEPTION 'La opción ingresada no es válida';
END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

-- e
CREATE PROCEDURE medicamento_eliminar(p_nombre text) AS $$
DECLARE 
	fila_medicamento medicamento%ROWTYPE;
BEGIN
IF (p_nombre IS NULL OR p_nombre = '') THEN
	RAISE EXCEPTION 'El nombre del medicamento no puede ser nulo ni vacio';
END IF;
SELECT * INTO fila_medicamento FROM medicamento WHERE nombre = p_nombre;
IF NOT FOUND THEN
	RAISE EXCEPTION 'El medicamento que desea eliminar no existe';
END IF;
DELETE FROM tratamiento WHERE id_medicamento = (SELECT id_medicamento FROM medicamento WHERE nombre = p_nombre);
DELETE FROM compra WHERE id_medicamento = (SELECT id_medicamento FROM medicamento WHERE nombre = p_nombre);
DELETE FROM medicamento WHERE nombre = p_nombre;
IF NOT FOUND THEN
	RAISE EXCEPTION 'No se pudo eliminar el medicamento';
END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

-- 2
-- a
CREATE OR REPLACE FUNCTION fn_diferencia_anios(p_fecha DATE) RETURNS int AS $$
DECLARE
	diferencia int;
BEGIN
	-- validación de que la fecha sea menor o igual a la actual
	IF p_fecha > CURRENT_DATE THEN
		RAISE EXCEPTION 'La fecha ingresada debe ser anterior o igual a la fecha actual';
	END IF;
	diferencia := EXTRACT(YEAR FROM AGE(CURRENT_DATE, p_fecha));
	RETURN diferencia;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

SELECT fn_diferencia_anios('2004-06-22');

-- b

CREATE OR REPLACE FUNCTION fn_porcentaje(p_monto numeric(10,2), p_porcentaje float) RETURNS int AS $$
DECLARE
	monto_actualizado numeric(10,2);
BEGIN
	IF p_porcentaje <= -100 OR p_monto < 0  THEN
		RAISE EXCEPTION 'Porcentaje y/o monto ingresados no válidos';
	END IF;
	monto_actualizado := p_monto*(1+(p_porcentaje/100));
	RETURN monto_actualizado;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

SELECT fn_porcentaje(1000, 10);

-- 3

-- a

CREATE OR REPLACE PROCEDURE paciente_internado_por_dni(p_dni text, OUT p_piso int, OUT p_habitacion int, OUT p_cama int) AS $$
DECLARE
	id_paciente int;
BEGIN
	IF p_dni IS NULL OR p_dni = '' THEN
		RAISE EXCEPTION 'El dni ingresado no puede ser nulo ni vacío';
	END IF;
	
    SELECT pa.id_paciente INTO id_paciente
    FROM persona p
    JOIN paciente pa ON p.id_persona = pa.id_paciente
    WHERE p.dni = p_dni;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe un paciente con DNI %', p_dni;
    END IF;
	
	SELECT piso, id_habitacion, id_cama INTO p_piso, p_habitacion, p_cama FROM persona p
	INNER JOIN internacion i ON p.id_persona = i.id_paciente
	INNER JOIN cama USING (id_cama)
	INNER JOIN habitacion USING (id_habitacion)
	WHERE dni = p_dni AND fecha_alta IS NULL;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se ha registrado una internación actual del paciente';
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

-- b

CREATE OR REPLACE PROCEDURE paciente_cantidad_estudios(p_dni text, OUT cantidad_estudios int) AS $$
DECLARE
	id_paciente int;
BEGIN
	IF p_dni IS NULL OR p_dni = '' THEN
		RAISE EXCEPTION 'El dni ingresado no puede ser nulo ni vacío';
	END IF;
	
    SELECT pa.id_paciente INTO id_paciente
    FROM persona p
    JOIN paciente pa ON p.id_persona = pa.id_paciente
    WHERE p.dni = p_dni;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe un paciente con DNI %', p_dni;
    END IF;
	
	SELECT COUNT(*) INTO cantidad_estudios FROM persona p
	INNER JOIN estudio_realizado e ON p.id_persona = e.id_paciente
	WHERE dni = p_dni;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'No se ha registrado ningún estudio del paciente';
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

CALL paciente_cantidad_estudios('6219887', null);

CREATE OR REPLACE PROCEDURE paciente_deuda(p_dni text, OUT adeudado int) AS $$
DECLARE
	id_paciente int;
BEGIN
	IF p_dni IS NULL OR p_dni = '' THEN
		RAISE EXCEPTION 'El dni ingresado no puede ser nulo ni vacío';
	END IF;
	
    SELECT pa.id_paciente INTO id_paciente
    FROM persona p
    JOIN paciente pa ON p.id_persona = pa.id_paciente
    WHERE p.dni = p_dni;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe un paciente con DNI %', p_dni;
    END IF;
	
	SELECT SUM(saldo) INTO adeudado FROM persona p
	INNER JOIN factura f ON p.id_persona = f.id_paciente
	WHERE dni = p_dni;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

CALL paciente_deuda('6219887', null);

CREATE OR REPLACE PROCEDURE medicamento_precio(p_nombre text, OUT p_precio numeric(10,2), OUT p_stock int,OUT p_descuento numeric(10,2)) AS $$
BEGIN
	IF p_nombre IS NULL OR p_nombre = '' THEN
		RAISE EXCEPTION 'El nombre del medicamento ingresado no puede ser nulo ni vacío';
	END IF;
	
    SELECT precio, stock, fn_porcentaje(precio, -10) INTO p_precio, p_stock, p_descuento
    FROM medicamento
    WHERE nombre = p_nombre;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe un medicamento con el nombre %', p_nombre;
    END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

CALL medicamento_precio('ACETAM GOTAS', null, null, null);

CREATE OR REPLACE PROCEDURE empleado_por_dni(p_dni text, OUT p_nombre text, OUT p_apellido text, OUT p_sueldo numeric(9,2), OUT p_antiguedad int) AS $$
BEGIN
	IF p_dni IS NULL OR p_dni = '' THEN
		RAISE EXCEPTION 'El dni ingresado no puede ser nulo ni vacío';
	END IF;
	
    SELECT nombre, apellido, sueldo, fn_diferencia_anios(fecha_ingreso) INTO p_nombre, p_apellido, p_sueldo, p_antiguedad
    FROM persona p
    JOIN empleado e ON p.id_persona = e.id_empleado
    WHERE p.dni = p_dni;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe un empleado con DNI %', p_dni;
    END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Inesperado: %', SQLERRM;
END;
$$ language plpgsql;

CALL empleado_por_dni('18354930', null, null, null, null);
