const http = require("http");

const port = Number(process.env.PORT) || 8080;

const server = http.createServer((req, res) => {
  const body = [
    "IaC Workshop 3 - CI/CD sample",
    `owner: ${process.env.OWNER ?? "(not set)"}`,
    `storage: ${process.env.STORAGE_ACCOUNT_NAME ?? "(not set)"}`,
    `workshop_change: ${process.env.WORKSHOP_CHANGE ?? "(not applied)"}`,
    `path: ${req.url}`,
  ].join("\n");

  res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
  res.end(body);
});

server.listen(port, () => {
  console.log(`Listening on port ${port}`);
});
