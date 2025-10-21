const express = require("express");
const sql = require("mssql");
const path = require("path");

const dbconfig = {
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
  try {
    const { usuario, contrasena } = req.body;
    const ip = req.ip || req.connection.remoteAddress || "127.0.0.1";
    const pool = await sql.connect(dbconfig);

    // 🔐 Ejecutar SP_Login directamente (ya maneja bloqueo e intentos)
    const request = pool.request();
    request.input("inUsuario", sql.NVarChar(50), usuario);
    request.input("inPassword", sql.NVarChar(64), contrasena);
    request.input("inPostInIP", sql.VarChar(50), ip);
    request.output("outCodigo", sql.Int);
    request.output("outMinutosRestantes", sql.Int);

    const result = await request.execute("sp_Login");
    const codigo = result.output.outCodigo;
    const minutos = result.output.outMinutosRestantes || 0;

    console.log("🧩 Resultado completo de sp_Login:", result);
    console.log("➡️ Código devuelto:", codigo);
    console.log("⏱️ Minutos restantes:", minutos);

    // 📦 Respuestas según código
    if (codigo === 0) {
      return res.json({ success: true });
    }

    if (codigo === 50001) {
      return res.json({ success: false, message: "Usuario no existe" });
    }

    if (codigo === 50002) {
      return res.json({ success: false, message: "Contraseña incorrecta" });
    }

    if (codigo === 50003) {
      // 🔒 Usuario bloqueado: mostramos tiempo exacto devuelto por SQL
      const minutosRestantes = Math.max(1, Math.min(10, minutos));
      return res.json({
        success: false,
        bloqueado: true,
        minutosRestantes,
        message: `Demasiados intentos. Intente de nuevo dentro de ${minutosRestantes} minuto${minutosRestantes > 1 ? "s" : ""}.`
      });
    }

    if (codigo === 50008) {
      return res.json({ success: false, message: "Error en la base de datos" });
    }

    return res.json({ success: false, message: "Error desconocido." });
  } catch (err) {
    console.error("❌ [ERROR /login]:", err);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});



// ======================== EMPLEADOS ========================

// Obtener todos los empleados
app.get("/empleados", async (req, res) => {
  try {
    let pool = await sql.connect(dbconfig);
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
        let pool = await sql.connect(dbconfig);
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
        console.error("Error en /empleados-modificar:");
        console.error(err.message);
        if (err.originalError?.info) {
          console.error("SQL Error:", err.originalError.info);
        }
        res.status(500).json({ success: false, message: "Error en el servidor (ver consola)" });
      }
});

// Obtener puestos
app.get("/puestos", async (req, res) => {
  try {
    let pool = await sql.connect(dbconfig);
    let request = pool.request();
    request.output("outValorRetorno", sql.Int);

    const result = await request.execute("sp_ObtenerPuestos");
    const retorno = result.output.outValorRetorno;

    if (retorno === 0) {
      res.json({ success: true, data: result.recordset });
    } else {
      res.json({ success: false, message: "Error al obtener puestos" });
    }
  } catch (err) {
    console.error("Error en /puestos:", err);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});

// Insertar empleado
app.post("/empleados-insertar", async (req, res) => {
  const { nombre, documento, idPuesto } = req.body;
  try {
    let pool = await sql.connect(dbconfig);
    let request = pool.request();
    request.input("Nombre", sql.NVarChar, nombre);
    request.input("Documento", sql.NVarChar, documento);
    request.input("IdPuesto", sql.Int, idPuesto);
    request.output("outCodigo", sql.Int);

    const result = await request.execute("sp_InsertarEmpleado");

    // 🔍 Log detallado
    console.log("📥 Resultado de sp_InsertarEmpleado:", result);
    console.log("📦 result.output:", result.output);
    console.log("📦 result.recordset:", result.recordset);

    const codigo = result.output.outCodigo;
    console.log("🔢 Código devuelto por SP:", codigo);

    if (codigo === 0) {
      res.json({ success: true });
    } else if (codigo === 50001) {
      res.json({ success: false, message: "Ya existe un empleado con ese nombre" });
    } else if (codigo === 50002) {
      res.json({ success: false, message: "Ya existe un empleado con ese documento de identidad" });
    } else {
      res.json({ success: false, message: "Error al insertar empleado" });
    }
  } catch (err) {
      console.error("❌ [ERROR /empleados-insertar] Excepción atrapada:");
      console.error("Mensaje:", err.message);

      if (err.originalError?.info) {
        console.error("📄 SQL Error Info:", err.originalError.info);
      }

      console.error("Stack:", err.stack);
      res.status(500).json({
        success: false,
        message: "Error en el servidor (ver consola para detalles)"
      });
    }
});

// Consultar un empleado
app.get("/empleados-consultar/:id", async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (Number.isNaN(id)) {
    return res.status(400).json({ success: false, message: "Id inválido" });
  }

  try {
    let pool = await sql.connect(dbconfig);
    let request = pool.request();
    request.input("IdEmpleado", sql.Int, id);
    request.output("outCodigo", sql.Int);

    const result = await request.execute("sp_ConsultarEmpleado");
    console.log("[/empleados-consultar] id=", id, "out=", result.output, "rows=", result.recordset?.length);

    const codigo = result.output.outCodigo;

    if (codigo === 0 && result.recordset.length > 0) {
      return res.json({ success: true, data: result.recordset[0] });
    }
    return res.json({ success: false, message: "Empleado no encontrado" });
  } catch (err) {
  console.error("Error en /empleados-consultar:", err);
    if (err?.originalError?.info) console.error("SQL info:", err.originalError.info);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});

// ======================== BORRAR EMPLEADO ========================
app.delete("/empleados-borrar/:id", async (req, res) => {
  const { id } = req.params;
  try {
    let pool = await sql.connect(dbconfig);
    let request = pool.request();
    request.input("IdEmpleado", sql.Int, id);
    request.output("outCodigo", sql.Int);

    const result = await request.execute("sp_BorrarEmpleado");
    const codigo = result.output.outCodigo;

    if (codigo === 0) {
      res.json({ success: true });
    } else if (codigo === 50001) {
      res.json({ success: false, message: "El empleado no existe" });
    } else if (codigo === 50002) {
      res.json({ success: false, message: "El empleado ya estaba inactivo" });
    } else {
      res.json({ success: false, message: "Error al borrar el empleado" });
    }
  } catch (err) {
    console.error("Error en /empleados-borrar:", err);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});

// ======================== MODIFICAR EMPLEADO ========================
app.post("/empleados-modificar", async (req, res) => {
  const { id, nuevoDoc, nuevoNombre, nuevoIdPuesto } = req.body;

  try {
    let pool = await sql.connect(dbconfig);
    let request = pool.request();
    request.input("IdEmpleado", sql.Int, id);
    request.input("NuevoDocumento", sql.NVarChar, nuevoDoc);
    request.input("NuevoNombre", sql.NVarChar, nuevoNombre);
    request.input("NuevoIdPuesto", sql.Int, nuevoIdPuesto);
    request.input("IdPostByUser", sql.Int, 1); // admin temporal
    request.input("PostInIP", sql.VarChar, "127.0.0.1");
    request.output("outCodigo", sql.Int);

    const result = await request.execute("sp_ModificarEmpleado");
    const codigo = result.output.outCodigo;

    if (codigo === 0) {
      res.json({ success: true });
    } else if (codigo === 50002) {
      res.json({ success: false, message: "Ya existe un empleado con ese documento de identidad" });
    } else if (codigo === 50003) {
      res.json({ success: false, message: "Ya existe un empleado con ese nombre" });
    } else {
      res.json({ success: false, message: "Error al modificar empleado" });
    }
  } catch (err) {
    console.error("Error en /empleados-modificar:", err);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});

// ======================== LISTAR MOVIMIENTOS ========================
app.get("/movimientos/:idEmpleado", async (req, res) => {
  const { idEmpleado } = req.params;

  try {
    let pool = await sql.connect(dbconfig);
    let request = pool.request();

    request.input("IdEmpleado", sql.Int, idEmpleado);
    request.output("outCodigo", sql.Int);

    const result = await request.execute("sp_ListarMovimientos");
    const codigo = result.output.outCodigo;

    if (codigo === 0) {
      res.json({ success: true, data: result.recordset });
    } else if (codigo === 50021) {
      res.json({ success: false, message: "El empleado no existe o está inactivo" });
    } else {
      res.json({ success: false, message: "Error al listar movimientos" });
    }
  } catch (err) {
    console.error("Error en /movimientos/:idEmpleado:", err);
    if (err?.originalError?.info)
      console.error("SQL info:", err.originalError.info);

    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});

// ======================== OBTENER TIPOS DE MOVIMIENTO ========================
app.get("/tipos-movimiento", async (req, res) => {
  try {
    let pool = await sql.connect(dbconfig);
    let request = pool.request();
    request.output("outCodigo", sql.Int);

    const result = await request.execute("sp_ObtenerTiposMovimiento");

    if (result.recordset && result.recordset.length > 0) {
      res.json({ success: true, data: result.recordset });
    } else {
      res.json({ success: false, message: "No se encontraron tipos de movimiento" });
    }
  } catch (err) {
    console.error("Error en /tipos-movimiento:", err);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});


// ======================== INSERTAR MOVIMIENTO ========================
app.post("/movimientos-insertar", async (req, res) => {
  const { idEmpleado, idTipoMovimiento, monto, idUsuario, ip } = req.body;
  try {
    let pool = await sql.connect(dbconfig);
    let request = pool.request();

    request.input("IdEmpleado", sql.Int, idEmpleado);
    request.input("IdTipoMovimiento", sql.Int, idTipoMovimiento);
    request.input("Monto", sql.Float, monto);
    request.input("IdPostByUser", sql.Int, idUsuario || 1);
    request.input("PostInIP", sql.VarChar, ip || "127.0.0.1");
    request.output("outCodigo", sql.Int);

    const result = await request.execute("sp_InsertarMovimiento");
    const codigo = result.output.outCodigo;

    if (codigo === 0)
      res.json({ success: true });
    else if (codigo === 50031)
      res.json({ success: false, message: "El empleado no existe o está inactivo." });
    else if (codigo === 50032)
      res.json({ success: false, message: "Tipo de movimiento inválido." });
    else if (codigo === 50033)
      res.json({ success: false, message: "El monto haría negativo el saldo." });
    else
      res.json({ success: false, message: "Error inesperado al insertar movimiento." });
  } catch (err) {
    console.error("Error en /movimientos-insertar:", err);
    res.status(500).json({ success: false, message: "Error en el servidor" });
  }
});

// ======================== SERVIDOR ========================
app.listen(port, () => {
    console.log(`Servidor corriendo en http://localhost:${port}`);
});