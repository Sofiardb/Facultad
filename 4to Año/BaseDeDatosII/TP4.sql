-- 1
BEGIN


UPDATE medicamento m
SET precio = precio*1.05
FROM clasificacion c, laboratorio l
WHERE m.id_clasificacion = c.id_clasificacion AND m.id_laboratorio = l.id_laboratorio
AND clasificacion LIKE 'ANTIINFECCIOSOS%' AND laboratorio = 'ABBOTT LABORATORIOS';

UPDATE medicamento m
SET precio = precio*0.975
FROM clasificacion c, laboratorio l
WHERE m.id_clasificacion = c.id_clasificacion AND m.id_laboratorio = l.id_laboratorio
AND clasificacion LIKE 'ANTIINFECCIOSOS%' AND laboratorio = 'BRISTOL CONSUMO';

SAVEPOINT MOD1;

UPDATE medicamento m
SET precio = precio*0.955
FROM clasificacion c, laboratorio l
WHERE m.id_clasificacion = c.id_clasificacion AND m.id_laboratorio = l.id_laboratorio
AND clasificacion LIKE 'ANTIINFECCIOSOS%' AND laboratorio = 'FARMINDUSTRIA';

SAVEPOINT MOD2;

UPDATE medicamento m
SET precio = precio*1.07
FROM clasificacion c, laboratorio l
WHERE m.id_clasificacion = c.id_clasificacion AND m.id_laboratorio = l.id_laboratorio
AND clasificacion LIKE 'ANTIINFECCIOSOS%' AND laboratorio NOT IN ('FARMINDUSTRIA', 'BRISTOL CONSUMO', 'ABBOTT LABORATORIOS');

COMMIT;

-- 2

BEGIN;

INSERT INTO persona (id_persona, nombre, apellido, dni, fecha_nacimiento, telefono, domicilio)
VALUES ((SELECT MAX(id_persona) + 1 FROM persona), 'JUAN', 'PEREZ', '3172286', '1984-08-20', '54-381-326-1780','AV-MITRE 643');

SAVEPOINT personacreada;

INSERT INTO paciente (id_paciente, id_obra_social)
VALUES ((SELECT id_persona FROM persona WHERE dni = '3172286'), (SELECT id_obra_social FROM obra_social WHERE nombre = 'OBRA SOCIAL DE LOCUTORES'));

COMMIT;

-- 3

BEGIN;

-- a
INSERT INTO estudio_realizado (id_paciente, id_estudio, fecha, id_equipo, id_empleado, resultado, observacion, precio)
VALUES (
	(SELECT id_persona FROM persona WHERE dni = '3172286'),
	(SELECT id_estudio FROM estudio WHERE nombre = 'ESPIROMETRIA COMPUTADA'),
	'2025-04-15',
	(SELECT id_equipo FROM equipo WHERE nombre = 'LARINGOSCOPIO'),
	(SELECT id_persona FROM persona WHERE nombre = 'EVA' AND apellido = 'ROJO'),
	'NORMAL',
	'NO SE OBSERVAN IRREGULARIDADES',
	3280.00
);
SAVEPOINT a;

-- b 
INSERT INTO internacion (id_paciente, id_cama, fecha_inicio, ordena_internacion)
VALUES (
	(SELECT id_persona FROM persona WHERE dni = '3172286'),
	157,
	'2025-04-16',
	(SELECT id_persona FROM persona WHERE nombre = 'PAULA DANIELA' AND apellido = 'ALBORNOZ')
);


SAVEPOINT b;
-- c
INSERT INTO tratamiento (id_paciente, id_medicamento, fecha_indicacion, prescribe, nombre, descripcion, dosis, costo)
VALUES 
	(
		(SELECT id_persona FROM persona WHERE dni = '3172286'),
		(SELECT id_medicamento FROM medicamento WHERE nombre = 'AFRIN ADULTOS SOL'),
		'2025-04-16',
		(SELECT id_persona FROM persona WHERE nombre = 'PAULA DANIELA' AND apellido = 'ALBORNOZ'),
		'AFRIN ADULTOS SOL',
		'FRASCO x 15 CC',
		1,
		1821.79
	),
	(
		(SELECT id_persona FROM persona WHERE dni = '3172286'),
		(SELECT id_medicamento FROM medicamento WHERE nombre = 'NAFAZOL'),
		'2025-04-16',
		(SELECT id_persona FROM persona WHERE nombre = 'PAULA DANIELA' AND apellido = 'ALBORNOZ'),
		'NAFAZOL',
		'FRASCO X 15 ML',
		2,
		1850.96
	),
	(
		(SELECT id_persona FROM persona WHERE dni = '3172286'),
		(SELECT id_medicamento FROM medicamento WHERE nombre = 'VIBROCIL GOTAS NASALES'),
		'2025-04-16',
		(SELECT id_persona FROM persona WHERE nombre = 'PAULA DANIELA' AND apellido = 'ALBORNOZ'),
		'VIBROCIL GOTAS NASALES',
		'FRASCO X 15 CC',
		2,
		2500.66
	);

SAVEPOINT c;

-- d
SELECT * from internacion; 

UPDATE internacion
SET fecha_alta = '2025-04-19', hora = '11:30:00', costo = 120000.00
WHERE id_paciente = (SELECT id_persona FROM persona WHERE dni = '3172286') AND id_cama = 157 AND fecha_inicio = '2025-04-16';

COMMIT;

-- 4
BEGIN;
INSERT INTO factura (id_factura, id_paciente, fecha, hora, monto, pagada, saldo)
VALUES (
	(SELECT MAX(id_factura) + 1 FROM factura),
	(SELECT id_persona FROM persona WHERE dni = '3172286'), 
	CURRENT_DATE, 
	CURRENT_TIME, 
	((SELECT precio FROM estudio_realizado WHERE id_paciente = (SELECT id_persona FROM persona WHERE dni = '3172286')) + 
	 (SELECT costo FROM internacion WHERE id_paciente = (SELECT id_persona FROM persona WHERE dni = '3172286')) +
	 (SELECT SUM(costo) FROM tratamiento WHERE id_paciente = (SELECT id_persona FROM persona WHERE dni = '3172286'))
	), 
	'N', 
	((SELECT precio FROM estudio_realizado WHERE id_paciente = (SELECT id_persona FROM persona WHERE dni = '3172286')) + 
	 (SELECT costo FROM internacion WHERE id_paciente = (SELECT id_persona FROM persona WHERE dni = '3172286')) +
	 (SELECT SUM(costo) FROM tratamiento WHERE id_paciente = (SELECT id_persona FROM persona WHERE dni = '3172286'))
	)
);

-- 5

-- a
-- User medico
SELECT * FROM patologia WHERE id_patologia = 1;

-- User postgres

BEGIN;
UPDATE patologia
SET nombre = 'RDELB'
WHERE id_patologia = 1;

-- User medico
SELECT * FROM patologia WHERE id_patologia = 1;

-- No se ve el nombre actualizado. Sigue en tos
-- postgres
COMMIT;

-- User medico
SELECT * FROM patologia WHERE id_patologia = 1;

-- Ahora ya se ve el nombre actualizado con el apellido de POSTGRES

-- Nivel de aislamiento es READ COMMITTED

-- b

BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM patologia WHERE id_patologia = 1;
-- Se ve la patologia de id 1 con el apellido de postgres
-- codigo postgres
BEGIN;
UPDATE patologia
SET nombre = 'SOFIA'
WHERE id_patologia = 1;

-- Vuelvo a mostrar patología 1 como medico y aún veo el apellido de postgres como nombre

-- Postgres comitea
COMMIT;
SELECT * FROM patologia WHERE id_patologia = 1;
-- postgres observa la patología 1 actualizada

-- Vuelvo a mostrar patología 1 como medico y aún veo el apellido de postgres como nombre
-- comitea medico
COMMIT;

-- Vuelvo a mostrar patología 1 y ahora veo el nombre actualizado

-- 6
BEGIN;
UPDATE empleado e
SET sueldo = sueldo*1.25
FROM cargo c
WHERE e.id_cargo = c.id_cargo AND cargo = 'DIRECTOR';

SAVEPOINT punto6a; 

UPDATE empleado e
SET sueldo = sueldo*1.20
FROM cargo c
WHERE e.id_cargo = c.id_cargo AND cargo = 'DIRECTOR AREA OPERATIVA';

SELECT * FROM empleado
INNER JOIN cargo USING(id_cargo)
WHERE cargo = 'DIRECTOR AREA OPERATIVA'
ORDER BY sueldo DESC;

ROLLBACK TO punto6a;

UPDATE empleado e
SET sueldo = sueldo*1.15
FROM cargo c
WHERE e.id_cargo = c.id_cargo AND cargo = 'DIRECTOR FISCALIZACION SANITARIA';

SELECT * FROM empleado
INNER JOIN cargo USING(id_cargo)
WHERE cargo = 'DIRECTOR FISCALIZACION SANITARIA'
ORDER BY sueldo DESC;

COMMIT;

-- 7

BEGIN;
INSERT INTO compra (id_medicamento, id_proveedor, fecha, id_empleado, precio_unitario, cantidad)
VALUES (
	(SELECT id_medicamento FROM medicamento WHERE nombre = 'DORIXINA'),
	(SELECT id_proveedor FROM proveedor WHERE proveedor = 'DECO S.A.'),
	'2025-04-20',
	(SELECT id_persona FROM persona WHERE nombre = 'RUBEN' AND apellido = 'LENES'),
	0.7*(SELECT precio FROM medicamento WHERE nombre = 'DORIXINA'),
	200
	),
	(
	(SELECT id_medicamento FROM medicamento WHERE nombre = 'TRAMAL GOTAS'),
	(SELECT id_proveedor FROM proveedor WHERE proveedor = 'DIFESA'),
	'2025-04-23',
	(SELECT id_persona FROM persona WHERE nombre = 'ADRIANA SONIA' AND apellido = 'DIAZ'),
	0.7*(SELECT precio FROM medicamento WHERE nombre = 'DORIXINA'),
	60
);

COMMIT;

-- 8
BEGIN;

DELETE FROM compra c
USING medicamento m
WHERE c.id_medicamento = m.id_medicamento AND m.nombre = 'SINEMET';

DELETE FROM tratamiento t 
USING medicamento m
WHERE t.id_medicamento = m.id_medicamento AND m.nombre = 'SINEMET';

DELETE FROM medicamento 
WHERE nombre = 'SINEMET';
COMMIT;

SELECT apellido, nombre, cargo FROM persona p
INNER JOIN empleado e ON e.id_empleado = p.id_persona
INNER JOIN cargo USING(id_cargo)
INNER JOIN mantenimiento_cama USING(id_empleado)
INNER JOIN cama USING (id_cama)
INNER JOIN habitacion h USING (id_habitacion)
WHERE piso = 5 AND h.tipo = 'TRIPLES' AND demora < 50;

select * from internacion;