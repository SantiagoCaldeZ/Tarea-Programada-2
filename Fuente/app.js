const express = require("express");
const sql = require("mssql");
const path = require("path");

const dbConfig = {
    user: "bdsc@francobd12025",
    password: "Franco2025",
    server: "francobd12025.database.windows.net",
    database: "bdtp2",
    options: {
        encrypt: true,
        trustServerCertificate: false
    }
};

const app = express();
const port = 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// ======================== EMPLEADOS ========================

app.get("/empleados", async (req, res) => {
    try {
        let pool = await sql.connect(dbConfig);
        let result = await pool.request()
            .execute("sp_ObtenerEmpleados");
        res.json(result.recordset);
    } catch (err) {
        console.error("Error en /empleados:", err);
        res.status(500).send("Error al consultar la base de datos");
    }
});

app.post('/insertar-empleado', async (req, res) => {
    try {
        const { nombre, salario } = req.body;
        let pool = await sql.connect(dbConfig);
        let request = pool.request();
        request.input('Nombre', sql.NVarChar, nombre);
        request.input('Salario', sql.Money, salario);

        const result = await request.execute('sp_InsertarEmpleado');
        const retorno = result.returnValue;

        if (retorno === 50001) {
            res.status(409).json({ success: false, message: 'El nombre de empleado ya existe.' });
        } else if (retorno === 0) {
            res.status(200).json({ success: true, message: 'Empleado insertado con éxito.' });
        } else {
            res.status(500).json({ success: false, message: 'Error desconocido del servidor.' });
        }
    } catch (err) {
        console.error("Error en /insertar-empleado:", err);
        res.status(500).json({ success: false, message: "Error al conectar o ejecutar la operación en la base de datos." });
    }
});

// ======================== LOGIN ========================

app.post("/login", async (req, res) => {
  const { usuario, contrasena } = req.body;
  try {
    let pool = await sql.connect(dbConfig);
    let request = pool.request();
    request.input("Usuario", sql.NVarChar, usuario);
    request.input("Contrasena", sql.NVarChar, contrasena);

    const result = await request.execute("sp_LoginUsuario"); // 👈 tu SP de login

    const retorno = result.returnValue;

    if (retorno === 0) {
      res.json({ success: true });
    } else {
      res.json({ success: false, message: "Credenciales inválidas" });
    }
  } catch (err) {
    console.error("Error en /login:", err);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});

// ======================== SERVIDOR ========================

app.listen(port, () => {
    console.log(`Servidor corriendo en http://localhost:${port}`);
});
