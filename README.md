# TVLite Microblog

![ai-generated repo image](tv.jpg)

TVLite📺 is a webstack based on tailwindcss, vlang, and sqlite.

No JavaScript(💩) is used to run any part of the website, meaning only HTML and CSS are shipped to the browser 🔥.

It is feature light, but complete enough for use.

## Deployment Dependencies

### Installing sqlite

If you are on linux sqlite can be installed with you package manager, if this does not work or you are on windows check the link below.

<https://github.com/vlang/v/blob/master/vlib/db/sqlite/README.md>

## Additional Dependencies for Development

### Installing Tailwindcss

Tailwindcss is normally installed via npm, and if you already have it on your machine go ahead with that, but for this project we will just use the standalone cli so we do not inherit a dependency on npm(🤮).

<https://github.com/tailwindlabs/tailwindcss/releases/latest>

From there you can copy the executable to /src/css
```shell
./tailwind -i input.css -o output.css
```
or (if using tailwind from path)
```shell
tailwind -i input.css -o output.css
```

## Deploying the Server

```shell
git clone https://github.com/jacksonmowry/blog.git
cd blog
cd src
v run .
```

## Development and Contribution

### Routes and Logic

To edit or add any routes to the server the `blog.v` file should be edited. All logic can be embedded directly within a route or extracted to the `article.v` file for more reusable code.

### Styling, Layout, and Markup

Using tailwindcss directly within html templates means that all style and layout is described right in the markup. For someone not used to web development (such as myself) this is a much easier paradigm to wrap your head around. Feel free to change up the layout and fix any visual anomalies you may see.

New components can be added by creating a separate html file which is then included using  `@include 'foo.html'`. Data for these components must be made available in the route or directly from the App (context) structure itself. These fields can then be populated into the template using an `@` prefix. Here is a link to the very helpful vweb documentation on templates, <https://github.com/vlang/v/blob/master/vlib/vweb/README.md>

### Running the Server in Development

Lastly, vweb's livereload feature, and the tailwind cli watch feature aid in rapid development.

During the prototyping stage of a new feature I prefer to use the typical `v run .` command because changing functions and routes can cause weird things to happen in the already running binary. 

Then once we move to the design stage of a new feature we can run v from the src directory
```shell
v -d vweb_livereload watch run .
```
and tailwind from the css directory
```shell
./tailwind -i input.css -o output.css --watch
```

These two commands in combination allow for instant refreshing of the webpage any time a change is made to the markup or the css classes applied.