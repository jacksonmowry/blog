module main

import vweb
import db.sqlite

struct App {
	vweb.Context
pub mut:
	db        sqlite.DB
	user_id   string
	logged_in bool
}

fn main() {
	mut app := &App{
		db: sqlite.connect(':memory:') or { panic(err) }
		// db: sqlite.connect('blog.db') or { panic(err) }
	}

	sql app.db {
		create table Article
		create table Comment
		create table User
	} or { println('cannot create tables in db') }

	vweb.run(app, 8081)
}

['/index']
pub fn (app &App) index() vweb.Result {
	articles := app.find_all_articles()
	return $vweb.html()
}

['/latest']
pub fn (app &App) latest() vweb.Result {
	article := app.find_latest_article() or { Article{} }
	return $vweb.html()
}

['/article/:id']
pub fn (app &App) article(id int) vweb.Result {
	article := app.find_article_by_id(id) or { Article{} }
	return $vweb.html()
}

['/author/:name']
pub fn (mut app App) author(name string) vweb.Result {
	articles := app.find_articles_by_author(name) or { []Article{} }
	if articles.len == 0 {
		app.redirect('/')
	}
	return $vweb.html()
}

['/new']
pub fn (mut app App) new() vweb.Result {
	if !app.logged_in {
		return app.redirect('/login')
	}
	return $vweb.html()
}

['/signup'; get]
pub fn (mut app App) signup() vweb.Result {
	if app.logged_in {
		return app.redirect('/')
	}
	return $vweb.html()
}

['/signup_form'; post]
pub fn (mut app App) signup_form(username string, display_name string, password string) vweb.Result {
	if app.logged_in {
		return app.redirect('/')
	}
	if username == '' || display_name == '' || password == '' {
		return app.text('Empty/Invalid Field')
	}

	user := User{
		uname: username
		dname: display_name
		pword: password
	}

	println(user)
	sql app.db {
		insert user into User
	} or { return app.text('Username already exists') }

	app.set_cookie(name: 'login', value: 'true')
	return app.redirect('/')
}

['/login'; get]
pub fn (mut app App) login() vweb.Result {
	if app.logged_in {
		return app.redirect('/')
	}
	return $vweb.html()
}

['/login_form'; post]
pub fn (mut app App) login_form(username string, password string) vweb.Result {
	if app.logged_in {
		return app.redirect('/')
	}
	if username == '' || password == '' {
		return app.text('Empty/Invalid Field')
	}

	user := sql app.db {
		select from User where uname == username limit 1
	} or { return app.redirect('/login') }

	if user[0].pword != password {
		app.redirect('/login')
	}

	app.set_cookie(name: 'login', value: 'true')
	return app.redirect('/')
}

['/signout']
pub fn (mut app App) signout() vweb.Result {
	app.set_cookie(name: 'login', value: 'false')
	return app.redirect('/')
}

['/new_article'; post]
pub fn (mut app App) new_article(title string, text string, author string) vweb.Result {
	if !app.logged_in {
		return app.redirect('/login')
	}
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
	} or { return app.server_error(500) }
	return app.redirect('/')
}

['/new_comment'; post]
pub fn (mut app App) new_comment(article_id int, author string, text string) vweb.Result {
	if !app.logged_in {
		return app.redirect('/login')
	}
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
	} or { return app.server_error(500) }
	return app.redirect('/article/${article_id}')
}

pub fn (mut app App) before_request() {
	login_p := app.get_cookie('login') or { '0' }
	app.logged_in = login_p == 'true'
}
