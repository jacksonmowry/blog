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
		db: sqlite.connect('blog.db') or { panic(err) }
	}

	sql app.db {
		create table Article
		create table Comment
		create table User
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
	if !app.logged_in {
		return app.redirect('/login')
	}
	return $vweb.html()
}

['/signup'; get]
pub fn (mut app App) signup() vweb.Result {
	return $vweb.html()
}

['/signup_form'; post]
pub fn (mut app App) signup_form(username string, password string) vweb.Result {
	if username == '' || password == '' {
		return app.text('Empty/Invalid Field')
	}

	user := User{
		uname: username
		pword: password
	}

	sql app.db {
		insert user into User
	} or { return app.text('Username already exists') }

	app.set_cookie(name: 'login', value: 'true')
	return app.redirect('/')
}

['/login'; get]
pub fn (mut app App) login() vweb.Result {
	return $vweb.html()
}

['/login_form'; post]
pub fn (mut app App) login_form(username string, password string) vweb.Result {
	if username == '' || password == '' {
		return app.text('Empty/Invalid Field')
	}

	user := sql app.db {
		select from User where uname == username limit 1
	} or { return app.redirect('/login') }

	if user.pword != password {
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
	}
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
	}
	return app.redirect('/article/${article_id}')
}

pub fn (mut app App) before_request() {
	app.user_id = app.get_cookie('login') or { '0' }
	app.logged_in = app.user_id == 'true'
}
