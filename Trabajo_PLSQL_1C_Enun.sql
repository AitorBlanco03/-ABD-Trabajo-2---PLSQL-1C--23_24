/*
 * Base de datos de una empresa de eventos que organiza un
 * festival de música y teatro.
 *
 * Autores:
 *      - Álvaro Villar Val (avv1013@alu.ubu.es)
 *      - David Ibeas Morrondo (dim1002@alu.ubu.es)
 *      - Aitor Blanco Fernández (abf1005@alu.ubu.es)
 *
 * Github: https://github.com/AitorBlanco03/-ABD-Trabajo-2---PLSQL-1C--23_24.git
 * Versión: 5.0
 */

-- Se eliminan las tablas existentes en caso de que ya existan.
drop table clientes cascade constraints;
drop table abonos   cascade constraints;
drop table eventos  cascade constraints;
drop table reservas	cascade constraints;

-- Se eliminan las secuencias existentes en caso de que ya existan.
drop sequence seq_abonos;
drop sequence seq_eventos;
drop sequence seq_reservas;


-- Creación de tablas y secuencias

-- Tabla para almacenar la información de los clientes.
create table clientes(
	NIF	varchar(9) primary key,
	nombre	varchar(20) not null,
	ape1	varchar(20) not null,
	ape2	varchar(20) not null
);

-- Secuencia para generar las PKs de la tabla abonos.
create sequence seq_abonos;

-- Tabla para almacenar la información de los abonos de los clientes.
create table abonos(
	id_abono	integer primary key,
	cliente  	varchar(9) references clientes,
	saldo	    integer not null check (saldo>=0)
    );

-- Secuencia para generar las PKs de la tabla eventos.
create sequence seq_eventos;

-- Tabla para almacenar la información de los eventos.
create table eventos(
	id_evento	integer  primary key,
	nombre_evento		varchar(20),
    fecha       date not null,
	asientos_disponibles	integer  not null
);

-- Secuencia para generar las PKs de la tabla reservas.
create sequence seq_reservas;

-- Tabla para almacenar información de las reservas.
create table reservas(
	id_reserva	integer primary key,
	cliente  	varchar(9) references clientes,
    evento      integer references eventos,
	abono       integer references abonos,
	fecha	date not null
);


	
-- Procedimiento almacenado que implementa la lógica para realizar una reserva.
create or replace procedure reservar_evento( arg_NIF_cliente varchar,
 arg_nombre_evento varchar, arg_fecha date) is
 
    -- Creamos la excepción -20001, para detectar eventos que ya han pasados.
    evento_pasado exception;
    pragma exception_init(evento_pasado, -20001);
    
    -- Creamos la excepción -20002, para detectar clientes inexistentes.
    cliente_inexistente exception;
    pragma exception_init(cliente_inexistente, -20002);
    
    -- Creamos la excepción -20003, para detectar eventos inexistentes.
    evento_inexistente exception;
    pragma exception_init(evento_inexistente, -20003);
    
    -- Creamos la excepción -20004, para detectar clientes sin saldo en su abono.
    saldo_insuficiente exception;
    pragma exception_init(saldo_insuficiente, -20004);
    
    -- Creamos la excepción -20005, para detectar eventos sin plazas disponibles.
    plazas_agotadas exception;
    pragma exception_init(plazas_agotadas, -20005);
    
    -- Variable para almacenar la fecha del evento.
    v_fecha_evento date;
    
    -- Variable para almacenar los asientos disponibles del evento.
    v_asientos_disponibles integer;
    
    -- Variable para almacenar el saldo del abono del usuario.
    v_saldo_abono integer;
    
 begin
  
    -- PASO 1: Comprobamos que el evento no ha pasado.
    begin
        
        -- Obtenemos la fecha del evento a partir del nombre del evento.
        select fecha into v_fecha_evento
        from eventos
        where nombre_evento = arg_nombre_evento
        for update;
        
        -- Si la fecha del evento es anterior a la proporcionada, lanzamos la excepción -20001.
        if v_fecha_evento < arg_fecha then
            rollback;
            raise_application_error(-20001, 'No se pueden reservar eventos pasados');
        end if;
        
    exception
    
        -- Si el evento no se encuentra, reformulamos la excepción no_data_found y lanzamos la excepción -20003.
        when no_data_found then
            rollback;
            raise_application_error(-20003, 'El evento ' || arg_nombre_evento || ' no existe');
            
    end;
    
    -- PASO 2: Comprobamos la disponibilidad de plazas del evento y el saldo del abono del cliente.
    begin
        
        -- Obtenemos la disponibilidad de plazas a partir del nombre del evento.
        select asientos_disponibles into v_asientos_disponibles
        from eventos
        where nombre_evento = arg_nombre_evento
        for update;
        
        -- Si no hay suficientes asientos disponibles, lanzamos la excepción -20005.
        if v_asientos_disponibles <= 0 then
            rollback;
            raise_application_error(-20005, 'No hay suficientes asientos disponibles para ' || arg_nombre_evento);
        end if;
        
        -- Obtenemos el saldo del abono del cliente.
        select saldo into v_saldo_abono
        from abonos
        where cliente = arg_NIF_cliente
        for update;
        
        -- Si el cliente no tiene suficiente saldo en su abono, lanzamos la excepción -20004.
        if v_saldo_abono <= 0 then
            rollback;
            raise_application_error(-20004, 'Saldo en abono insuficiente');
        end if;
        
    exception
    
        -- Si el cliente no se encuentra, reformulamos la excepción no_data_found y lanzamos la excepción -20002.
        when no_data_found then
            rollback;
            raise_application_error(-20002, 'Cliente inexistente');
        
    end;
    
    -- PASO 3: Formalizamos y realizamos la reserva.
    begin
    
        -- Descontamos una unidad del saldo del abono del cliente.
        update abonos
        set saldo = saldo - 1
        where cliente = arg_NIF_cliente;
        
        -- Descontamos el número de plazas disponibles para el evento.
        update eventos
        set asientos_disponibles = asientos_disponibles - 1
        where nombre_evento = arg_nombre_evento;
        
        -- Insertamos la información de la reserva en la tabla de reservas.
        insert into reservas
        values (seq_reservas.nextval,
                arg_NIF_cliente,
                (select id_evento from eventos where nombre_evento = arg_nombre_evento),
                (select id_abono from abonos where cliente = arg_NIF_cliente),
                arg_fecha);
                
    exception
    
        -- Capturamos cualquier excepción durante el proceso y hacemos rollback si hay errores.
        when others then
            rollback;
            raise;
    end;
    
    -- Confirmamos los cambios en la base de datos, si la reserva se realiza con éxito.
    commit;
    
    
end;
/

------ Respuestas a las preguntas del enunciado:

-- * P4.1 . El resultado de la comprobación del paso 2 ¿sigue siendo fiable en el paso 3?:

-- Sí, el resultado de la comprobación del paso 2 sigue siendo fiable en el paso 3. Esto se debe
-- principalmente a que las condiciones verificadas en el paso 2, se evaluán nuevamente antes de
-- realizar la reserva en el paso 3.

-- * P4.2 . En el paso 3, la ejecución concurrente del mismo procedimiento reservar_evento con, quizás otros o los mismos argumentos, 
-- ¿podría habernos añadido una reserva no recogida en esa SELECT que fuese incompatible con nuestra reserva?, ¿por qué?.

-- No, porque al incluir las cláusulas 'FOR UPDATE' nos permite asegurar que ninguna otra reserva pueda modificar esas filas
-- mientras se esté llevando a cabo una reserva.

-- * P4.3 . ¿Qué estrategia de programación has utilizado?:

-- Hemos utilizado una estrategia defensiva. Esta estrategia se basa en anticipar posibles errores
-- o condiciones inesperadas y manejarlas de manera proactiva mediante el uso de excepciones y
-- rollback. En lugar de confiar de que todas las operaciones se ejecuten sin problemas, nos
-- preparamos para manejar cualquier situación inesperada de manera segura.

-- * P4.4 ¿Cómo puede verse este hecho en tu código?

-- En el código, la estrategia defensiva se puede ver en el manejo de excepciones, donde anticipamos
-- los posibles errores y tomamos las medidas adecuadas para manejarlos antes de realizar la reserva del evento.

-- * P4.5 ¿De qué otro modo crees que podrías resolver el problema propuesto? Incluye el pseudocódigo.

-- Otro manera de implementar reservar_evento es optar una estrategia agresiva.

-- PSEUDOCÓDIGO:
--  1.- Actualizar y reducir el número de plazas para el evento.
--      - Si no se encuentra el evento o si el evento ya ha pasado, lanzamos la excepción correspondiente,
--  2.- Actualizar y reducir el saldo del abono.
--      - Si no se encuentra el cliente o si el cliente no tiene suficiente saldo, lanzamos la excepción correspondiente.
--  3.- Realizar la reserva.
--      - Si ocurré algún error, revertimos todos los cambios realizados.



-- Procedimiento almacenado para reinicar una secuencia.
create or replace
procedure reset_seq( p_seq_name varchar )
is
    l_val number;
begin
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by -' || l_val || 
                                                          ' minvalue 0';
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

end;
/

-- Procedimiento almacenado para iniciar la base de datos con los datos del test.
create or replace procedure inicializa_test is
begin
  
  -- Reiniciamos todas las secuencias de la base de datos.
  reset_seq( 'seq_abonos' );
  reset_seq( 'seq_eventos' );
  reset_seq( 'seq_reservas' );
        
    -- Borramos todos los datos de las tablas de nuestra base de datos.
    delete from reservas;
    delete from eventos;
    delete from abonos;
    delete from clientes;
    
    -- Insertamos en la base de datos los datos para realizar los tests.
    insert into clientes values ('12345678A', 'Pepe', 'Perez', 'Porras');
    insert into clientes values ('11111111B', 'Beatriz', 'Barbosa', 'Bernardez');
    
    insert into abonos values (seq_abonos.nextval, '12345678A',10);
    insert into abonos values (seq_abonos.nextval, '11111111B',0);
    
    insert into eventos values ( seq_eventos.nextval, 'concierto_la_moda', date '2024-6-27', 200);
    insert into eventos values ( seq_eventos.nextval, 'teatro_impro', date '2024-7-1', 50);

    commit;
end;
/

exec inicializa_test;

-- Procedimiento almacenado que ejecuta los tests para el procedimiento reservar_evento.
create or replace procedure test_reserva_evento is
begin
	 
  --CASO DE PRUEBA 1: Reserva correcta, se realiza.
  begin
    -- Iniciamos la base de datos para los tests en la base de datos.
    inicializa_test;
    dbms_output.put_line('CASO DE PRUEBA 1: Reserva correcta--------------------');
    dbms_output.put_line('');
    
    -- Realizamos una reserva de manera correcta con datos válidos.
    reservar_evento('12345678A','concierto_la_moda',date '2024-6-27');
    
    -- Verificamos que la reserva se ha realizado correctamente consultando la tabla reserva.
    declare
        num_reservas integer;
    begin
        -- Contamos el número de reservas que existen para estos datos.
        select count(*)
        into num_reservas
        from reservas
        where cliente = '12345678A'
        and evento = (select id_evento from eventos where nombre_evento='concierto_la_moda')
        and fecha = date '2024-6-27';
        
        -- Comprobamos que existe una única reserva para estos datos
        if num_reservas = 1 then
            dbms_output.put_line('OK: Reserva realizada correctamente.');
            dbms_output.put_line('');
        else
            dbms_output.put_line('FAIL: No realiza la reserva correctamente.');
            dbms_output.put_line('');
        end if;
    end;
  
  exception
  
    -- No pasará el test si lanza un excepción a la hora de hacer la reserva.
    when others then
        dbms_output.put_line('FAIL: Da error.');
        dbms_output.put_line('Error nro: '||SQLCODE);
        dbms_output.put_line('Mensaje: '||SQLERRM);
        dbms_output.put_line('');
  end;
  
  --CASO DE PRUEBA 2: Evento pasado.
  begin
    -- Inicializamos la base de datos para los tests en la base de datos.
    inicializa_test;
    dbms_output.put_line('CASO DE PRUEBAS 2: Evento pasado--------------------');
    dbms_output.put_line('');
    
    -- Intentamos hacer una reserva de un evento pasado.
    reservar_evento('12345678A', 'concierto_la_moda', date '2024-9-25');
    
    -- No pasará el test si se realiza una reserva de un evento pasado.
    dbms_output.put_line('FAIL: Reserva para un evento que ya ha pasado.');
    dbms_output.put_line('');
    
  exception
    
    when others then
        -- Comprobamos que se lanza la excepción -20001.
        if sqlcode = -20001 then
            dbms_output.put_line('OK: Detecta evento pasado.');
            dbms_output.put_line('Error nro: '||SQLCODE);
            dbms_output.put_line('Mensaje: '||SQLERRM);
            dbms_output.put_line('');
        else
            dbms_output.put_line('FAIL: Da error, pero no detecta evento pasado.');
            dbms_output.put_line('Error nro: '||SQLCODE);
            dbms_output.put_line('Mensaje: '||SQLERRM);
            dbms_output.put_line('');
        end if;
  end;
  
  --CASO DE PRUEBA 3: Evento inexistente.
  begin
    -- Inicializamos la base de datos para los tests en la base de datos.
    inicializa_test;
    dbms_output.put_line('CASO DE PRUEBA 3: Evento inexistente--------------------');
    dbms_output.put_line('');
    
    -- Intentamos hacer una reserva de un evento inexistente.
    reservar_evento('12345678A','Monologo chiquito de la calzada',date '2024-6-27');
    
    -- No pasará el test si se realiza una reserva de un evento inexistente.
    dbms_output.put_line('FAIL: Reserva para un evento que no existe.');
    dbms_output.put_line('');
    
  exception
  
    when others then
        -- Comprobamos que se lanza la excepción -20003.
        if sqlcode = -20003 then
            dbms_output.put_line('OK: Detecta evento inexistente.');
            dbms_output.put_line('Error nro: '||SQLCODE);
            dbms_output.put_line('Mensaje: '||SQLERRM);
            dbms_output.put_line('');
        else
            dbms_output.put_line('FAIL: Da error, pero no detecta evento inexistente.');
            dbms_output.put_line('Error nro: '||SQLCODE);
            dbms_output.put_line('Mensaje: '||SQLERRM);
            dbms_output.put_line('');
        end if;
  end;
  

  --CASO DE PRUEBA 4: Cliente inexistente. 
  begin
    -- Inicializamos la base de datos para los tests en la base de datos.
    inicializa_test;
    dbms_output.put_line('CASO DE PRUEBA 4: Cliente inexistente--------------------');
    dbms_output.put_line('');
    
    -- Intentamos hacer una reserva para un cliente que no existe.
    reservar_evento('12345678B', 'concierto_la_moda', date '2023-6-27');
    
    -- No pasará el test si se realiza una reserva para un cliente que no existe,
    dbms_output.put_line('FAIL: Reserva para un cliente que no existe.');
    dbms_output.put_line('');

  exception
  
    when others then
        --Comprobamos que se lanza la excepción -20002.
        if sqlcode = -20002 then
            dbms_output.put_line('OK: Detecta cliente inexistente.');
            dbms_output.put_line('Error nro: '||SQLCODE);
            dbms_output.put_line('Mensaje: '||SQLERRM);
            dbms_output.put_line('');
        else
            dbms_output.put_line('FAIL: Da error, pero no detecta cliente inexistente.');
            dbms_output.put_line('Error nro: '||SQLCODE);
            dbms_output.put_line('Mensaje: '||SQLERRM);
            dbms_output.put_line('');
        end if;
  end;
  
  --caso 5 El cliente no tiene saldo suficiente
  begin
    -- Inicializamos la base de datos para los tests en la base de datos.
    inicializa_test;
    dbms_output.put_line('CASO DE PRUEBA 5: El cliente no tiene suficiente saldo---------------------');
    dbms_output.put_line('');
    
    -- Intentamos hacer una reserva para un cliente sin saldo.
    reservar_evento('11111111B','teatro_impro',date '2023-7-1');
    
    -- No pasará el test si se realiza una reserva para un cliente sin saldo.
    dbms_output.put_line('FAIL: Reserva para un cliente sin saldo en su abono.');
    dbms_output.put_line('');
    
  exception
    
    when others then
        -- Comprobamos que se lanza la excepción -20004.
        if sqlcode = -20004 then
            dbms_output.put_line('OK: Detecta cliente sin saldo.');
            dbms_output.put_line('Error nro: '||SQLCODE);
            dbms_output.put_line('Mensaje: '||SQLERRM);
            dbms_output.put_line('');
        else
            dbms_output.put_line('FAIL: Da error, pero no detecta cliente sin saldo.');
            dbms_output.put_line('Error nro: '||SQLCODE);
            dbms_output.put_line('Mensaje: '||SQLERRM);
            dbms_output.put_line('');
        end if;
  end;

  
end;
/


set serveroutput on;
exec test_reserva_evento;
