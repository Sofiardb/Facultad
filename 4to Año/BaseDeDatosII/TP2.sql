-- 1
-- a

SELECT * FROM consultorio ORDER BY interno;

-- b

UPDATE consultorio 
SET interno = 100
WHERE nombre = 'GINECOLOGIA';

-- c

SELECT * FROM consultorio ORDER BY interno;

-- Se puede observar que al introducir un dato númerico en un campo varchar no se produce el ordenamiento correctamente
-- d

UPDATE tratamiento SET dosis = dosis + 2 WHERE id_paciente = 71387 AND id_medicamento = 159;

-- Se produce un error por querer sumar a un campo varchar 2 unidades

-- e

ALTER TABLE consultorio ALTER COLUMN interno SET DATA TYPE integer USING interno::integer;

-- f

ALTER TABLE tratamiento ALTER COLUMN dosis SET DATA TYPE smallint USING dosis::smallint;

-- 2
SELECT * FROM factura;
-- a
/* Es mejor tener un índice por fecha y resultado antes que otro orden ya que la fecha 
es más restrictiva que el resultado, con lo cual en el primer filtro se eliminan más registros.
Todo depende igual del proposito que se le de al campo y lo que vpy a permitir que se cargue en el mismo, antigüedad, etc.
También depende el formato en el que se escribe el resultado, si se debe elegir de una lista de opciones o 
se puede escribir lo que sea, etc.
Sin embargo, en este caso, si se ven los registros se puede observar que los resultados se repiten mucho.*/

-- b

/* Para el caso de la búsqueda por fecha si crearía un índice porque es un filtro de búsqueda recurrente por lo que
reducirá el tiempo de búsqueda tener el índice. Además, debido a la prolongación en el tiempo de las consultas, lo hace
a este filtro bastante restrictivo.
   Para el caso de las facturas pagadas, no es útil usar un índice porque son datos que toman pocos valores por lo que no
es necesario y además al ser un campo que se modificará constantemente, al hacer INSERT, UPDATE o DELETE la tabla tendrá
que actualizarse y ésto no será óptimo*/

-- c 

/*Por número y piso ya que el número es más restrictivo puesto que para cada piso 1,2,3,..., los números de habitaciones
comienzan con ese respectivo número.*/

-- d

/*No conviene un índice en esa tabla ya que es una tabla como pocos registros y que no tiene una proyección mayor a
la actual*/

-- e

/*Yo no crearía el índice por el id porque al ser pk, ya existe. Debería crear un índice por apellido, nombre o dni 
(dependiendo el criterio de búsqueda más utilizado) así optimiza la búsqueda del paciente y después hago el join con 
la tabla consulta*/

-- f

/*Crearía un índice parcial filtrando las facturas con un WHERE donde la condición se cumpla que el monto > 100000*/

-- g

/*El índice debería ser en la tabla especialidad pero esto no tiene sentido ya que la tabla es chica y cada
especialidad hace una única vez*/

-- 3

-- a

EXPLAIN ANALYZE SELECT * FROM factura
WHERE fecha BETWEEN '2021-01-01' AND '2021-03-31';

-- PLANNING TIME: 0.176 ms EXECUTION TIME: 141.470 ms

-- b

CREATE INDEX indice_fecha_factura ON factura(fecha);

-- c

-- PLANNING TIME: 0.181 ms EXECUTION TIME: 37.425 ms. Mejoró 73.54%

-- d

SELECT pg_size_pretty(pg_table_size('factura')) AS factura,  pg_size_pretty(pg_table_size('indice_fecha_factura')) AS indice_factura;

-- e

-- Índice para buscar por apellido, nombre compuesto.
CREATE INDEX idx_persona_nombre ON persona(apellido, nombre);

-- Índice para buscar por DNI
CREATE INDEX idx_persona_dni ON persona(dni);

-- Índice para optimizar búsquedas por fecha en factura
CREATE INDEX idx_factura_fecha ON factura(fecha);

-- Índice para optimizar búsquedas por fecha en consulta
CREATE INDEX idx_consulta_fecha ON consulta(fecha);

-- Índice para optimizar búsquedas por fecha_alta en internaciones
CREATE INDEX idx_internaciones_fecha_alta ON internacion(fecha_alta);

-- Índice para optimizar búsquedas por fecha en estudio_realizado
CREATE INDEX idx_estudio_realizado_fecha ON estudio_realizado(fecha);

-- Índice para optimizar búsquedas por fecha en compra
CREATE INDEX idx_compra_fecha ON compra(fecha);

-- Índice para optimizar búsquedas por nombre en medicamento
CREATE INDEX idx_medicamento_nombre ON medicamento(nombre);

-- Índice para optimizar búsquedas por stock en medicamento
CREATE INDEX idx_medicamento_stock ON medicamento(stock)
WHERE stock < 10;


-- Índice para optimizar búsquedas por fecha_ingreso en empleado
CREATE INDEX idx_empleado_fecha_ingreso ON empleado(fecha_ingreso);

-- 4
-- a
/*
Tabla: personas
Campo	Tipo de dato
idPersona	SERIAL INTEGER (PK)
idBarrio	INTEGER (FK)
nombres	VARCHAR(50)
apellidos	VARCHAR(100)
documento	VARCHAR(8) 
fechaNacimiento	DATE
sexo	CHAR(1) (por ejemplo: 'M', 'F')
tieneDiscapacidad	BOOL
tieneObraSocial	BOOL
esJubilado	BOOL
salarioUniversal	BOOL
cuil	VARCHAR(11)
telefono	VARCHAR(20)
domicilio	VARCHAR(200)
baja	BOOL
idNivelEscolar	INTEGER (FK)
idEnfermedad	INTEGER (FK, nullable)

Tabla: gruposFamiliares
Campo	Tipo de dato
idGrupoFamiliar	SERIAL INTEGER (PK)
materialCasa	VARCHAR(50)
tieneBaño	BOOL
tipoBaño	VARCHAR(50)
tieneAgua	BOOL
tieneLuz	BOOL

Tabla: personasgruposfamiliares
Campo	Tipo de dato
idPersona	INTEGER (FK)
idGrupoFamiliar	INTEGER (FK)
desde	DATE
hasta	DATE

Tabla: beneficios
Campo	Tipo de dato
idBeneficio	SERIAL INTEGER (PK)
beneficio	VARCHAR(100)
stock	INTEGER
stockIlimitado	BOOL

Tabla: personasBeneficios
Campo	Tipo de dato
fechaAud	DATE
idPersona	INTEGER (FK)
idBeneficio	INTEGER (FK)
idSolicitante	INTEGER
cantidad	INTEGER 

abla: nivelesEscolares
Campo	Tipo de dato
idNivelEscolar	SERIAL INTEGER (PK)
nivelEscolar	VARCHAR(50)

Tabla: barrios
Campo	Tipo de dato
idBarrio	SERIAL INTEGER (PK)
barrio	VARCHAR(50)

Tabla: enfermedades
Campo	Tipo de dato
idEnfermedad	SERIAL INTEGER (PK)
enfermedad	VARCHAR(100)

*/

-- b

/*
En el caso de la tabla persona, las búsquedas más recurrentes se dan por nombre y apellido o dni. Por lo tanto crearía
un índice por dni y otro índice compuesto por apellido y nombre.

Lo beneficios a los que se pueden acceder también serán consultados permanentemente. Por lo tanto, haría un índice por
el nombre del beneficio (campo beneficio) y también crearía un índice parcial por stock marcando un valor límite inferior
para conocer cuales son los beneficios cuyos cupos están próximos a completarse.

Otro criterio de búsqueda permanente podría ser la fecha de auditoría para que una persona reciba un beneficio. Por lo
tanto crearía un índice por fecha en la tabla personasBeneficios.

En cuanto a la tabla personasgruposfamiliares, las consultas respecto de cuando empezó una persona a formar parte del 
grupo familiar asi como también conocer si sigue vigente en ese grupo serán constantes. Luego, crearía un índice para
desde y otro para hasta.

*/