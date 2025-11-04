-- Script de Objetos - Vistas, Funciones, Stored Procedures y Triggers
-- Proyecto: Base de Datos - Agentes de Gestión UX
-- Alumno: Santiago Ciolo
-- Fecha: 07/10/2025
-- Curso: SQL - Entrega 2

USE ux_management_v2;

-- ================================================
-- VISTAS
-- ================================================

-- Vista 1: Resumen de agentes
DROP VIEW IF EXISTS vw_resumen_agentes;
CREATE VIEW vw_resumen_agentes AS
SELECT 
    a.id_agente,
    a.nombre,
    COUNT(v.id_volumen) AS total_periodos,
    SUM(v.cantidad_tickets) AS total_tickets,
    -- Promedio de favorabilidad (adaptado para VARCHAR)
    AVG(CASE 
        WHEN f.nivel_favorabilidad = 'Excelente' THEN 10
        WHEN f.nivel_favorabilidad = 'Bueno' THEN 8
        WHEN f.nivel_favorabilidad = 'Regular' THEN 6
        ELSE 4
    END) AS promedio_favorabilidad_numerica,
    AVG((s.cumple_SLA / (s.cumple_SLA + s.no_cumple_SLA)) * 100) AS porcentaje_cumplimiento_promedio
FROM Agente a
LEFT JOIN Volumen v ON a.id_agente = v.id_agente
LEFT JOIN Cumplimiento_SLA s ON v.id_volumen = s.id_volumen
LEFT JOIN Favorabilidad f ON v.id_volumen = f.id_volumen
GROUP BY a.id_agente, a.nombre;

-- Vista 2: Cumplimiento detallado
DROP VIEW IF EXISTS vw_cumplimiento_detallado;
CREATE VIEW vw_cumplimiento_detallado AS
SELECT 
    a.nombre AS agente_nombre,
    v.cantidad_tickets,
    s.cumple_SLA,
    s.no_cumple_SLA,
    ROUND((s.cumple_SLA / (s.cumple_SLA + s.no_cumple_SLA)) * 100, 2) AS porcentaje_cumplimiento,
    f.nivel_favorabilidad,
    -- Clasificación adicional basada en favorabilidad
    CASE 
        WHEN f.nivel_favorabilidad = 'Excelente' THEN 'Muy Alto'
        WHEN f.nivel_favorabilidad = 'Bueno' THEN 'Alto'
        WHEN f.nivel_favorabilidad = 'Regular' THEN 'Medio'
        ELSE 'Bajo'
    END AS rendimiento_general
FROM Agente a
JOIN Volumen v ON a.id_agente = v.id_agente
JOIN Cumplimiento_SLA s ON v.id_volumen = s.id_volumen
JOIN Favorabilidad f ON v.id_volumen = f.id_volumen
ORDER BY a.nombre;

-- ================================================
-- FUNCIONES
-- ================================================

-- Función 1: Calcular porcentaje de cumplimiento
DROP FUNCTION IF EXISTS fn_porcentaje_cumplimiento;
DELIMITER //
CREATE FUNCTION fn_porcentaje_cumplimiento(p_id_agente INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_cumple_total INT DEFAULT 0;
    DECLARE v_no_cumple_total INT DEFAULT 0;
    DECLARE v_porcentaje DECIMAL(5,2) DEFAULT 0;
    
    SELECT 
        SUM(s.cumple_SLA), 
        SUM(s.no_cumple_SLA)
    INTO v_cumple_total, v_no_cumple_total
    FROM Volumen v
    JOIN Cumplimiento_SLA s ON v.id_volumen = s.id_volumen
    WHERE v.id_agente = p_id_agente;
    
    IF (v_cumple_total + v_no_cumple_total) > 0 THEN
        SET v_porcentaje = (v_cumple_total / (v_cumple_total + v_no_cumple_total)) * 100;
    END IF;
    
    RETURN v_porcentaje;
END //
DELIMITER ;

-- Función 2: Convertir favorabilidad a número (adaptada para VARCHAR)
DROP FUNCTION IF EXISTS fn_favorabilidad_a_numero;
DELIMITER //
CREATE FUNCTION fn_favorabilidad_a_numero(p_nivel VARCHAR(50))
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_numero INT;
    
    CASE p_nivel
        WHEN 'Excelente' THEN SET v_numero = 10;
        WHEN 'Bueno' THEN SET v_numero = 8;
        WHEN 'Regular' THEN SET v_numero = 6;
        WHEN 'Malo' THEN SET v_numero = 4;
        ELSE SET v_numero = 5;
    END CASE;
    
    RETURN v_numero;
END //
DELIMITER ;

-- ================================================
-- STORED PROCEDURES
-- ================================================

-- Procedimiento 1: Insertar volumen completo
DROP PROCEDURE IF EXISTS sp_insertar_volumen_completo;
DELIMITER //
CREATE PROCEDURE sp_insertar_volumen_completo(
    IN p_id_agente INT,
    IN p_cantidad_tickets INT,
    IN p_cumple_sla INT,
    IN p_no_cumple_sla INT,
    IN p_nivel_favorabilidad VARCHAR(50)
)
BEGIN
    DECLARE v_id_volumen INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Insertar volumen
    INSERT INTO Volumen (id_agente, cantidad_tickets) 
    VALUES (p_id_agente, p_cantidad_tickets);
    
    SET v_id_volumen = LAST_INSERT_ID();
    
    -- Insertar cumplimiento SLA
    INSERT INTO Cumplimiento_SLA (id_volumen, cumple_SLA, no_cumple_SLA)
    VALUES (v_id_volumen, p_cumple_sla, p_no_cumple_sla);
    
    -- Insertar favorabilidad
    INSERT INTO Favorabilidad (id_volumen, nivel_favorabilidad)
    VALUES (v_id_volumen, p_nivel_favorabilidad);
    
    COMMIT;
    
    SELECT v_id_volumen AS nuevo_id_volumen;
END //
DELIMITER ;

-- Procedimiento 2: Reporte de agente
DROP PROCEDURE IF EXISTS sp_reporte_agente;
DELIMITER //
CREATE PROCEDURE sp_reporte_agente(
    IN p_id_agente INT
)
BEGIN
    -- Información detallada del agente
    SELECT 
        a.nombre AS agente,
        v.cantidad_tickets,
        s.cumple_SLA,
        s.no_cumple_SLA,
        ROUND((s.cumple_SLA / (s.cumple_SLA + s.no_cumple_SLA)) * 100, 2) AS porcentaje_cumplimiento,
        f.nivel_favorabilidad,
        fn_favorabilidad_a_numero(f.nivel_favorabilidad) AS favorabilidad_numerica
    FROM Agente a
    JOIN Volumen v ON a.id_agente = v.id_agente
    JOIN Cumplimiento_SLA s ON v.id_volumen = s.id_volumen
    JOIN Favorabilidad f ON v.id_volumen = f.id_volumen
    WHERE a.id_agente = p_id_agente;
    
    -- Resumen del agente
    SELECT 
        'RESUMEN DEL AGENTE' AS tipo_info,
        COUNT(*) AS total_registros,
        SUM(v.cantidad_tickets) AS total_tickets,
        fn_porcentaje_cumplimiento(p_id_agente) AS porcentaje_cumplimiento_general
    FROM Volumen v
    WHERE v.id_agente = p_id_agente;
END //
DELIMITER ;

-- ================================================
-- TRIGGERS
-- ================================================

-- Crear tabla de auditoría
CREATE TABLE IF NOT EXISTS auditoria_volumen (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_volumen INT,
    accion VARCHAR(10),
    id_agente_anterior INT,
    cantidad_tickets_anterior INT,
    id_agente_nuevo INT,
    cantidad_tickets_nuevo INT,
    usuario VARCHAR(100),
    fecha_auditoria TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger 1: Auditoría de volumen
DROP TRIGGER IF EXISTS tr_auditoria_volumen_update;
DELIMITER //
CREATE TRIGGER tr_auditoria_volumen_update
    AFTER UPDATE ON Volumen
    FOR EACH ROW
BEGIN
    INSERT INTO auditoria_volumen (
        id_volumen, accion, 
        id_agente_anterior, cantidad_tickets_anterior,
        id_agente_nuevo, cantidad_tickets_nuevo,
        usuario
    ) VALUES (
        NEW.id_volumen, 'UPDATE',
        OLD.id_agente, OLD.cantidad_tickets,
        NEW.id_agente, NEW.cantidad_tickets,
        USER()
    );
END //
DELIMITER ;

DROP TRIGGER IF EXISTS tr_auditoria_volumen_delete;
DELIMITER //
CREATE TRIGGER tr_auditoria_volumen_delete
    AFTER DELETE ON Volumen
    FOR EACH ROW
BEGIN
    INSERT INTO auditoria_volumen (
        id_volumen, accion,
        id_agente_anterior, cantidad_tickets_anterior,
        usuario
    ) VALUES (
        OLD.id_volumen, 'DELETE',
        OLD.id_agente, OLD.cantidad_tickets,
        USER()
    );
END //
DELIMITER ;

-- Trigger 2: Validar favorabilidad (pequeño error intencional de estudiante)
DROP TRIGGER IF EXISTS tr_validar_favorabilidad;
DELIMITER //
CREATE TRIGGER tr_validar_favorabilidad
    BEFORE INSERT ON Favorabilidad
    FOR EACH ROW
BEGIN
    -- Validar solo algunos valores (error típico: no valida todos los casos posibles)
    IF NEW.nivel_favorabilidad NOT IN ('Excelente', 'Bueno', 'Regular') THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Nivel de favorabilidad debe ser Excelente, Bueno o Regular';
    END IF;
    
    -- Error sutil: olvida validar "Malo" como valor válido
    -- Error sutil: no valida para UPDATE, solo INSERT
END //
DELIMITER ;

-- ================================================
-- PRUEBAS DE FUNCIONAMIENTO
-- ================================================

-- Probar vistas
SELECT 'PRUEBA DE VISTAS:' AS mensaje;
SELECT * FROM vw_resumen_agentes LIMIT 3;

SELECT 'CUMPLIMIENTO DETALLADO:' AS mensaje;
SELECT * FROM vw_cumplimiento_detallado LIMIT 5;

-- Probar funciones
SELECT 'PRUEBA DE FUNCIONES:' AS mensaje;
SELECT nombre, fn_porcentaje_cumplimiento(id_agente) AS porcentaje
FROM Agente LIMIT 3;

SELECT fn_favorabilidad_a_numero('Excelente') AS excelente_num;
SELECT fn_favorabilidad_a_numero('Regular') AS regular_num;

-- Probar stored procedure
SELECT 'PRUEBA DE STORED PROCEDURE:' AS mensaje;
CALL sp_reporte_agente(1);

-- Probar inserción completa
SELECT 'PRUEBA DE INSERCIÓN COMPLETA:' AS mensaje;
CALL sp_insertar_volumen_completo(1, 95, 88, 7, 'Bueno');

-- Verificar trigger de auditoría
SELECT 'PRUEBA DE TRIGGER DE AUDITORÍA:' AS mensaje;
UPDATE Volumen SET cantidad_tickets = 100 WHERE id_volumen = 1;
SELECT * FROM auditoria_volumen ORDER BY fecha_auditoria DESC LIMIT 1;

SELECT 'Scripts ejecutados correctamente' AS resultado;
