/* 1 */

CREATE OR REPLACE PROCEDURE ObtenerPagosPorFechas(
    fecha_inicio DATE,
    fecha_fin DATE
)
AS
BEGIN
    SELECT
        p.Fecha_Pago,
        p.Moneda,
        SUM(CASE WHEN s.Nombre_Seguro = 'Vida Total' THEN 1 ELSE 0 END) AS SEGURO_VIDA_TOTAL_CANTIDAD_PAGOS,
        SUM(CASE WHEN s.Nombre_Seguro = 'Vida Total' THEN pd.Monto_Pago_Detalle ELSE 0 END) AS SEGURO_VIDA_TOTAL_MONTO_PAGO,
        SUM(CASE WHEN s.Nombre_Seguro = 'Salud Básico' THEN 1 ELSE 0 END) AS SEGURO_SALUD_BASICO_CANTIDAD_PAGOS,
        SUM(CASE WHEN s.Nombre_Seguro = 'Salud Básico' THEN pd.Monto_Pago_Detalle ELSE 0 END) AS SEGUDO_SALUD_BASICO_MONTO_PAGO,
        SUM(CASE WHEN s.Nombre_Seguro = 'Auto Terceros' THEN 1 ELSE 0 END) AS SEGURO_AUTO_TERCEROS_CANTIDAD_PAGOS,
        SUM(CASE WHEN s.Nombre_Seguro = 'Auto Terceros' THEN pd.Monto_Pago_Detalle ELSE 0 END) AS SEGURO_AUTO_TERCEROS_MONTO_PAGO
    FROM
        Pagos p
    INNER JOIN Polizas pol ON p.ID_Poliza = pol.ID_Poliza
    INNER JOIN Seguros s ON pol.ID_Seguro = s.ID_Seguro
    LEFT JOIN Pagos_Detalle pd ON p.ID_Pago = pd.ID_Pago
    WHERE
        p.Fecha_Pago BETWEEN fecha_inicio AND fecha_fin
    GROUP BY
        p.Fecha_Pago,
        p.Moneda
    ORDER BY
        p.Fecha_Pago,
        p.Moneda;
END;


/* 2 */
CREATE OR REPLACE PROCEDURE ActualizarEstadoPolizas()
AS
    fecha_actual DATE := CURRENT_DATE;
BEGIN
    -- Actualizar pólizas sin registros de pagos en el mes actual a 'Desactivada por Impago'
    UPDATE Polizas
    SET Estado_Poliza = 'Desactivada por Impago'
    WHERE ID_Poliza NOT IN (
        SELECT DISTINCT ID_Poliza
        FROM Pagos
        WHERE EXTRACT(YEAR FROM Fecha_Pago) = EXTRACT(YEAR FROM fecha_actual)
        AND EXTRACT(MONTH FROM Fecha_Pago) = EXTRACT(MONTH FROM fecha_actual)
    );

    -- Actualizar pólizas con fecha de vencimiento menor a la fecha actual a 'Finalizada'
    UPDATE Polizas
    SET Estado_Poliza = 'Finalizada'
    WHERE Fecha_Vencimiento < fecha_actual
    AND Estado_Poliza <> 'Desactivada por Impago';
    
    -- Mensaje de confirmación
    RAISE NOTICE 'Estado de las pólizas actualizado exitosamente.';
    
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, muestra un mensaje de error
        RAISE EXCEPTION 'Error al actualizar el estado de las pólizas: %', SQLERRM;
END;

/* 3 */

CREATE OR REPLACE PROCEDURE GenerarReportePolizas(
    p_moneda_poliza VARCHAR DEFAULT NULL,
    p_duracion_poliza VARCHAR DEFAULT NULL,
    p_nombre_cliente VARCHAR DEFAULT NULL,
    p_sexo_cliente CHAR DEFAULT NULL,
    p_nombre_seguro VARCHAR DEFAULT NULL,
    p_estado_poliza VARCHAR DEFAULT NULL
)
AS
    v_sql_query VARCHAR;
BEGIN
    v_sql_query := 'SELECT pol.ID_Poliza AS POLIZA,
                          c.Nombre_Cliente AS CLIENTE,
                          c.Sexo AS SEXO_CLIENTE,
                          pol.Fecha_Inicio AS FECHA_INICIO_POLIZA,
                          pol.Fecha_Vencimiento AS FECHA_FIN_POLIZA,
                          pol.Estado_Poliza AS ESTADO_POLIZA,
                          cob.Nombre_Cobertura AS NOMBRE_COBERTURA,
                          s.Nombre_Seguro AS NOMBRE_SEGURO,
                          pol.Moneda AS MONEDA_POLIZA,
                          pol.Duracion AS DURACION_POLIZA,
                          pol.Precio AS MONTO_POLIZA,
                          COUNT(p.ID_Pago) AS CANTIDAD_TOTAL_PAGOS,
                          SUM(pd.Monto_Pago_Detalle) AS MONTO_TOTAL_PAGOS
                   FROM Polizas pol
                   INNER JOIN Clientes c ON pol.ID_Cliente = c.ID_Cliente
                   INNER JOIN Coberturas cob ON pol.ID_Cobertura = cob.ID_Cobertura
                   INNER JOIN Seguros s ON pol.ID_Seguro = s.ID_Seguro
                   LEFT JOIN Pagos p ON pol.ID_Poliza = p.ID_Poliza
                   LEFT JOIN Pagos_Detalle pd ON p.ID_Pago = pd.ID_Pago ';

    IF p_moneda_poliza IS NOT NULL THEN
        v_sql_query := v_sql_query || 'WHERE pol.Moneda = ''' || p_moneda_poliza || ''' ';
    END IF;

    IF p_duracion_poliza IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND pol.Duracion = ''' || p_duracion_poliza || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE pol.Duracion = ''' || p_duracion_poliza || ''' ';
        END IF;
    END IF;

    IF p_nombre_cliente IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL OR p_duracion_poliza IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND c.Nombre_Cliente = ''' || p_nombre_cliente || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE c.Nombre_Cliente = ''' || p_nombre_cliente || ''' ';
        END IF;
    END IF;

    IF p_sexo_cliente IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL OR p_duracion_poliza IS NOT NULL OR p_nombre_cliente IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND c.Sexo = ''' || p_sexo_cliente || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE c.Sexo = ''' || p_sexo_cliente || ''' ';
        END IF;
    END IF;

    IF p_nombre_seguro IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL OR p_duracion_poliza IS NOT NULL OR p_nombre_cliente IS NOT NULL OR p_sexo_cliente IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND s.Nombre_Seguro = ''' || p_nombre_seguro || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE s.Nombre_Seguro = ''' || p_nombre_seguro || ''' ';
        END IF;
    END IF;

    IF p_estado_poliza IS NOT NULL THEN
        IF p_moneda_poliza IS NOT NULL OR p_duracion_poliza IS NOT NULL OR p_nombre_cliente IS NOT NULL OR p_sexo_cliente IS NOT NULL OR p_nombre_seguro IS NOT NULL THEN
            v_sql_query := v_sql_query || 'AND pol.Estado_Poliza = ''' || p_estado_poliza || ''' ';
        ELSE
            v_sql_query := v_sql_query || 'WHERE pol.Estado_Poliza = ''' || p_estado_poliza || ''' ';
        END IF;
    END IF;

    v_sql_query := v_sql_query || 'GROUP BY pol.ID_Poliza, c.Nombre_Cliente, c.Sexo, pol.Fecha_Inicio, pol.Fecha_Vencimiento,
                                    pol.Estado_Poliza, cob.Nombre_Cobertura, s.Nombre_Seguro, pol.Moneda, pol.Duracion, pol.Precio';

    -- Ejecutar consulta
    EXECUTE v_sql_query;
END;
