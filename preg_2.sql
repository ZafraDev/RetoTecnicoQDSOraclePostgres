CREATE OR REPLACE PROCEDURE ActualizarEstadoPolizas 
AS
  fecha_actual DATE := CURRENT_DATE;
BEGIN
    -- Actualiza las polizas a estado Finalizdas
    UPDATE Polizas
    SET Estado_Poliza = 'Finalizada'
    WHERE Fecha_Vencimiento < fecha_actual;

    -- Actualiza las polizas a estado Desactivada por Impago
    UPDATE Polizas
    SET Estado_Poliza = 'Desactivada por Impago'
    WHERE ID_Poliza NOT IN (
        SELECT DISTINCT ID_Poliza
        FROM Pagos
        WHERE (
            EXTRACT(
              YEAR
              FROM Fecha_Pago
            ) = EXTRACT(
              YEAR
              FROM fecha_actual
            )
            AND EXTRACT(
              MONTH
              FROM Fecha_Pago
            ) = EXTRACT(
              MONTH
              FROM fecha_actual
            )
          )
          OR Estado_Poliza = 'Finalizada'
      );
END;
/
/* TEST */
BEGIN
    ActualizarEstadoPolizas();
END;
/