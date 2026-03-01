-- Oracle DB Explorer — nvim-dbee (SOLO LECTURA)
-- Backend Go nativo, no depende de sqlplus/sqlcl
-- <leader>D toggle | Soporta Oracle, PostgreSQL, MySQL, SQLite
-- SEGURIDAD: conexiones usan usuario con grants SELECT solamente

return {
  {
    "kndndrj/nvim-dbee",
    dependencies = { "MunifTanjim/nui.nvim" },
    build = function()
      require("dbee").install()
    end,
    cmd = { "Dbee" },
    keys = {
      { "<leader>D", function() require("dbee").toggle() end, desc = "Toggle DB Explorer" },
    },
    config = function()
      -- Crear directorio si no existe
      local dbee_dir = vim.fn.stdpath("data") .. "/dbee"
      if vim.fn.isdirectory(dbee_dir) == 0 then
        vim.fn.mkdir(dbee_dir, "p")
      end

      -- Crear archivo de conexiones template si no existe
      local conn_file = dbee_dir .. "/connections.json"
      if vim.fn.filereadable(conn_file) == 0 then
        local template = vim.json.encode({
          {
            id = "oracle-readonly",
            name = "Oracle (READ-ONLY)",
            type = "oracle",
            url = "oracle://readonly_user:password@host:1521/service_name",
          },
        })
        local f = io.open(conn_file, "w")
        if f then
          f:write(template)
          f:close()
        end
      end

      -- Setup con sources dentro de config (dbee ya está cargado aquí)
      require("dbee").setup({
        sources = {
          require("dbee.sources").FileSource:new(conn_file),
        },
      })
    end,
  },
}
