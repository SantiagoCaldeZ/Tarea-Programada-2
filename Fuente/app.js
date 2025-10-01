const express = require("express");
const sql = require("mssql");
const path = require("path");

const dbConfig = {
    user: "bdsc@francobd12025",
    password: "Franco2025",
    server: "francobd12025.database.windows.net",
    database: "bdtp2",   // 👈 ahora es bdtp2
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

    // Entradas
    request.input("inUsuario", sql.NVarChar(64), usuario);
    request.input("inPassword", sql.NVarChar(64), contrasena);

    // Salida
    request.output("outCodigo", sql.Int);

    const result = await request.execute("sp_Login");

    const retorno = result.output.outCodigo;

    if (retorno === 0) {
      res.json({ success: true });
    } else if (retorno === 50001) {
      res.json({ success: false, message: "Usuario no existe" });
    } else if (retorno === 50002) {
      res.json({ success: false, message: "Contraseña incorrecta" });
    } else {
      res.json({ success: false, message: "Error en el login" });
    }
  } catch (err) {
    console.error("❌ Error en /login:", err);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});

// ======================== SERVIDOR ========================

app.listen(port, () => {
    console.log(`Servidor corriendo en http://localhost:${port}`);
});
