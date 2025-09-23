CREATE ROLE rdelbs_grupo_informes WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

CREATE ROLE rdelbs_grupo_admision WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

CREATE ROLE rdelbs_grupo_rrhh WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

CREATE ROLE rdelbs_grupo_medicos WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1

CREATE ROLE rdelbs_grupo_compras WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

CREATE ROLE rdelbs_grupo_facturacion WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

CREATE ROLE rdelbs_grupo_mantenimiento WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

CREATE ROLE rdelbs_grupo_sistemas WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

CREATE ROLE rdelbs_user_informes WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'rdelb1234';

GRANT rdelbs_grupo_informes TO rdelbs_user_informes;

CREATE ROLE rdelbs_user_admision WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'rdelb1234';

GRANT rdelbs_grupo_admision TO rdelbs_user_admision;

CREATE ROLE rdelbs_user_rrhh WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'rdelb1234';

GRANT rdelbs_grupo_rrhh TO rdelbs_user_rrhh;

CREATE ROLE rdelbs_user_medicos WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'rdelb1234';

GRANT rdelbs_grupo_medicos TO rdelbs_user_medicos;

CREATE ROLE rdelbs_user_compras WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'rdelb1234';

GRANT rdelbs_grupo_compras TO rdelbs_user_compras;

CREATE ROLE rdelbs_user_facturacion WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'rdelb1234';

GRANT rdelbs_grupo_facturacion TO rdelbs_user_facturacion;

CREATE ROLE rdelbs_user_mantenimiento WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'rdelb1234';

GRANT rdelbs_grupo_mantenimiento TO rdelbs_user_mantenimiento;

CREATE ROLE rdelbs_user_sistemas WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'rdelb1234';

GRANT rdelbs_grupo_sistemas TO rdelbs_user_sistemas;


-- Permisos de Informes

GRANT USAGE ON SCHEMA public TO rdelbs_grupo_informes;
-- a
GRANT SELECT ON TABLE paciente, obra_social, persona TO rdelbs_grupo_informes, rdelbs_grupo_medicos;
-- b
GRANT SELECT ON TABLE consulta, diagnostico, patologia, empleado, tratamiento, medicamento TO rdelbs_grupo_informes, rdelbs_grupo_medicos;
-- c
GRANT SELECT ON TABLE internacion, cama, habitacion TO rdelbs_grupo_informes, rdelbs_grupo_medicos;
-- d
GRANT SELECT ON TABLE estudio_realizado, estudio, equipo TO rdelbs_grupo_informes, rdelbs_grupo_medicos;

-- Permisos Admisión

GRANT USAGE ON SCHEMA public TO rdelbs_grupo_admision;

-- a
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE paciente, persona TO rdelbs_grupo_admision, rdelbs_grupo_medicos;
-- b
GRANT SELECT ON TABLE  consulta, diagnostico, patologia, estudio_realizado, estudio, consultorio TO rdelbs_grupo_admision, rdelbs_grupo_medicos;
-- c
GRANT INSERT ON TABLE consulta TO rdelbs_grupo_admision, rdelbs_grupo_medicos;
-- d
GRANT INSERT ON TABLE estudio_realizado TO rdelbs_grupo_admision, rdelbs_grupo_medicos;

-- e
GRANT SELECT, UPDATE, INSERT ON TABLE internacion TO rdelbs_grupo_admision, rdelbs_grupo_medicos;

-- Permisos RRHH

GRANT USAGE ON SCHEMA public TO rdelbs_grupo_rrhh;

-- a

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE persona, empleado TO rdelbs_grupo_rrhh;

-- b

GRANT SELECT, INSERT ON TABLE trabajan TO rdelbs_grupo_rrhh;
GRANT SELECT, UPDATE ON TABLE especialidad, trabajan, turno, cargo TO rdelbs_grupo_rrhh;


-- Permisos medicos

GRANT USAGE ON SCHEMA public TO rdelbs_grupo_medicos;

-- a

GRANT SELECT ON TABLE persona, consultorio TO rdelbs_grupo_medicos;
GRANT INSERT ON TABLE consulta TO rdelbs_grupo_medicos;

-- b
GRANT SELECT ON TABLE medicamento TO rdelbs_grupo_medicos;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tratamiento TO rdelbs_grupo_medicos;

-- c

GRANT SELECT ON TABLE patologia TO rdelbs_grupo_medicos;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE diagnostico TO rdelbs_grupo_medicos;

-- d

GRANT SELECT ON TABLE estudio, equipo TO rdelbs_grupo_medicos;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE estudio_realizado TO rdelbs_grupo_medicos;

-- e
-- Se los agrego en informes y admision

-- Permisos compras

GRANT USAGE ON SCHEMA public TO rdelbs_grupo_compras;

-- a

GRANT SELECT ON TABLE compra,proveedor, medicamento, clasificacion, laboratorio, persona TO rdelbs_grupo_compras;

-- b, c, d
GRANT INSERT, UPDATE, DELETE ON TABLE proveedor, medicamento, clasificacion, laboratorio TO rdelbs_grupo_compras;
-- Permisos Facturacion

GRANT USAGE ON SCHEMA public TO rdelbs_grupo_facturacion;
-- a

GRANT SELECT ON TABLE persona, paciente, factura TO rdelbs_grupo_facturacion;

-- b

GRANT INSERT, UPDATE, DELETE ON TABLE factura TO rdelbs_grupo_facturacion;
-- c y d
GRANT SELECT, INSERT, UPDATE,DELETE ON TABLE pago TO rdelbs_grupo_facturacion;

-- Permisos mantenimiento

GRANT USAGE ON SCHEMA public TO rdelbs_grupo_mantenimiento;
 -- a

GRANT SELECT ON TABLE equipo, mantenimiento_equipo TO rdelbs_grupo_mantenimiento;

-- b

GRANT SELECT ON TABLE cama, mantenimiento_equipo TO rdelbs_grupo_mantenimiento;

-- c

GRANT SELECT ON TABLE habitacion TO rdelbs_grupo_mantenimiento;
GRANT INSERT ON TABLE cama, equipo TO rdelbs_grupo_mantenimiento;

-- permisos de sistemas
GRANT USAGE ON SCHEMA public TO rdelbs_grupo_sistemas; 
-- a, b, c, d, e, f, g, h
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE estudio, tipo_estudio, cargo, especialidad, consultorio, obra_social, turno TO rdelbs_grupo_sistemas; 

-- 2
-- a

-- Puede ser realizada por los grupos informes y médicos.
SELECT p.nombre, apellido, COALESCE(o.nombre, 'Sin obra social') FROM paciente pc
INNER JOIN persona p ON pc.id_paciente = p.id_persona
LEFT JOIN obra_social o USING(id_obra_social);

-- b

-- La puede realizar rrhh

SELECT p.nombre, apellido, cargo, especialidad, sueldo FROM empleado e
INNER JOIN persona p ON e.id_empleado = p.id_persona
INNER JOIN cargo USING(id_cargo)
INNER JOIN especialidad USING(id_especialidad)
WHERE fecha_baja IS NULL;

-- c

-- No la puede realizar ninguno

SELECT t.nombre, t.descripcion, m.nombre, presentacion, clasificacion FROM tratamiento t
INNER JOIN medicamento m USING(id_medicamento)
INNER JOIN clasificacion USING(id_clasificacion)
WHERE dosis > 3;

-- d

-- La puede realizar admision, informes y medicos

SELECT CONCAT(pa.apellido,', ',pa.nombre) AS paciente, CONCAT(pe.apellido,', ',pe.nombre) AS medico, fecha, resultado
FROM consulta c
INNER JOIN persona pa ON pa.id_persona = c.id_paciente
INNER JOIN persona pe ON pe.id_persona = c.id_empleado
WHERE fecha BETWEEN '2022-01-01' AND '2022-03-31';

-- e

-- Puede realizarla facturacion
SELECT id_factura, fecha, hora, monto, saldo FROM factura
WHERE pagada = 'N' AND saldo < monto;

-- f
-- La puede realizar admision, informes y medicos
SELECT fecha, hora, resultado FROM consulta
INNER JOIN persona ON id_empleado = id_persona
WHERE nombre = 'ANGELA' AND apellido = 'MENDOZA'
ORDER BY fecha, hora;

-- g

-- La puede realizar informes y medicos
(SELECT p.nombre, apellido, 'Estudio' AS tipo, fecha , resultado 
FROM estudio_realizado 
INNER JOIN persona p ON id_paciente = id_persona
WHERE p.nombre = 'SOFIA' AND apellido = 'TELLO'
UNION 
SELECT p.nombre, apellido, 'Consulta' AS tipo, fecha AS fecha, resultado 
FROM consulta
INNER JOIN persona p ON id_paciente = id_persona
WHERE p.nombre = 'SOFIA' AND apellido = 'TELLO'
UNION
SELECT p.nombre, apellido, 'Internacion'  AS tipo, fecha_inicio AS fecha, CONCAT('Alta:', ' ', fecha_alta) AS alta
FROM internacion
INNER JOIN persona p ON id_paciente = id_persona
WHERE p.nombre = 'SOFIA' AND apellido = 'TELLO'
UNION
SELECT p.nombre, apellido, 'Tratamiento'  AS tipo, fecha_indicacion AS fecha, m.nombre
FROM tratamiento
INNER JOIN persona p ON id_paciente = id_persona
INNER JOIN medicamento m USING(id_medicamento)
WHERE p.nombre = 'SOFIA' AND apellido = 'TELLO')
ORDER BY fecha;

-- h
-- Puede realizarla facturacion
SELECT p.nombre, p.apellido, id_factura, pa.fecha, pa.monto
FROM pago pa
INNER JOIN factura f USING(id_factura)
INNER JOIN persona p ON p.id_persona = f.id_paciente
WHERE p.nombre = 'SERGIO DANIEL' AND p.apellido = 'PEREZ';

-- i

-- Puede realizarla mantenimiento
SELECT id_equipo, nombre 
FROM mantenimiento_equipo
INNER JOIN equipo USING(id_equipo)
WHERE fecha_egreso IS NULL;

-- j
-- Puede realizarla compras
SELECT c.fecha, m.nombre, proveedor, p.nombre
FROM compra c
INNER JOIN proveedor USING(id_proveedor)
INNER JOIN medicamento m USING(id_medicamento)
INNER JOIN laboratorio USING (id_laboratorio)
INNER JOIN persona p ON c.id_empleado = p.id_persona
WHERE laboratorio = 'ROEMMERS';

-- k

-- La puede realizar compras

INSERT INTO laboratorio (id_laboratorio, laboratorio, direccion, telefono)
VALUES (206, 'LABUNT', 'AV. INDEPENDENCIA 1800', '54-381-123-5555');

-- l

-- No la puede realizar ningun usuario
INSERT INTO mantenimiento_cama (id_cama, fecha_ingreso, observacion, estado, fecha_egreso, demora, id_empleado)
VALUES(52, '2023-02-02', 'A la espera de repuestos', 'En reparacion',
null, 26, 210);

-- m
-- La puede hacer compras
UPDATE laboratorio
SET telefono = '54-381-456-5555'
WHERE laboratorio = 'LABUNT';

-- n

-- La puede realizar RRHH
UPDATE trabajan t
SET fin = CURRENT_DATE
FROM persona p, turno tu
WHERE t.id_turno = tu.id_turno AND t.id_empleado = p.id_persona AND p.nombre = 'PABLO ALEJANDRO' AND p.apellido = 'MEDRANO'
AND turno = 'Sabado';

INSERT INTO trabajan (id_empleado, id_turno, inicio)
VALUES (
  (SELECT id_persona FROM persona p WHERE p.nombre = 'PABLO ALEJANDRO' AND p.apellido = 'MEDRANO'),
  (SELECT id_turno FROM turno WHERE turno = 'Domingo'),
  CURRENT_DATE + INTERVAL '1 day'
);

-- o

-- Puede realizar compras
DELETE FROM laboratorio
WHERE laboratorio = 'MERELL';

-- 3
-- a

CREATE SCHEMA facturacion
    AUTHORIZATION postgres;

-- b

ALTER TABLE IF EXISTS public.factura
  SET SCHEMA facturacion;

ALTER TABLE IF EXISTS public.pago
  SET SCHEMA facturacion;

-- c

/*Primero no la puedo ejecutar por el siguiente error: 'no existe la relación «pago»'. Esto se debe a que se está
trabajando sobre el esquema public y las tablas a las que se consulta se encuentran en este momento en el esquema
facturación. Además, se le debe otorgar el acceso al esquema facturación al grupo facturación. 
Luego, para que esta funcione primero debemos otorgar el uso del esquema al grupo facturacion. Además en la consulta
se debe referenciar a las tablas pago y factura como facturacion.pago y facturacion.factura para que reconozca la
existencia de dichas tablas.*/
GRANT USAGE ON SCHEMA facturacion TO rdelbs_grupo_facturacion;

SELECT p.nombre, p.apellido, id_factura, pa.fecha, pa.monto
FROM facturacion.pago pa
INNER JOIN facturacion.factura f USING(id_factura)
INNER JOIN persona p ON p.id_persona = f.id_paciente
WHERE p.nombre = 'SERGIO DANIEL' AND p.apellido = 'PEREZ';