
--  EJERCICIO 1
-- a1
CREATE TABLE public.parentesco
(
    id_parentesco smallint NOT NULL,
    parentesco character varying(20) NOT NULL,
    PRIMARY KEY (id_parentesco)
);

CREATE TABLE public.familiar
(
    id_familiar integer NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    dni character varying(8) NOT NULL,
    fecha_nacimiento date NOT NULL,
	id_empleado integer NOT NULL,
    id_parentesco smallint NOT NULL,
    PRIMARY KEY (id_familiar),
    CONSTRAINT fk_parentesco FOREIGN KEY (id_parentesco)
        REFERENCES public.parentesco (id_parentesco) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION
        NOT VALID,
	CONSTRAINT fk_empleado FOREIGN KEY (id_empleado)
        REFERENCES public.empleado (id_empleado) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION
        NOT VALID
);


-- a2

CREATE TABLE public.ciudad
(
    id_ciudad smallint NOT NULL,
    ciudad character varying(50) NOT NULL,
    PRIMARY KEY (id_ciudad)
);



CREATE TABLE public.provincia
(
    id_provincia smallint NOT NULL,
    provincia character varying(50) NOT NULL,
    PRIMARY KEY (id_provincia)
);


ALTER TABLE paciente ADD COLUMN id_ciudad smallint;

ALTER TABLE paciente ADD CONSTRAINT fk_ciudad FOREIGN KEY (id_ciudad)
        REFERENCES public.ciudad (id_ciudad) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE SET NULL;

ALTER TABLE paciente ADD COLUMN id_provincia smallint;

ALTER TABLE paciente ADD CONSTRAINT fk_provincia FOREIGN KEY (id_provincia)
        REFERENCES public.provincia (id_provincia) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE SET NULL;

-- b

-- b1

/*Propongo un índice por fecha ya que es un criterio de búsqueda usado. Además, el valor de la fecha toma gran cantidad
de valores distintos lo cual hace que el índice sea útil para acelerar la búsqueda. No agregaría un índice por pagada 
ya que solo toma dos valores por lo que un índice no aceleraría lo suficiente la búsqueda respecto al costo de generar
la tabla del índice pagada y las operaciones de insert, update o delete que se deberían realizar llegado el caso.*/

CREATE INDEX idx_fecha_factura ON factura(fecha);

-- b2

/*Crearía un índice compuesto (localidad, provincia) para filtrar las obras sociales por este criterio en ese orden ya
que la localidad es un criterio más restrictivo que la provincia dado que la cantidad de obras sociales por localidad 
será menor que la totalidad de obras sociales de una dada provincia. Esto nos permitirá generar un mejor filtro para 
luego buscar por provincia. Este último filtro es necesario puesto que existen localidades de un mismo nombre en 
distintas provincias*/

CREATE INDEX idx_ubicacion_obrasocial ON obra_social(localidad, provincia);

-- b3

/*No crearía ningún índice en este caso ya que el filtro en este caso se aplica sobre la placa proveedor, la cual
es una tabla pequeña por lo que el uso del índice no acelerará de manera significativa la performance de la consulta
respecto del costo de mantener la tabla del índice*/


-- EJERCICIO 2

-- a
CREATE ROLE "SegParcial" WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

-- b

CREATE ROLE rodriguezdelbusto_s WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD '1234';

GRANT "SegParcial" TO rodriguezdelbusto_s;
-- c

GRANT CREATE ON DATABASE hospital_parcial TO "SegParcial";
GRANT USAGE ON SCHEMA public TO "SegParcial";
-- 1

CREATE SCHEMA jubilaciones;
-- 2
GRANT CREATE ON SCHEMA jubilaciones TO "SegParcial";
CREATE TABLE jubilaciones.empleado_jubilado
(
    id_empleado integer NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    dni character varying(8) NOT NULL,
    edad smallint NOT NULL,
    antiguedad smallint NOT NULL,
    PRIMARY KEY (id_empleado)
);

-- 3
GRANT SELECT ON public.persona TO "SegParcial";
GRANT SELECT(id_empleado, fecha_ingreso) ON public.empleado TO "SegParcial";
GRANT INSERT ON jubilaciones.empleado_jubilado TO "SegParcial";

INSERT INTO jubilaciones.empleado_jubilado
SELECT id_empleado, nombre, apellido, dni, extract(year from age(current_date, fecha_nacimiento)), extract(year from age(current_date, fecha_ingreso))
FROM persona p
INNER JOIN empleado e ON p.id_persona = e.id_empleado
WHERE extract(year from age(current_date, fecha_nacimiento)) > 70 AND  extract(year from age(current_date, fecha_ingreso)) > 30;

-- 4

GRANT SELECT(id_medicamento, fecha), DELETE ON compra TO "SegParcial";
GRANT SELECT(id_medicamento, id_clasificacion) ON medicamento TO "SegParcial";
GRANT SELECT ON clasificacion TO "SegParcial";

DELETE FROM compra c
USING medicamento m, clasificacion cl
WHERE c.id_medicamento = m.id_medicamento AND m.id_clasificacion = cl.id_clasificacion
AND c.fecha BETWEEN '2020-03-01' AND '2022-03-15' AND cl.clasificacion = 'ANTIVIRAL';

-- EJERCICIO 3
BEGIN;

CREATE SCHEMA facturacion;

SAVEPOINT creacion;

CREATE TABLE facturacion.paciente AS (SELECT * FROM public.paciente);

SAVEPOINT creacioncliente;

ALTER TABLE internacion SET SCHEMA facturacion;
ALTER TABLE pago SET SCHEMA facturacion;
ALTER TABLE factura SET SCHEMA facturacion;
ALTER TABLE tratamiento SET SCHEMA facturacion;

SAVEPOINT incisoc;

INSERT INTO public.persona
VALUES((SELECT MAX(id_persona) + 1 FROM public.persona), 'JUAN', 'PEREZ', '9999850', '2000-03-12','Av. Roca 200', '100000');

SAVEPOINT personacreada;

INSERT INTO paciente 
VALUES((SELECT id_persona FROM public.persona WHERE dni = '9999850'), 49);

SAVEPOINT pacienteagregado;

INSERT INTO facturacion.factura 
VALUES((SELECT MAX(id_factura)+1 FROM facturacion.factura), 
		(SELECT id_persona FROM public.persona WHERE dni = '9999850'),
		'2025-05-04',
		'12:35',
		153841.32,
		'N',
		100000);
SAVEPOINT facturagregada;

INSERT INTO facturacion.pago
VALUES ((SELECT MAX(id_factura) FROM facturacion.factura), (SELECT fecha FROM facturacion.factura WHERE id_factura = (SELECT MAX(id_factura) FROM facturacion.factura)), 53481.32);

SAVEPOINT pagoagregado;

COMMIT;