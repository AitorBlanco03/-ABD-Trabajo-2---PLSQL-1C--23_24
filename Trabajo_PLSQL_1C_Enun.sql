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
 *Versión:2.5
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
        where nombre_evento = arg_nombre_evento;
        
        -- Si la fecha del evento es anterior a la proporcionada, lanzamos la excepción -20001.
        if v_fecha_evento > arg_fecha then
            raise_application_error(-20001, 'No se pueden reservar eventos pasados');
        end if;
        
    exception
    
        -- Si el evento no se encuentra, reformulamos la excepción no_data_found y lanzamos la excepción -20003.
        when no_data_found then
            raise_application_error(-20003, 'El evento ' || arg_nombre_evento || ' no existe');
            
    end;
    
    -- PASO 2: Comprobamos la disponibilidad de plazas del evento y el saldo del abono del cliente.
    begin
        
        -- Obtenemos la disponibilidad de plazas a partir del nombre del evento.
        select asientos_disponibles into v_asientos_disponibles
        from eventos
        where nombre_evento = arg_nombre_evento;
        
        -- Si no hay suficientes asientos disponibles, lanzamos la excepción -20005.
        if v_asientos_disponibles <= 0 then
            raise_application_error(-20005, 'No hay suficientes asientos disponibles para ' || arg_nombre_evento);
        end if;
        
        -- Obtenemos el saldo del abono del cliente.
        select saldo into v_saldo_abono
        from abonos
        where cliente = arg_NIF_cliente;
        
        -- Si el cliente no tiene suficiente saldo en su abono, lanzamos la excepción -20004.
        if v_saldo_abono <= 0 then
            raise_application_error(-20004, 'Saldo en abono insuficiente');
        end if;
        
    exception
    
        -- Si el cliente no se encuentra, reformulamos la excepción no_data_found y lanzamos la excepción -20002.
        when no_data_found then
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
-- * P4.1
--
-- * P4.2
--
-- * P4.3
-- Hemos utilizado una estrategia de programación defensiva
-- * P4.4
--
-- * P4.5
-- 


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
    reservar_evento('12345678A','concierto_la_moda',date '2024-6-27');
    reservar_evento('12345678A','teatro_impro',date '2024-7-1');
    /*reservar_evento('11111111B','teatro_impro',date '2024-7-1');*/
  end;
  
  --CASO DE PRUEBA 2: Evento pasado.
  begin
    -- Inicializamos la base de datos para los tests en la base de datos.
    inicializa_test;
    dbms_output.put_line('CASO DE PRUEBAS 2: Evento pasado--------------------');
    reservar_evento('12345678A','concierto_la_moda',date '2023-6-25');
    -- En caso de que no salte la excepción nos saldra por pantalla que ha fallado
    dbms_output.put_line('MAL: No se ha lanzado ninguna excepción');
    --  Cazamos la excepción que salte
    exception
        when others then
            if (SQLCODE=-20001) then --En caso de que salte la excepción que queremos la -20001
                dbms_output.put_line('BIEN,Lanza la excepción -20001 cuando se intenta reservar un evento por un cliente que no existe'); --Imprimimos que esta correcto
                if(SQLERRM='ORA-20001: No se pueden reservar eventos pasados') then --Comprobamos que lanza el mensaje tambien correcto
                    dbms_output.put_line('BIEN,Manda el mensaje de error correcto: '|| SQLERRM); -- Imprimimos que el mensaje esta correcto
                else --En caso de que el mensaje no este correcto
                    dbms_output.put_line('MAL,Lanza la excepción -20001 pero no el mensaje de error correcto'); --Imprimimos que esta incorrecto
                end if;
                
            else --En caso de que nos de cualquiera otra excepción la imprimieremos por pantalla junto con su mensaje de error
                dbms_output.put_line('MAL: Lanza algun tipo de excepción, que no es la que buscamos');
                dbms_output.put_line('Error nro: '||SQLCODE);
                dbms_output.put_line('Mensaje: '||SQLERRM);
                
            end if;
  end;
  
  --CASO DE PRUEBA 3: Evento inexistente.
 declare
  mensajeError varchar(100);
  arg_nombre_evento varchar(100);
  begin
    dbms_output.put_line('CASO DE PRUEBAS 3: Evento inexistente--------------------');
    -- Inicializamos la base de datos para los tests en la base de datos.
    inicializa_test;
    -- Declaramos el evento que vamos a querer reservar que no existe
    arg_nombre_evento:='Monologo chiquito de la calzada';
    -- Guardamos el mensaje de error que esperamos de la excepción
    mensajeError:='ORA-20003: El evento ' || arg_nombre_evento || ' no existe';
    -- Intentamos hacer la reserva de el evento que no existe
    reservar_evento('12345678A',arg_nombre_evento,date '2024-6-27');
    -- En caso de que no salte la excepción nos saldra por pantalla que ha fallado
    dbms_output.put_line('MAL: No se ha lanzado ninguna excepción');
    --  Cazamos la excepción que salte
    exception
        when others then
            if (SQLCODE=-20003) then --En caso de que salte la excepción que queremos la -2003 
                dbms_output.put_line('BIEN,Lanza la excepción -20003 cuando se intenta reservar un evento no existente'); --Imprimimos que esta correcto
                if(SQLERRM=mensajeError) then --Comprobamos que lanza el mensaje tambien correcto
                    dbms_output.put_line('BIEN,Manda el mensaje de error correcto: '|| SQLERRM); -- Imprimimos que el mensaje esta correcto
                else --En caso de que el mensaje no este correcto
                    dbms_output.put_line('MAL,Lanza la excepción -20003 pero no el mensaje de error correcto'); --Imprimimos que esta incorrecto
                end if;
                
            else --En caso de que nos de cualquiera otra excepción la imprimieremos por pantalla junto con su mensaje de error
                dbms_output.put_line('MAL: Lanza algun tipo de excepción, que no es la que buscamos');
                dbms_output.put_line('Error nro: '||SQLCODE);
                dbms_output.put_line('Mensaje: '||SQLERRM);
                
            end if;  
        
        
  end;
  

  --CASO DE PRUEBA 4: Cliente inexistente. 
  begin
    -- Inicializamos la base de datos para los tests en la base de datos.
    inicializa_test;
    dbms_output.put_line('CASO DE PRUEBA 4: Cliente inexistente--------------------');
    -- Intentamos reservar un evento con un cliente que no existe
    reservar_evento('12345678B','concierto_la_moda',date '2024-6-27');
    -- En caso de que no salte la excepción nos saldra por pantalla que ha fallado
    dbms_output.put_line('MAL: No se ha lanzado ninguna excepción');
    --  Cazamos la excepción que salte
    exception
        when others then
            if (SQLCODE=-20002) then --En caso de que salte la excepción que queremos la -20002
                dbms_output.put_line('BIEN,Lanza la excepción -20002 cuando se intenta reservar un evento por un cliente que no existe'); --Imprimimos que esta correcto
                if(SQLERRM='ORA-20002: Cliente inexistente') then --Comprobamos que lanza el mensaje tambien correcto
                    dbms_output.put_line('BIEN,Manda el mensaje de error correcto: '|| SQLERRM); -- Imprimimos que el mensaje esta correcto
                else --En caso de que el mensaje no este correcto
                    dbms_output.put_line('MAL,Lanza la excepción -20002 pero no el mensaje de error correcto'); --Imprimimos que esta incorrecto
                end if;
                
            else --En caso de que nos de cualquiera otra excepción la imprimieremos por pantalla junto con su mensaje de error
                dbms_output.put_line('MAL: Lanza algun tipo de excepción, que no es la que buscamos');
                dbms_output.put_line('Error nro: '||SQLCODE);
                dbms_output.put_line('Mensaje: '||SQLERRM);
                
            end if;
  end;
  
  --caso 5 El cliente no tiene saldo suficiente
  begin
    -- Inicializamos la base de datos para los tests en la base de datos.
    inicializa_test;
    dbms_output.put_line('CASO DE PRUEBA 5: El cliente no tiene suficiente saldo---------------------');
    -- Intentamos hacer la reserva de el un evento sin tener el saldo suficiente
    reservar_evento('11111111B','teatro_impro',date '2024-7-1');
     -- En caso de que no salte la excepción nos saldra por pantalla que ha fallado
    dbms_output.put_line('MAL: No se ha lanzado ninguna excepción');
    --  Cazamos la excepción que salte
    exception
        when others then
            if (SQLCODE=-20004) then --En caso de que salte la excepción que queremos la -2004
                dbms_output.put_line('BIEN,Lanza la excepción -20004 cuando se intenta reservar un evento para el cual el cliente no tiene suficiente saldo'); --Imprimimos que esta correcto
                if(SQLERRM='ORA-20004: Saldo en abono insuficiente') then --Comprobamos que lanza el mensaje tambien correcto
                    dbms_output.put_line('BIEN,Manda el mensaje de error correcto: '|| SQLERRM); -- Imprimimos que el mensaje esta correcto
                else --En caso de que el mensaje no este correcto
                    dbms_output.put_line('MAL,Lanza la excepción -20004 pero no el mensaje de error correcto'); --Imprimimos que esta incorrecto
                end if;
                
            else --En caso de que nos de cualquiera otra excepción la imprimieremos por pantalla junto con su mensaje de error
                dbms_output.put_line('MAL: Lanza algun tipo de excepción, que no es la que buscamos');
                dbms_output.put_line('Error nro: '||SQLCODE);
                dbms_output.put_line('Mensaje: '||SQLERRM);
                
            end if;
  end;

  
end;
/


set serveroutput on;
exec test_reserva_evento;
