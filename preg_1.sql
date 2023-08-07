CREATE OR REPLACE PROCEDURE ObtenerPagosPorFechas(
    fecha_inicio in VARCHAR2,
    fecha_fin in VARCHAR2,
    value_out OUT SYS_REFCURSOR
  ) IS BEGIN OPEN value_out FOR 
  -- Obtener la cantidad de pagos
  WITH cantidad_pagos AS(
    SELECT p.Fecha_Pago,
      p.Moneda,
      SUM(
        CASE
          WHEN pol.ID_SEGURO = 1 THEN 1
          ELSE 0
        END
      ) AS SEGURO_VIDA_TOTAL_CANTIDAD_PAGOS,
      SUM(
        CASE
          WHEN pol.ID_SEGURO = 2 THEN 1
          ELSE 0
        END
      ) AS SEGURO_SALUD_BASICO_CANTIDAD_PAGOS,
      SUM(
        CASE
          WHEN pol.ID_SEGURO = 3 THEN 1
          ELSE 0
        END
      ) AS SEGURO_AUTO_TERCEROS_CANTIDAD_PAGOS
    FROM PAGOS P
      INNER JOIN Polizas pol ON p.ID_Poliza = pol.ID_Poliza
    WHERE p.Fecha_Pago BETWEEN to_date(fecha_inicio, 'yyyy/mm/dd') AND to_date(fecha_fin, 'yyyy/mm/dd')
    GROUP BY p.Fecha_Pago,
      p.Moneda
    ORDER BY p.Fecha_Pago,
      p.Moneda
  ),
  -- obtener el detalle monto de los pagos
  monto_pagos AS (
    SELECT p.Fecha_Pago,
      p.Moneda,
      SUM(
        CASE
          WHEN pol.ID_SEGURO = 1 THEN pd.Monto_Pago_Detalle
          ELSE 0
        END
      ) AS SEGURO_VIDA_TOTAL_MONTO_PAGO,
      SUM(
        CASE
          WHEN pol.ID_SEGURO = 2 THEN pd.Monto_Pago_Detalle
          ELSE 0
        END
      ) AS SEGUDO_SALUD_BASICO_MONTO_PAGO,
      SUM(
        CASE
          WHEN pol.ID_SEGURO = 3 THEN pd.Monto_Pago_Detalle
          ELSE 0
        END
      ) AS SEGURO_AUTO_TERCEROS_MONTO_PAGO
    FROM PAGOS P
      INNER JOIN Polizas pol ON p.ID_Poliza = pol.ID_Poliza
      LEFT JOIN DetallePagos pd ON p.ID_Pago = pd.ID_Pago
    WHERE p.Fecha_Pago BETWEEN to_date(fecha_inicio, 'yyyy/mm/dd') AND to_date(fecha_fin, 'yyyy/mm/dd')
    GROUP BY p.Fecha_Pago,
      p.Moneda
    ORDER BY p.Fecha_Pago,
      p.Moneda
  ),
  resultado AS (
    SELECT cp.Fecha_Pago,
      cp.Moneda,
      SEGURO_VIDA_TOTAL_CANTIDAD_PAGOS,
      SEGURO_VIDA_TOTAL_MONTO_PAGO,
      SEGURO_SALUD_BASICO_CANTIDAD_PAGOS,
      SEGUDO_SALUD_BASICO_MONTO_PAGO,
      SEGURO_AUTO_TERCEROS_CANTIDAD_PAGOS,
      SEGURO_AUTO_TERCEROS_MONTO_PAGO
    FROM cantidad_pagos cp
      LEFT JOIN monto_pagos mp ON cp.fecha_pago = mp.fecha_pago
      AND cp.moneda = mp.moneda
  )
SELECT *
FROM resultado;
END ObtenerPagosPorFechas;
/

/* TEST */
DECLARE RESULTADO_CURSOR SYS_REFCURSOR;
FECHA_PAGO DATE;
MONEDA CHAR(3);
SEGURO_VIDA_TOTAL_CANTIDAD_PAGOS NUMBER;
SEGURO_VIDA_TOTAL_MONTO_PAGO NUMBER;
SEGURO_SALUD_BASICO_CANTIDAD_PAGOS NUMBER;
SEGUDO_SALUD_BASICO_MONTO_PAGO NUMBER;
SEGURO_AUTO_TERCEROS_CANTIDAD_PAGOS NUMBER;
SEGURO_AUTO_TERCEROS_MONTO_PAGO NUMBER;
BEGIN ObtenerPagosPorFechas('2023-01-01', '2023-12-01', RESULTADO_CURSOR);
dbms_output.put_line(
  'FECHA_PAGO' || '|' || 'MONEDA' || '|' || 'SEGURO_VIDA_TOTAL_CANTIDAD_PAGOS' || '|' || 'SEGURO_VIDA_TOTAL_MONTO_PAGO' || '|' || 'SEGURO_SALUD_BASICO_CANTIDAD_PAGOS' || '|' || 'SEGUDO_SALUD_BASICO_MONTO_PAGO' || '|' || 'SEGURO_AUTO_TERCEROS_CANTIDAD_PAGOS' || '|' || 'SEGURO_AUTO_TERCEROS_MONTO_PAGO'
);
LOOP FETCH RESULTADO_CURSOR INTO FECHA_PAGO,
MONEDA,
SEGURO_VIDA_TOTAL_CANTIDAD_PAGOS,
SEGURO_VIDA_TOTAL_MONTO_PAGO,
SEGURO_SALUD_BASICO_CANTIDAD_PAGOS,
SEGUDO_SALUD_BASICO_MONTO_PAGO,
SEGURO_AUTO_TERCEROS_CANTIDAD_PAGOS,
SEGURO_AUTO_TERCEROS_MONTO_PAGO;
EXIT
WHEN resultado_cursor %NOTFOUND;
dbms_output.put_line(
  FECHA_PAGO || '|' || MONEDA || '|' || SEGURO_VIDA_TOTAL_CANTIDAD_PAGOS || '|' || SEGURO_VIDA_TOTAL_MONTO_PAGO || '|' || SEGURO_SALUD_BASICO_CANTIDAD_PAGOS || '|' || SEGUDO_SALUD_BASICO_MONTO_PAGO || '|' || SEGURO_AUTO_TERCEROS_CANTIDAD_PAGOS || '|' || SEGURO_AUTO_TERCEROS_MONTO_PAGO
);
END LOOP;
CLOSE RESULTADO_CURSOR;
END;
/