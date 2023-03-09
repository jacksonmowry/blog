module main

import vweb
import time
import db.sqlite
import json

struct App {
	vweb.Context
pub mut:
	db      sqlite.DB
	user_id string
}

fn main() {
	mut app := &App{
		db: sqlite.connect('blog.db') or { panic(err) }
	}

	sql app.db {
		create table Article
	}

	first_article := Article{
		title: 'Hello, world!'
		text: 'V is great. This is a second sentence to test how text wrapping works'
	}

	second_article := Article{
		title: 'Second post'
		text: 'Hm. . . '
	}

	sql app.db {
		insert first_article into Article
		insert second_article into Article
	}

	vweb.run(app, 8081)
}

['/index']
pub fn (app &App) index() vweb.Result {
	articles := app.find_all_articles()
	return $vweb.html()
}

pub fn (mut app App) before_request() {
	app.user_id = app.get_cookie('id') or { '0' }
}

['/new']
pub fn (mut app App) new() vweb.Result {
	return $vweb.html()
}

['/new_article'; post]
pub fn (mut app App) new_article(title string, text string) vweb.Result {
	if title == '' || text == '' {
		return app.text('Empty text/title')
	}
	article := Article{
		title: title
		text: text
	}
	println('posting article')
	println(article)
	sql app.db {
		insert article into Article
	}
	return app.redirect('/')
}

['/articles'; get]
pub fn (mut app App) articles() vweb.Result {
	articles := app.find_all_articles()
	json_result := json.encode(articles)
	return app.json(json_result)
}

fn (mut app App) time() vweb.Result {
	return app.text(time.now().format())
}
