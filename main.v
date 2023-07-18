module main

import net.http
import net.html
import vweb
import db.sqlite
import rand
import crypto.bcrypt
import blog

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
		db: sqlite.connect('db/blog.db') or { panic(err) }
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
	app.serve_static('/output.css', 'output.css')
	//

	vweb.run(app, 8081)
}
