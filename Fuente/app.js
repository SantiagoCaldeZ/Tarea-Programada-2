const express = require("express");
const sql = require("mssql");
const path = require("path");

const dbConfig = {
    user: "bdsc",
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

// ======================== LOGIN ========================
app.post("/login", async (req, res) => {
    const { usuario, contrasena } = req.body;
    try {
        let pool = await sql.connect(dbConfig);
        let request = pool.request();
        request.input("inUsuario", sql.NVarChar, usuario);
        request.input("inPassword", sql.NVarChar, contrasena);
        request.output("outCodigo", sql.Int);

        const result = await request.execute("sp_Login");
        const retorno = result.output.outCodigo;

        if (retorno === 0) {
            res.json({ success: true });
        } else if (retorno === 50001) {
            res.json({ success: false, message: "Usuario no existe" });
        } else if (retorno === 50002) {
            res.json({ success: false, message: "Contraseña incorrecta" });
        } else if (retorno === 50003) {
            res.json({ success: false, message: "Cuenta bloqueada temporalmente" });
        } else {
            res.json({ success: false, message: "Error en el login" });
        }
    } catch (err) {
        console.error("Error en /login:", err);
        res.status(500).json({ success: false, message: "Error en el servidor" });
    }
});

// ======================== EMPLEADOS ========================

// Obtener todos los empleados
app.get("/empleados", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    let request = pool.request();

    request.output("outValorRetorno", sql.Int);
    const result = await request.execute("sp_ObtenerEmpleados");
    const retorno = result.output.outValorRetorno;

    if (retorno === 0) {
      res.json({ success: true, data: result.recordset }); // 👈 siempre objeto con success + data
    } else {
      res.json({ success: false, message: "Error al obtener empleados" });
    }
  } catch (err) {
    console.error("Error en /empleados:", err);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});

// Filtrar empleados
app.post("/empleados-filtrar", async (req, res) => {
    const { valor, tipo } = req.body;
    try {
        let pool = await sql.connect(dbConfig);
        let request = pool.request();
        request.input("Filtro", sql.NVarChar, valor);
        request.input("Tipo", sql.NVarChar, tipo);
        request.output("outValorRetorno", sql.Int);

        const result = await request.execute("sp_BuscarEmpleados");
        const retorno = result.output.outValorRetorno;

        if (retorno === 0) {
          res.json({ success: true, data: result.recordset });
        } else if (retorno === 50002) {
            res.json({ success: false, message: "Tipo de filtro inválido" });
        } else {
            res.json({ success: false, message: "Error inesperado al filtrar empleados" });
        }
    } catch (err) {
        console.error("Error en /empleados-filtrar:", err);
        res.status(500).send("Error en el servidor");
    }
});

// ======================== SERVIDOR ========================
app.listen(port, () => {
    console.log(`Servidor corriendo en http://localhost:${port}`);
});
