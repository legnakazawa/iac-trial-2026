const http = require("http");

const port = Number(process.env.PORT) || 8080;

const server = http.createServer((req, res) => {
  const body = [
    "IaC Workshop - Node sample",
    `owner: ${process.env.OWNER ?? "(not set)"}`,
    `storage: ${process.env.STORAGE_ACCOUNT_NAME ?? "(not set)"}`,
    `path: ${req.url}`,
  ].join("\n");

  res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
  res.end(body);
});

server.listen(port, () => {
  console.log(`Listening on port ${port}`);
});
