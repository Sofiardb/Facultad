-- 1
SELECT id_paciente, nombre, apellido, dni FROM persona
INNER JOIN paciente ON id_persona = id_paciente
WHERE id_obra_social IS NULL;

-- 2

SELECT id_empleado, nombre, apellido, sueldo, cargo, especialidad FROM persona
INNER JOIN empleado ON id_persona = id_empleado
INNER JOIN especialidad USING (id_especialidad)
INNER JOIN cargo USING (id_cargo)
ORDER BY cargo, especialidad, sueldo DESC;

-- 3

SELECT DISTINCT id_paciente, ps.nombre, ps.apellido, ps.dni, os.nombre FROM persona ps
INNER JOIN paciente p ON id_persona = id_paciente
INNER JOIN obra_social os USING (id_obra_social)
INNER JOIN consulta USING (id_paciente)
INNER JOIN consultorio c USING (id_consultorio)
WHERE c.nombre IN ('CARDIOLOGIA', 'NEUMONOLOGIA'); -- REVISAR

-- 4

SELECT id_empleado, ps.nombre, ps.apellido, cargo, turno FROM persona ps
INNER JOIN empleado ON id_persona = id_empleado
INNER JOIN cargo USING (id_cargo)
INNER JOIN trabajan USING (id_empleado)
INNER JOIN turno USING (id_turno)
WHERE cargo LIKE '%AUXILIAR%' AND fin IS NULL
ORDER BY apellido, nombre;

-- 5

SELECT id_empleado, nombre, apellido, especialidad, COUNT(id_empleado) AS cantidad_internaciones FROM persona
INNER JOIN empleado ON id_persona = id_empleado
INNER JOIN especialidad USING (id_especialidad) 
INNER JOIN internacion ON ordena_internacion = id_empleado
WHERE especialidad = 'NEUROLOGÍA'
GROUP BY id_empleado, nombre, apellido, especialidad
ORDER BY cantidad_internaciones DESC;

-- 6

SELECT proveedor FROM proveedor WHERE
id_proveedor NOT IN (SELECT id_proveedor FROM compra);

-- 7

SELECT ps.nombre, ps.apellido, ps.dni, os.nombre FROM persona ps
INNER JOIN paciente p ON id_persona = id_paciente
INNER JOIN obra_social os USING (id_obra_social)
INNER JOIN internacion USING (id_paciente)
INNER JOIN cama USING (id_cama)
INNER JOIN habitacion USING (id_habitacion)
INNER JOIN empleado ON id_empleado = ordena_internacion
INNER JOIN especialidad USING (id_especialidad)
WHERE piso = 8 AND especialidad = 'PSIQUIATRÍA' AND (fecha_inicio BETWEEN '2022-01-01' AND '2022-01-31')
ORDER BY fecha_inicio;

-- 8

SELECT id_medicamento, m.nombre, laboratorio, COUNT(id_medicamento) AS cantidad_de_prescripciones FROM medicamento m 
INNER JOIN tratamiento USING (id_medicamento)
INNER JOIN laboratorio USING (id_laboratorio)
GROUP BY  m.nombre, laboratorio
ORDER BY cantidad_de_prescripciones DESC
LIMIT 5;

-- 9

SELECT id_empleado, nombre, apellido FROM persona
INNER JOIN empleado ON id_persona = id_empleado
INNER JOIN cargo USING(id_cargo)
WHERE id_empleado NOT IN (SELECT ordena_internacion FROM internacion
WHERE fecha_inicio BETWEEN '2021-01-01' AND '2021-12-31')
ORDER BY apellido, nombre;

-- 10

SELECT id_paciente, ps.nombre, ps.apellido, SUM(monto) AS total_facturado FROM persona ps
INNER JOIN paciente p ON id_persona = id_paciente
INNER JOIN factura USING (id_paciente)
WHERE(fecha BETWEEN '2022-05-15' AND CURRENT_DATE)
GROUP BY id_paciente, ps.nombre, ps.apellido
HAVING SUM(monto) > (SELECT SUM(monto) FROM persona pe
INNER JOIN paciente ON id_persona = id_paciente
INNER JOIN factura USING (id_paciente) 
WHERE pe.nombre = 'LAURA MONICA' AND pe.apellido = 'JABALOYES' AND (fecha BETWEEN '2022-05-15' AND CURRENT_DATE));


-- 11

SELECT id_paciente, ps.nombre, ps.apellido, COUNT(id_paciente) AS total_internaciones FROM persona ps
INNER JOIN paciente p ON id_persona = id_paciente
INNER JOIN internacion USING (id_paciente)
WHERE(fecha_inicio < '2020-01-01')
GROUP BY id_paciente, ps.nombre, ps.apellido
HAVING COUNT(id_paciente) > (SELECT COUNT(id_paciente) FROM persona pe
INNER JOIN paciente ON id_persona = id_paciente
INNER JOIN internacion USING (id_paciente) 
WHERE pe.nombre = 'MARTA AMALIA' AND pe.apellido = 'GRAMAJO' AND fecha_inicio < '2020-01-01');

-- 12

(SELECT ps.nombre, ps.apellido, '2021-03-04' AS fecha ,costo, 'INTERNACION' AS tipo  FROM persona ps
INNER JOIN paciente p ON id_persona = id_paciente
INNER JOIN internacion USING (id_paciente)
WHERE fecha_inicio = '2021-03-04')
UNION (SELECT ps.nombre, ps.apellido, '2021-03-04' AS fecha,precio, 'ESTUDIO' AS tipo FROM persona ps
INNER JOIN paciente p ON id_persona = id_paciente
INNER JOIN estudio_realizado USING (id_paciente)
WHERE fecha = '2021-03-04')


-- 13

UPDATE medicamento 
SET precio = precio * 1.05
FROM laboratorio
INNER JOIN clasificacion ON clasificacion.id_clasificacion = medicamento.id_clasificacion
WHERE laboratorio.id_laboratorio = medicamento.id_laboratorio
AND laboratorio.nombre = 'LABOSINRATO'
AND (clasificacion.nombre = 'APARATO DIGESTIVO' OR clasificacion.nombre = 'VENDAS');


-- 14

UPDATE mantenimiento_equipo 
SET estado = 'baja', fecha_egreso = CURRENT_DATE
WHERE fecha_egreso IS NULL AND (CURRENT_DATE - fecha_ingreso::DATE) > 100;

-- 15

DELETE FROM clasificacion c
WHERE NOT EXISTS (
    SELECT 1 FROM medicamento m WHERE c.id_clasificacion = m.id_clasificacion
);


-- 16

DELETE FROM compra c
WHERE EXISTS (
    SELECT 1 
    FROM medicamento m
    INNER JOIN clasificacion cl ON m.id_clasificacion = cl.id_clasificacion
    WHERE c.id_medicamento = m.id_medicamento
    AND cl.clasificacion = 'ENERGETICOS'
)
AND c.fecha BETWEEN '2008-03-01' AND '2008-03-15';

DELETE FROM compra c
USING medicamento m, clasificacion cl
WHERE c.id_medicamento = m.id_medicamento
AND m.id_clasificacion = cl.id_clasificacion
AND cl.clasificacion = 'ENERGETICOS'
AND c.fecha BETWEEN '2008-03-01' AND '2008-03-15';
