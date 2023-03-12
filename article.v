module main

struct Article {
	id       int       [primary; sql: serial]
	title    string
	text     string
	comments []Comment [fkey: 'article_id']
	// Add abstract for the link
}

struct Comment {
	id         int    [primary; serial; sql]
	article_id int
	author     string
	text       string
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
