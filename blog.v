module main

import vweb
import db.sqlite
import rand
import crypto.bcrypt

struct App {
	vweb.Context
pub mut:
	db          sqlite.DB
	username    string
	logged_in   bool
	user_struct User
}

fn main() {
	mut app := &App{
		// db: sqlite.connect(':memory:') or { panic(err) }
		db: sqlite.connect('blog.db') or { panic(err) }
	}

	sql app.db {
		create table Article
		create table Comment
		create table User
		create table Likes
		create table Sessions
	} or { println('cannot create tables in db') }

	//
	// Testing
	app.serve_static('/modal_test.css', 'modal_test.css')
	//

	vweb.run(app, 8081)
}

['/index']
pub fn (app &App) index() vweb.Result {
	articles := app.find_all_articles()
	return $vweb.html()
}

['/latest']
pub fn (mut app App) latest() vweb.Result {
	article := app.find_latest_article() or { Article{} }
	liked := app.has_liked(article.id)
	return $vweb.html()
}

['/article/:id']
pub fn (mut app App) article(id int) vweb.Result {
	liked := app.has_liked(id)
	article := app.find_article_by_id(id) or { Article{} }
	return $vweb.html()
}

['/author/:name']
pub fn (mut app App) author(name string) vweb.Result {
	articles := app.find_articles_by_author(name) or { []Article{} }

	// find articles liked by authors id not viewers id
	author := sql app.db {
		select from User where uname == name
	} or { return app.redirect('/') }

	liked := author[0].likes

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

	// hashing password
	hash := bcrypt.generate_from_password(password.bytes(), 10) or {
		return app.text('Password hashing failed')
	}

	user := User{
		uname: username
		dname: display_name
		pword: hash
	}

	sql app.db {
		insert user into User
	} or { return app.text('Username already exists') }

	id_check := sql app.db {
		select from User where uname == username
	} or { return app.server_error(500) }
	id := id_check[0].id

	app.set_cookie(name: 'login', value: 'true')

	uuid := rand.uuid_v4()
	session := Sessions{
		user_id: id
		session_token: uuid
		username: username
	}
	sql app.db {
		insert session into Sessions
	} or {}
	app.set_cookie(name: 'session_token', value: uuid)

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

	if user.len == 0 {
		return app.redirect('/login')
	}
	bcrypt.compare_hash_and_password(password.bytes(), user[0].pword.bytes()) or {
		return app.redirect('/login')
	}

	app.set_cookie(name: 'login', value: 'true')

	uuid := rand.uuid_v4()
	session := Sessions{
		user_id: user[0].id
		session_token: uuid
		username: username
	}
	sql app.db {
		insert session into Sessions
	} or {}
	app.set_cookie(name: 'session_token', value: uuid)
	return app.redirect('/')
}

['/signout']
pub fn (mut app App) signout() vweb.Result {
	session_t := app.get_cookie('session_token') or { '' }
	if session_t == '' {
		return app.redirect('/')
	}
	sql app.db {
		delete from Sessions where session_token == session_t
	} or { return app.redirect('/') }
	app.set_cookie(name: 'login', value: 'false')
	app.set_cookie(name: 'session_token', value: '')
	return app.redirect('/')
}

['/new_article'; post]
pub fn (mut app App) new_article(title string, text string) vweb.Result {
	if !app.logged_in {
		return app.redirect('/login')
	}
	if title == '' || text == '' {
		return app.text('Empty text/title')
	}
	article := Article{
		title: title
		text: text
		author: app.username
	}
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
	if text == '' || article_id == 0 {
		return app.text('Invalid Comment')
	}
	comment := Comment{
		article_id: article_id
		author: app.username
		text: text
	}
	sql app.db {
		insert comment into Comment
	} or { return app.server_error(500) }
	return app.redirect('/article/${article_id}')
}

['/rss']
pub fn (mut app App) rss() vweb.Result {
	articles := app.find_all_articles()
	app.add_header('Content-Type', 'application/xml')
	return $vweb.html()
}

['/rss/:author']
pub fn (mut app App) rssbyauthor(author string) vweb.Result {
	articles := app.find_articles_by_author(author) or { []Article{} }
	app.add_header('Content-Type', 'application/xml')
	return $vweb.html()
}

['/:article_id/up']
pub fn (mut app App) up(article_id int) vweb.Result {
	articles_liked := app.user_struct.likes

	for like in articles_liked {
		if like.article_id == article_id {
			sql app.db {
				delete from Likes where username == app.username && article_id == article_id
			} or { return app.text('removing like did not work') }

			sql app.db {
				update Article set likes = likes - 1 where id == article_id
			} or { return app.text('reducing like did not work') }
			return app.redirect('/article/${article_id}')
		}
	}

	like := Likes{
		user_id: app.user_struct.id
		username: app.username
		article_id: article_id
	}
	sql app.db {
		insert like into Likes
	} or { return app.text('adding like ref failed') }
	sql app.db {
		update Article set likes = likes + 1 where id == article_id
	} or { return app.text('upping like count failed') }
	return app.redirect('/article/${article_id}')
}

pub fn (mut app App) before_request() {
	// login_p := app.get_cookie('login') or { '0' }
	// app.logged_in = login_p == 'true'
	session_t := app.get_cookie('session_token') or { '' }
	session := sql app.db {
		select from Sessions where session_token == session_t limit 1
	} or { []Sessions{} }
	if session.len == 0 || session_t != session[0].session_token {
		app.logged_in = false
	} else {
		app.username = session[0].username
		app.logged_in = true
	}

	user_struct := sql app.db {
		select from User where uname == app.username
	} or { panic('sql bork') }
	if user_struct.len > 0 {
		app.user_struct = user_struct[0]
	}
}
