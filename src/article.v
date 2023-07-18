module main

struct Article {
	id         int    [primary; sql: serial]
	title      string
	text       string
	author     string
	link       string
	link_title string
mut:
	views int
pub:
	likes    int
	comments []Comment [fkey: 'article_id']
}

struct Comment {
	id         int    [primary; serial: sql]
	article_id int
	author     string
	text       string
}

struct User {
	id       int        [primary; serial: sql]
	uname    string     [nonull; unique]
	dname    string     [nonull]
	pword    string     [nonull]
	likes    []Likes    [fkey: 'user_id']
	sessions []Sessions [fkey: 'user_id']
}

struct Likes {
	id         int    [primary; sql: serial]
	user_id    int
	username   string
	article_id int
}

struct Sessions {
	id            int    [primary; sql: serial]
	user_id       int
	session_token string [sql_type: 'uuid']
	username      string
}

pub fn (app &App) find_all_articles() []Article {
	articles := sql app.db {
		select from Article order by id desc
	} or { []Article{len: 1} }
	return articles
}

pub fn (mut app App) find_latest_article() ?Article {
	mut article := sql app.db {
		select from Article order by id desc limit 1
	} or { []Article{} }
	if article.len == 0 {
		return none
	}
	app.view(article[0].id)
	article[0].views += 1
	return article[0]
}

pub fn (mut app App) find_article_by_id(article_id int) ?Article {
	app.view(article_id)
	article := sql app.db {
		select from Article where id == article_id limit 1
	} or { []Article{} }
	if article.len == 0 {
		return none
	}
	return article[0]
}

pub fn (app &App) find_articles_by_author(author string) ?[]Article {
	articles := sql app.db {
		select from Article where author == author
	} or { []Article{} }
	if articles.len == 0 {
		return none
	}
	return articles
}

pub fn (app &App) has_liked(id int) bool {
	mut liked := false
	for _, l in app.user_struct.likes {
		if l.article_id == id {
			liked = true
		}
	}

	return liked
}

pub fn (mut app App) view(id int) {
	sql app.db {
		update Article set views = views + 1 where id == id
	} or {}
}
