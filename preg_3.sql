CREATE OR REPLACE PROCEDURE GenerarReportePolizas(
    value_out OUT SYS_REFCURSOR,
    p_moneda_poliza in VARCHAR DEFAULT NULL,
    p_duracion_poliza in VARCHAR DEFAULT NULL,
    p_nombre_cliente in VARCHAR DEFAULT NULL,
    p_sexo_cliente in CHAR DEFAULT NULL,
    p_nombre_seguro in VARCHAR DEFAULT NULL,
    p_estado_poliza in VARCHAR DEFAULT NULL
)
AS
    v_sql_query VARCHAR2(4000);
BEGIN
    v_sql_query := 'SELECT pol.ID_Poliza AS POLIZA,
                          c.Nombre_Cliente AS CLIENTE,
                          c.Sexo AS SEXO_CLIENTE,
                          pol.Fecha_Inicio AS FECHA_INICIO_POLIZA,
                          pol.Fecha_Vencimiento AS FECHA_FIN_POLIZA,
                          pol.Estado_Poliza AS ESTADO_POLIZA,
                          cob.Nombre_Cobertura AS NOMBRE_COBERTURA,
                          s.Nombre_Seguro AS NOMBRE_SEGURO,
                          s.Moneda AS MONEDA_POLIZA,
                          s.Duracion AS DURACION_POLIZA,
                          s.Precio AS MONTO_POLIZA,
                          COUNT(p.ID_Pago) AS CANTIDAD_TOTAL_PAGOS,
                          SUM(pd.Monto_Pago_Detalle) AS MONTO_TOTAL_PAGOS
                    FROM Polizas pol
                    INNER JOIN Clientes c ON pol.ID_Cliente = c.ID_Cliente
                    INNER JOIN Seguros s ON pol.ID_Seguro = s.ID_Seguro
                    INNER JOIN Coberturas cob ON s.ID_Cobertura = cob.ID_Cobertura
                    LEFT JOIN Pagos p ON pol.ID_Poliza = p.ID_Poliza
                    LEFT JOIN DetallePagos pd ON p.ID_Pago = pd.ID_Pago';

    -- Filtro Moneda del seguro
    IF p_moneda_poliza IS NOT NULL THEN
        v_sql_query := v_sql_query || 'WHERE s.Moneda = ''' || p_moneda_poliza || ''' ';
    END IF;

    -- Filtro Duracion del seguro
    IF p_duracion_poliza IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND s.Duracion = ''' || p_duracion_poliza || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE s.Duracion = ''' || p_duracion_poliza || ''' ';
        END IF;
    END IF;

    -- Filtro Nombre cliente
    IF p_nombre_cliente IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL OR p_duracion_poliza IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND c.Nombre_Cliente = ''' || p_nombre_cliente || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE c.Nombre_Cliente = ''' || p_nombre_cliente || ''' ';
        END IF;
    END IF;

    -- Filtro Sexo Cliente
    IF p_sexo_cliente IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL OR p_duracion_poliza IS NOT NULL OR p_nombre_cliente IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND c.Sexo = ''' || p_sexo_cliente || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE c.Sexo = ''' || p_sexo_cliente || ''' ';
        END IF;
    END IF;

    -- Filtro Nombre del Seguro
    IF p_nombre_seguro IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL OR p_duracion_poliza IS NOT NULL OR p_nombre_cliente IS NOT NULL OR p_sexo_cliente IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND s.Nombre_Seguro = ''' || p_nombre_seguro || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE s.Nombre_Seguro = ''' || p_nombre_seguro || ''' ';
        END IF;
    END IF;

    -- Filtro Estado Poliza
    IF p_estado_poliza IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL OR p_duracion_poliza IS NOT NULL OR p_nombre_cliente IS NOT NULL OR p_sexo_cliente IS NOT NULL OR p_nombre_seguro IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND pol.Estado_Poliza = ''' || p_estado_poliza || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE pol.Estado_Poliza = ''' || p_estado_poliza || ''' ';
        END IF;
    END IF;

    -- Agrupacion para los calculos
    v_sql_query := v_sql_query || 'GROUP BY pol.ID_Poliza, c.Nombre_Cliente, c.Sexo, pol.Fecha_Inicio, pol.Fecha_Vencimiento,
                                    pol.Estado_Poliza, cob.Nombre_Cobertura, s.Nombre_Seguro, s.Moneda, s.Duracion, s.Precio';

    -- Ejecutar consulta
	OPEN value_out
	FOR v_sql_query;
END GenerarReportePolizas;
/

/* TEST */

DECLARE
    RESULTADO_CURSOR SYS_REFCURSOR;
   	POLIZA NUMBER;
    CLIENTE VARCHAR2(100);
   	SEXO_CLIENTE CHAR(1);
    FECHA_INICIO_POLIZA DATE;
    FECHA_FIN_POLIZA DATE;
   	ESTADO_POLIZA VARCHAR(25);
    NOMBRE_COBERTURA VARCHAR2(100);
    NOMBRE_SEGURO VARCHAR2(100);
    MONEDA_POLIZA CHAR(3);
    DURACION_POLIZA VARCHAR(50);
    MONTO_POLIZA NUMBER;
    CANTIDAD_TOTAL_PAGOS NUMBER;
    MONTO_TOTAL_PAGOS NUMBER;
BEGIN
    GenerarReportePolizas(RESULTADO_CURSOR, 'USD');
   	dbms_output.put_line('POLIZA'  
	   	|| '|' || 'CLIENTE' 
	   	|| '|' || 'SEXO_CLIENTE' 
	   	|| '|' || 'FECHA_INICIO_POLIZA' 
	   	|| '|' || 'FECHA_FIN_POLIZA' 
	   	|| '|' || 'ESTADO_POLIZA'
	   	|| '|' || 'NOMBRE_COBERTURA'
	   	|| '|' || 'NOMBRE_SEGURO'
	   	|| '|' || 'MONEDA_POLIZA'
	   	|| '|' || 'DURACION_POLIZA'
	   	|| '|' || 'MONTO_POLIZA'
	   	|| '|' || 'CANTIDAD_TOTAL_PAGOS'
	   	|| '|' || 'MONTO_TOTAL_PAGOS');
    LOOP
        FETCH RESULTADO_CURSOR 
        INTO
          POLIZA,
          CLIENTE,
          SEXO_CLIENTE,
          FECHA_INICIO_POLIZA,
          FECHA_FIN_POLIZA,
          ESTADO_POLIZA,
          NOMBRE_COBERTURA,
          NOMBRE_SEGURO,
          MONEDA_POLIZA,
          DURACION_POLIZA,
          MONTO_POLIZA,
          CANTIDAD_TOTAL_PAGOS,
          MONTO_TOTAL_PAGOS;
        EXIT WHEN resultado_cursor%NOTFOUND;
        dbms_output.put_line(POLIZA 
        || '|' || CLIENTE 
        || '|' || SEXO_CLIENTE 
        || '|' || FECHA_INICIO_POLIZA 
        || '|' || FECHA_FIN_POLIZA 
        || '|' || ESTADO_POLIZA
        || '|' || NOMBRE_COBERTURA 
        || '|' || NOMBRE_SEGURO
        || '|' || MONEDA_POLIZA 
        || '|' || DURACION_POLIZA 
        || '|' || MONTO_POLIZA 
        || '|' || CANTIDAD_TOTAL_PAGOS 
        || '|' || MONTO_TOTAL_PAGOS);
    END LOOP;
    CLOSE RESULTADO_CURSOR;
END;
/