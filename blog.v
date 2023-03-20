module main

import vweb
import db.sqlite

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
		create table Comment
	}

	vweb.run(app, 8081)
}

['/index']
pub fn (app &App) index() vweb.Result {
	articles := app.find_all_articles()
	return $vweb.html()
}

['/latest']
pub fn (app &App) latest() vweb.Result {
	article := app.find_latest_article()
	return $vweb.html()
}

['/article/:id']
pub fn (app &App) article(id int) vweb.Result {
	article := app.find_article_by_id(id)
	return $vweb.html()
}

['/new']
pub fn (mut app App) new() vweb.Result {
	return $vweb.html()
}

['/new_article'; post]
pub fn (mut app App) new_article(title string, text string, author string) vweb.Result {
	if title == '' || text == '' || author == '' {
		return app.text('Empty text/title')
	}
	article := Article{
		title: title
		text: text
		author: author
	}
	println('posting article')
	println(article)
	sql app.db {
		insert article into Article
	}
	return app.redirect('/')
}

['/new_comment'; post]
pub fn (mut app App) new_comment(article_id int, author string, text string) vweb.Result {
	if author == '' || text == '' || article_id == 0 {
		return app.text('Invalid Comment')
	}
	comment := Comment{
		article_id: article_id
		author: author
		text: text
	}
	println('new comment')
	println(comment)
	sql app.db {
		insert comment into Comment
	}
	return app.redirect('/article/${article_id}')
}

pub fn (mut app App) before_request() {
	app.user_id = app.get_cookie('id') or { '0' }
}
