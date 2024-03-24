/**
 * Código SQL que presenta la base de datos de una empresa de eventos
 * que organiza un festival de música y teatro.
 *
 * Autores:
 *      - Álvaro Villar Val (avv1013@alu.ubu.es)
 *      - David Ibeas Morrondo (dim1002@alu.ubu.es)
 *      - Aitor Blanco Fernández (abf1005@alu.ubu.es)
 *
 * Github: https://github.com/AitorBlanco03/-ABD-Trabajo-2---PLSQL-1C--23_24
 */

-- Eliminamos las tablas existentes si ya existen en la base de datos, junto con las restricciones asociadas.

DROP TABLE clientes CASCADE constrains;
DROP TABLE abonos CASCADE constrains;
DROP TABLE eventos CASCADE constrains;
DROP TABLE reservas CASCADE constrains;

-- Eliminamos las secuencias existentes si ya existen en la base de datos.

DROP SEQUENCE seq_abonos;
DROP SEQUENCE seq_eventos;
DROP SEQUENCE seq_reservas;

-- Creamos la tabla 'clientes' para almacenar la información de los clientes.

CREATE TABLE clientes (
    NIF varchar(9)                  PRIMARY KEY,
    nombre varchar(30)              NOT NULL,
    ape1 varchar(20)                NOT NULL,
    ape2 varchar(20)                NOT NULL
);

-- Creamos la secuencia 'seq_abonos' para generar valores automáticos para los IDs de los abonos.

CREATE SEQUENCE seq_abonos;

-- Creamos la tabla 'abonos' para almacenar la información de los abonos de los clientes.

CREATE TABLE abonos (
    id_abono integer                PRIMARY KEY,
    cliente varchar(9)              REFERENCES clientes,
    saldo integer                   NOT NULL CHECK (saldo >= 0)
);

-- Creamos la secuencia 'seq_eventos' para generar valores automáticos para los IDs de los eventos.

CREATE SEQUENCE seq_eventos;

-- Creamos la tabla 'eventos' para almacenar la información de los eventos disponibles.

CREATE TABLE eventos (
    id_evento integer               PRIMARY KEY,
    nombre_evento varchar(20),
    fecha date                      NOT NULL,
    asientos_disponibles integer    NOT NULL
);

-- Creamos la secuencia 'seq_reservas' para generar valores automáticos para los IDs de las reservas.

CREATE SEQUENCE seq_reservas;

-- Creamos la tabla 'reservas' para almacenar la información de las reservas.

CREATE TABLE reservas (
    id_reservas integer             PRIMARY KEY,
    cliente varchar(9)              REFERENCES clientes,
    evento integer                  REFERENCES eventos,
    abono integer                   REFERENCES abonos,
    fecha date                      NOT NULL
);

-- Procedimiento almacenado para realizar la reserva de un evento para una fecha especifica.

CREATE OR REPLACE PROCEDURE reservar_evento ( arg_NIF_cliente varchar,
 arg_nombre_evento varchar, arg_fecha date) IS
 BEGIN
    NULL;  --TODO: IMPLEMENTAR LA LÓGICA PARA LA RESERVAS.
 END;
/

------ Respuestas a las preguntas proporcionadas en el enunciado:

-- * P4.1
--
-- * P4.2
--
-- * P4.3
--
-- * P4.4
--
-- * P4.5
--

-- Procedimiento almacenado para reiniciar el valor de una secuencia dada.

CREATE OR REPLACE PROCEDURE reset_seq ( p_seq_name varchar ) IS
    l_val number;
BEGIN
    EXECUTE IMMEDIATE 
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    EXECUTE IMMEDIATE
    'alter sequence ' || p_seq_name || ' increment by -' || l_val ||
                                                          ' minvalue 0';

    EXECUTE IMMEDIATE
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    EXECUTE IMMEDIATE
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

END;
/

-- Procedimiento almacenado para inicializar la base de datos con los datos de prueba para los test.

CREATE OR REPLACE PROCEDURE inicializa_test IS
BEGIN

    -- Reiniciamos los valores de las secuencias.
    reset_seq ( 'seq_abonos' );
    reset_seq ( 'seq_eventos' );
    reset_seq ( 'seq_reservas' );

    -- Eliminamos todos los datos de las tablas.
    DELETE FROM reservas;
    DELETE FROM eventos;
    DELETE FROM abonos;
    DELETE FROM clientes;

    -- Insertamos los datos de prueba en las tablas correspondientes.
    INSERT INTO clientes VALUES ('12345678A', 'Pepe', 'Perez', 'Porras');
    INSERT INTO clientes VALUES ('11111111B', 'Beatriz', 'Barbosa', 'Bernardez');

    INSERT INTO abonos VALUES (seq_abonos.nextval, '12345678A', 10);
    INSERT INTO abonos VALUES (seq_abonos.nextval, '11111111B', 0);

    INSERT INTO eventos VALUES (seq_eventos.nextval, 'concierto_la_moda', date '2023-6-27', 200);
    INSERT INTO eventos VALUES (seq_eventos.nextval, 'teatro_impro', date '2023-7-1', 50);

    COMMIT;
END;
/

-- Ejecutamos el procedimiento 'inicializa_test' para inicializar la base de datos con los datos de prueba.

EXEC inicializa_test;

-- Procedimiento almacenado que contiene todos los tests para el procedimiento 'reservar_evento'.

CREATE OR REPLACE PROCEDURE test_reserva_evento IS
BEGIN

    -- CASO DE PRUEBA 1: Si se intenta realizar una reserva con valores correctos, la reserva se realiza.
    BEGIN
        inicializa_test;
        --TODO: HACER CASO DE PRUEBA 1.
    END;

    -- CASO DE PRUEBA 2: Si se intenta hacer una reserva de un evento pasado, devuelve el error -20001.
    BEGIN
        inicializa_test;
        --TODO: HACER CASO DE PRUEBA 2.
    END;

    -- CASO DE PRUEBA 3: Si se intenta hacer una reserva de un evento inexistente, devuelve el error -20003.
    BEGIN
        inicializa_test;
        --TODO: HACER CASO DE PRUEBA 3.
    END;

    -- CASO DE PRUEBA 4: Si se intenta hacer una reserva a un cliente inexistente devuelve el error -20002.
    BEGIN
        inicializa_test;
        --TODO: HACER CASO DE PRUEBA 4.
    END;

    -- CASO DE PRUEBA 5: Si se intenta hacer una reserva para un cliente sin suficiente saldo en su abono devuelve el error -20004.
    BEGIN
        inicializa_test;
        --TODO: HACER CASO DE PRUEBA 5.
    END;


END;
/

SET serveroutput ON;

-- Ejecutamos los tests para el procedimiento 'reservar_eventos'.
EXEC test_reserva_evento;