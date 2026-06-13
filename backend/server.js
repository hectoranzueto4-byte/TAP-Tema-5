const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Conexión a PostgreSQL
const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'clinica_agenda',
    password: '1234',
    port: 5432,
});

// Endpoint para obtener citas de un paciente
app.get('/citas/:pacienteId', async (req, res) => {
    try {
        const { pacienteId } = req.params;
        const resultado = await pool.query(
            'SELECT c.id, u.nombre AS medico, c.fecha_hora, c.estado FROM citas c JOIN usuarios u ON c.medico_id = u.id WHERE c.paciente_id = $1', 
            [pacienteId]
        );
        
        // Si no hay citas, devolvemos un arreglo vacío con estado 200 en lugar de fallar
        res.json(resultado.rows); 
    } catch (err) {
        console.error("❌ Error en la consulta SQL:", err.message); // Esto te dirá el error real en tu consola
        res.status(500).json({ error: err.message });
    }
});
// Obtener todos los usuarios que son médicos
app.get('/medicos', async (req, res) => {
    try {
        const resultado = await pool.query("SELECT id, nombre FROM usuarios WHERE rol = 'medico'");
        res.json(resultado.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Endpoint para agendar una nueva cita
app.post('/citas', async (req, res) => {
    const { paciente_id, medico_id, fecha_hora, motivo } = req.body;
    try {
        const nuevaCita = await pool.query(
            'INSERT INTO citas (paciente_id, medico_id, fecha_hora, motivo) VALUES ($1, $2, $3, $4) RETURNING *',
            [paciente_id, medico_id, fecha_hora, motivo]
        );
        res.json(nuevaCita.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.listen(3000, () => console.log('Servidor corriendo en el puerto 3000'));
// 1. EDITAR/ACTUALIZAR una cita existente (Cambiar fecha o estado)
app.put('/citas/:id', async (req, res) => {
    const { id } = req.params;
    const { fecha_hora, estado, motivo } = req.body;
    try {
        const citaActualizada = await pool.query(
            'UPDATE citas SET fecha_hora = $1, estado = $2, motivo = $3 WHERE id = $4 RETURNING *',
            [fecha_hora, estado, motivo, id]
        );
        
        if (citaActualizada.rows.length === 0) {
            return res.status(404).json({ error: "La cita no existe" });
        }
        res.json({ mensaje: "Cita actualizada con éxito", cita: citaActualizada.rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 2. BORRAR una cita de la base de datos
app.delete('/citas/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const resultado = await pool.query('DELETE FROM citas WHERE id = $1 RETURNING *', [id]);
        
        if (resultado.rows.length === 0) {
            return res.status(404).json({ error: "La cita no existe" });
        }
        res.json({ mensaje: "Cita eliminada correctamente" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

