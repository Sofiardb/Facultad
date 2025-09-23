
-- 1
-- a
CREATE DATABASE tp4_pedidos
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
CREATE TYPE cargo AS ENUM ('administrativo', 'vendedor',
'cajero', 'gerente');

CREATE TYPE sector AS ENUM ('ventas', 'compras', 'gerencia',
'depósito');

CREATE TYPE	domicilio AS(
		calle VARCHAR(100),
		nro VARCHAR(10),
		ciudad VARCHAR(50)
); 

CREATE TABLE public.persona
(
    id_persona serial NOT NULL,
    nombre character varying(150) NOT NULL,
    dni character varying(8) NOT NULL,
    mail character varying(100)[],
    domicilio domicilio NOT NULL,
    CONSTRAINT pk_persona PRIMARY KEY (id_persona)
);

ALTER TABLE persona ALTER COLUMN mail DROP NOT NULL;

CREATE TABLE public.empleado
(
    cargo cargo NOT NULL,
    sector sector NOT NULL,
    legajo character varying(20) NOT NULL,
    sueldo numeric(10,2),
    CONSTRAINT pk_empleado PRIMARY KEY (id_persona)
)
    INHERITS (public.persona);

CREATE TABLE public.cliente
(
    cuenta_corriente character varying(50) NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_persona)
)
    INHERITS (public.persona);

ALTER TABLE cliente ALTER COLUMN cuenta_corriente DROP NOT NULL;

CREATE TABLE public.pedido
(
    id_empleado integer NOT NULL,
    id_cliente integer NOT NULL,
    fecha date NOT NULL,
    total numeric(10,2) NOT NULL,
    CONSTRAINT pk_pedido PRIMARY KEY (id_empleado, id_cliente, fecha),
    CONSTRAINT fk_empleado FOREIGN KEY (id_empleado)
        REFERENCES public.empleado (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT fk_cliente FOREIGN KEY (id_cliente)
        REFERENCES public.cliente (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);

-- b
/*
Se genera una secuencia que que puede tomar valores del 1 a 2147483647 que incrementa en una unidad. Además, muestra
el último valor de la secuencia. Como en este caso no se creó ninguna persona toma el valor 1.
*/
-- c
-- d

INSERT INTO empleado (id_persona, nombre, dni, mail, domicilio, sueldo, sector, cargo, legajo)
VALUES (default, 'VILCARROMERO, ERIK', '17130935', array['vilcarro@gmail.com', 'vilco@live.com'],row('AV SANTA ROSA', '1177', 'S.M.TUC')
		, 550000, 'ventas', 'cajero', '1232');
INSERT INTO empleado (id_persona, nombre, dni, mail, domicilio, sueldo, sector, cargo, legajo)
VALUES ((SELECT MAX(id_persona) + 1 FROM persona), 'MUNIZ, SILVA', '27418519', array['muniz@gmail.com', 'silvi@gmail.com'], 
		row('AV. AREQUIPA', '2288', 'SALTA'),
		  692000, 'gerencia', 'gerente', '1002');
		  
INSERT INTO cliente (id_persona, nombre, dni, mail, domicilio, cuenta_corriente)
VALUES (default, 'JARUFE, ERNESTO','31569934', array['jarus@gmail.com'],
	row('LAS BEGONIAS', '451', 'LA PLATA'), 'F1515');

SELECT * FROM persona;

SELECT * FROM empleado;

SELECT * FROM cliente;

/*Podemos ver que en la tabla persona el id_persona se repite a pesar de que es pk. Esto se debe que al usar el 
max(id_persona) + 1 no se incrementa la secuencia generada para el serial del id_persona. Luego, este queda con 2 como 
próximo valor, el cual se introduce en el cliente.*/

INSERT INTO cliente (id_persona, nombre, dni, mail, domicilio, cuenta_corriente)
VALUES (default, 'HUAPAYA, CLAUDIA','23185175', array['huap@gmail.com', 'laud@gmail.com'],
	row('COLOMBIA', '395', 'SALTA'), 'G1254');

INSERT INTO empleado (id_persona, nombre, dni, mail, domicilio, sueldo, sector, cargo, legajo)
VALUES (default, 'VASQUEZ, JUAN', '44125608', array['vasquez@gmail.com', 'juan@gmail.com'],row('AV REPUBLICA', '3755', 'SALTA')
		, 423000, 'depósito', 'administrativo', '1123');

DELETE FROM empleado WHERE dni = '27418519';

SELECT * from  persona;

INSERT INTO cliente (id_persona, nombre, dni, domicilio, cuenta_corriente)
VALUES (4, 'RAMES, MAYRA','12113059', row('J.P FERNANDINI', '1140', 'LA PLATA'),  'C3321');


INSERT INTO cliente(id_persona, nombre, dni, domicilio, mail)
VALUES (4, 'ABON, ALFREDO', '29085527', row('AV BOLIVIA', '1157', 'S.M.TUC'), array['abon@gmail.com', 'abon@live.com']);

/*El primer registro lo puedo insertar y el segundo no se puede. Podemos ver que en persona hay dos personas con id 4.
Esto se debe a que uno es empleado y el primer insertado es cliente. Luego, no está violando la restricción de pk
en la tabla cliente en la primera inserción. En cambio, en la segunda, se está ingresando un nuevo cliente con id 4
luego viola la restricción de la pk.*/


-- Partición por año desde 2021 a 2025
CREATE TABLE public.pedido2021
(
	CHECK (fecha >= '2021-01-01' AND fecha <= '2021-12-31'),
    CONSTRAINT pk_pedido2021 PRIMARY KEY (id_empleado, id_cliente, fecha),
    CONSTRAINT fk_empleado2021 FOREIGN KEY (id_empleado)
        REFERENCES public.empleado (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT fk_cliente2021 FOREIGN KEY (id_cliente)
        REFERENCES public.cliente (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION
)
	INHERITS (public.pedido);

CREATE TABLE public.pedido2022
(
	CHECK (fecha >= '2022-01-01' AND fecha <= '2022-12-31'),
    CONSTRAINT pk_pedido2022 PRIMARY KEY (id_empleado, id_cliente, fecha),
    CONSTRAINT fk_empleado2022 FOREIGN KEY (id_empleado)
        REFERENCES public.empleado (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT fk_cliente2022 FOREIGN KEY (id_cliente)
        REFERENCES public.cliente (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION
)
	INHERITS (public.pedido);

CREATE TABLE public.pedido2023
(
	CHECK (fecha >= '2023-01-01' AND fecha <= '2023-12-31'),
    CONSTRAINT pk_pedido2023 PRIMARY KEY (id_empleado, id_cliente, fecha),
    CONSTRAINT fk_empleado2023 FOREIGN KEY (id_empleado)
        REFERENCES public.empleado (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT fk_cliente2023 FOREIGN KEY (id_cliente)
        REFERENCES public.cliente (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION
)
	INHERITS (public.pedido);

CREATE TABLE public.pedido2024
(
	CHECK (fecha >= '2024-01-01' AND fecha <= '2024-12-31'),
    CONSTRAINT pk_pedido2024 PRIMARY KEY (id_empleado, id_cliente, fecha),
    CONSTRAINT fk_empleado2024 FOREIGN KEY (id_empleado)
        REFERENCES public.empleado (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT fk_cliente2024 FOREIGN KEY (id_cliente)
        REFERENCES public.cliente (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION
)
	INHERITS (public.pedido);

CREATE TABLE public.pedido2025
(
	CHECK (fecha >= '2025-01-01' AND fecha <= '2025-12-31'),
    CONSTRAINT pk_pedido2025 PRIMARY KEY (id_empleado, id_cliente, fecha),
    CONSTRAINT fk_empleado2025 FOREIGN KEY (id_empleado)
        REFERENCES public.empleado (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT fk_cliente2025 FOREIGN KEY (id_cliente)
        REFERENCES public.cliente (id_persona) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION
)
	INHERITS (public.pedido);

-- 2

-- a

SELECT * FROM obra_social;  

CREATE TYPE personayobrasocial AS (
	id_paciente integer,
	nombre_paciente VARCHAR(100),
	apellido_paciente VARCHAR(100),
	sigla VARCHAR(15),
	nombre_obra_social VARCHAR(100)
);

CREATE TYPE empleado_cargo_sueldo AS (
	id_empleado integer,
	nombre VARCHAR(100),
	apellido VARCHAR(100),
	cargo VARCHAR(50),
	sueldo NUMERIC(9,2)
);

CREATE TYPE empleado_ingreso_especialidad AS (
	id_empleado integer,
	nombre VARCHAR(100),
	apellido VARCHAR(100),
	especialidad VARCHAR(50),
	fecha_ingreso DATE
);

CREATE TYPE medicamento_produccion_stock AS (
	id_medicamento integer,
	medicamento VARCHAR(50),
	stock integer,
	clasificacion VARCHAR(75),
	laboratorio VARCHAR(50)
);

CREATE TYPE medicamento_produccion_proveedor AS (
	id_medicamento integer,
	medicamento VARCHAR(50),
	clasificacion VARCHAR(75),
	laboratorio VARCHAR(50),
	precio_unitario NUMERIC(10,2),
	proveedor VARCHAR(50)
);

CREATE TYPE informacion_consulta AS (
	nombre_paciente VARCHAR(100),
	apellido_paciente VARCHAR(100),
	nombre_empleado VARCHAR(100),
	apellido_empleado VARCHAR(100),
	fecha_consulta DATE,
	consultorio VARCHAR(50)
);

CREATE TYPE informacion_estudio AS (
	nombre_paciente VARCHAR(100),
	apellido_paciente VARCHAR(100),
	nombre_estudio VARCHAR(100),
	fecha_estudio DATE,
	precio numeric(10,2)
);

CREATE TYPE informacion_internacion AS (
	nombre_paciente VARCHAR(100),
	apellido_paciente VARCHAR(100),
	nombre_empleado VARCHAR(100),
	apellido_empleado VARCHAR(100),
	fecha_alta DATE,
	costo numeric(10,2)
);

CREATE TYPE factura_paciente AS (
	id_factura integer,
	fecha DATE,
	monto numeric(10,2),
	nombre_paciente VARCHAR(100),
	apellido_paciente VARCHAR(100)
);

CREATE TYPE pagos_paciente AS (
	fecha DATE, 
	monto numeric(10,2),
	nombre_paciente VARCHAR(100),
	apellido_paciente VARCHAR(100)
);

CREATE TYPE equipos_empleado AS (
	nombre_empleado VARCHAR(100),
	apellido_empleado VARCHAR(100),
	fecha_ingreso DATE,
	marca_equipo VARCHAR(50),
	equipo VARCHAR(100),
	estado_equipo VARCHAR(25)
);
SELECT * from mantenimiento_equipo;
SELECT * FROM medicamento INNER JOIN clasificacion USING(id_clasificacion) INNER JOIN laboratorio USING(id_laboratorio);
SELECT * FROM compra;
SELECT * FROM internacion;