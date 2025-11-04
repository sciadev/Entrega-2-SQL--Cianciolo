-- Script de Inserción de Datos - UX Management
-- Proyecto: Base de Datos - Agentes de Gestión UX
-- Alumno: Santiago Ciolo
-- Fecha: 07/10/2025
-- Curso: SQL - Entrega 2

USE ux_management_v2;

-- ================================================
-- INSERCIÓN DE DATOS DE PRUEBA
-- ================================================

-- Insertar agentes (usando solo el campo nombre como en la estructura original)
INSERT INTO Agente (nombre) VALUES 
('Juan Pérez'),
('María González'),
('Carlos López'),
('Ana Martínez'),
('Pedro Rodríguez'),
('Lucía Silva'),
('Diego Torres'),
('Sofía Herrera');

-- Insertar volúmenes de tickets 
INSERT INTO Volumen (id_agente, cantidad_tickets) VALUES 
(1, 85),
(2, 92),
(3, 78),
(4, 105),
(5, 88),
(6, 95),
(7, 72),
(8, 89),
-- Segundo período (simulando diferentes fechas)
(1, 90),
(2, 87),
(3, 82),
(4, 98),
(5, 93),
(6, 91),
(7, 85),
(8, 94);

-- Insertar datos de cumplimiento SLA
INSERT INTO Cumplimiento_SLA (id_volumen, cumple_SLA, no_cumple_SLA) VALUES 
(1, 80, 5),
(2, 88, 4),
(3, 72, 6),
(4, 98, 7),
(5, 82, 6),
(6, 90, 5),
(7, 65, 7),
(8, 84, 5),
-- Segundo período
(9, 85, 5),
(10, 80, 7),
(11, 76, 6),
(12, 90, 8),
(13, 87, 6),
(14, 86, 5),
(15, 79, 6),
(16, 88, 6);

-- Insertar datos de favorabilidad (usando VARCHAR como en estructura original)
INSERT INTO Favorabilidad (id_volumen, nivel_favorabilidad) VALUES 
(1, 'Bueno'),
(2, 'Excelente'),
(3, 'Regular'),
(4, 'Excelente'),
(5, 'Bueno'),
(6, 'Bueno'),
(7, 'Regular'),
(8, 'Bueno'),
-- Segundo período  
(9, 'Bueno'),
(10, 'Bueno'),
(11, 'Regular'),
(12, 'Excelente'),
(13, 'Bueno'),
(14, 'Bueno'),
(15, 'Regular'),
(16, 'Bueno');

-- ================================================
-- VERIFICACIONES
-- ================================================

-- Verificar datos insertados
SELECT 'Verificación de datos insertados:' AS mensaje;

SELECT COUNT(*) AS total_agentes FROM Agente;
SELECT COUNT(*) AS total_volumenes FROM Volumen;
SELECT COUNT(*) AS total_SLA FROM Cumplimiento_SLA;
SELECT COUNT(*) AS total_favorabilidad FROM Favorabilidad;

-- Mostrar algunos registros de ejemplo
SELECT 'Datos de ejemplo:' AS mensaje;

SELECT a.nombre, v.cantidad_tickets, s.cumple_SLA, s.no_cumple_SLA, f.nivel_favorabilidad
FROM Agente a
JOIN Volumen v ON a.id_agente = v.id_agente
JOIN Cumplimiento_SLA s ON v.id_volumen = s.id_volumen
JOIN Favorabilidad f ON v.id_volumen = f.id_volumen
LIMIT 5;

-- Mensaje final
SELECT 'Datos insertados correctamente' AS resultado;
