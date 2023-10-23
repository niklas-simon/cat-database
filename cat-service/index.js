const express = require('express');
const multer = require('multer');
const fs = require('fs');
const mysql = require('mysql2');

const app = express();

var connection = mysql.createConnection({
    host     : process.env.DB_HOST || '127.0.0.1',
    user     : process.env.DB_USER || 'root',
    password : process.env.DB_PASSWORD || 'root',
    database : process.env.DB_NAME || 'cats'
}).promise();

connection.query("create table if not exists cats (id int primary key auto_increment, name text, description text, image text)");

const head = title => `
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous" defer></script>
    <script>
        if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
            document.documentElement.dataset.bsTheme = "dark";
        }
    </script>
</head>
`

app.get("/", async (req, res) => {
    const results = (await connection.query("select * from cats"))[0];
    res.send(`
    <!DOCTYPE html>
    <html lang="en">
    ${head("Cat Database")}
    <body class="container">
        <h1>Cat Database</h1>
        ${results.length ? `<table class="table" style="vertical-align: middle;">
            <tr>
                <th>Name</th>
                <th>Description</th>
                <th>
                    <a href="/new" class="btn btn-outline-secondary">create</a>
                </th>
            </tr>
        ${results.map(cat => `
            <tr>
                <td>${cat.name}</td>
                <td>${cat.description}</td>
                <td>
                    <a href="/${cat.id}" class="btn btn-outline-primary">details</a>
                </td>
            </tr>
        `).join("")}
        </table>` : `This place is catless. Please <a href="/new" class="btn btn-outline-secondary">create a Cat</a>`}
    </body>
    </html>
    `);
})

const getCat = async id => (await connection.query(`select * from cats where id = ${connection.escape(id)}`))[0]?.[0];

const notFound = () => `
    <!DOCTYPE html>
    <html lang="en">
    ${head("404 Cat Not Found")}
    <body style="width: 100vw; height: 100vh; display: flex; align-items: center; justify-content: center;">
        <img src="http://http.cat/404"></img>
    </body>
    </html>
`

const upload = multer({dest: "images/"})
app.post("/", upload.single("image"), async (req, res) => {
    req.body.id = Number(req.body.id);
    const cat = req.body.id ? await getCat(req.body.id) : {name: "", description: "", image: null};
    if (!cat) {
        res.status(404).send(notFound());
        return;
    }
    if (req.body?.name) cat.name = req.body.name;
    if (req.body?.description) cat.description = req.body.description;
    if (req.file?.path) {
        if (cat.image) {
            try {
                fs.rmSync(`${__dirname}/${cat.image}`);
            } catch (e) {
                console.error(e);
            }
        }
        cat.image = req.file.path;
    }
    if (!cat.name) {
        res.status(401).redirect(`/${req.body.id ? req.body.id : 'new'}?error=${encodeURIComponent("Every Cat needs a name!")}&name=${encodeURIComponent(cat.name)}&description=${encodeURIComponent(cat.description)}`);
        return;
    }
    if (!cat.image) {
        res.status(401).redirect(`/${req.body.id ? req.body.id : 'new'}?error=${encodeURIComponent("We'd really like to see your cat. Please provide an image.")}&name=${encodeURIComponent(cat.name)}&description=${encodeURIComponent(cat.description)}`);
        return;
    }
    if (req.body.id) {
        await connection.query(`update cats set name = ${connection.escape(cat.name)}, description = ${connection.escape(cat.description)}, image = ${connection.escape(cat.image)} where id = ${connection.escape(cat.id)}`);
    } else {
        await connection.query(`insert into cats (name, description, image) values (${connection.escape(cat.name)}, ${connection.escape(cat.description)}, ${connection.escape(cat.image)})`);
    }
    res.redirect("/");
})

const detailsPage = (isNew, cat, error) => `
<!DOCTYPE html>
<html lang="en">
${head(isNew ? "New Cat" : cat?.name)}
<body class="container">
    <script>
        function deleteCat(p) {
            var xhr = new XMLHttpRequest();
            xhr.open("DELETE", p);
            xhr.onreadystatechange = function() {
                if (this.readyState == 4 && this.status == 200) {
                    window.location.replace("/");
                }
            };
            xhr.send();
        }
    </script>
    <div class="row g-3">
        <div class="col-12 col-md-6">
            ${isNew ? `
                <h1>New Cat</h1>
            ` : `
                <h1>${cat.name}</h1>
                <p>${cat.description}</p>
            `}
            <form action="/" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="id" id="id" value="${cat?.id || 0}">
                <label for="name" class="form-label">Name</label>
                <input type="text" value="${cat?.name || ""}" name="name" id="name" class="form-control">
                <label for="description" class="form-label">Description</label>
                <textarea name="description" id="description" class="form-control">${cat?.description || ""}</textarea>
                <label for="image" class="form-label">Image</label>
                <input type="file" accept=".png,.jpg,.jpeg" id="image" name="image" class="form-control">
                ${error ? `<p class="text-danger">${error}</p>` : ``}
                <div class="row align-items-end gap-3">
                    <input type="submit" class="btn btn-outline-primary col g-3" value="save">
                    ${cat?.id ? `<button type="button" onclick="deleteCat('/${cat.id}')" class="btn btn-outline-danger col g-3">delete</button>`: ''}
                </div>
            </form>
        </div>
        <div class="col-12 col-md-6">
            ${cat?.image ? `<img src="${cat.image}" class="img-thumbnail" alt="${cat.name}"></img>` : ''}
        </div>
    </div>
</body>
</html>
`

app.get("/images/*", async (req, res) => {
    try {
        const buffer = fs.readFileSync(`${__dirname}${req.url}`);
        res.send(buffer);
    } catch (e) {
        const image = await (await fetch("http://http.cat/404")).blob();
        res.send(Buffer.from(await image.arrayBuffer()));
    }
})

app.get("/new", (req, res) => res.send(detailsPage(true, {
    name: req.query?.name,
    description: req.query.description
}, req.query?.error)))

app.get("/:id", async (req, res) => {
    const results = (await connection.query(`select * from cats where id = ${connection.escape(req.params.id)}`))[0];
    if (!results.length) {
        res.status(404).send(notFound());
        return;
    }
    res.send(detailsPage(false, results[0], req.params?.error));
})

app.delete("/:id", async (req, res) => {
    const cat = await getCat(req.params.id);
    if (!cat) {
        res.status(404).send(notFound());
        return;
    }
    try {
        fs.rmSync(`${__dirname}/${cat.image}`);
    } catch (e) {
        console.error(e);
    }
    await connection.query(`delete from cats where id = ${connection.escape(req.params.id)}`);
    res.send();
})

app.listen(80, () => console.log("listening..."))
