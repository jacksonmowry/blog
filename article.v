module main

struct Article {
	id       int       [primary; sql: serial]
	title    string
	text     string
	author   string
	comments []Comment [fkey: 'article_id']
	// Add abstract for the link
}

struct Comment {
	id         int    [primary; serial; sql]
	article_id int
	author     string
	text       string
}

struct User {
	id    int    [primary; serial; sql]
	uname string [nonull; unique]
	dname string [nonull]
	pword string [nonull]
}

pub fn (app &App) find_all_articles() []Article {
	return sql app.db {
		select from Article order by id desc
	}
}

pub fn (app &App) find_latest_article() Article {
	println(app.db.last_id())
	return sql app.db {
		select from Article order by id desc limit 1
	}
}

pub fn (app &App) find_article_by_id(article_id int) Article {
	return sql app.db {
		select from Article where id == article_id limit 1
	}
}

pub fn (app &App) find_articles_by_author(author string) []Article {
	return sql app.db {
		select from Article where author == author
	}
}
