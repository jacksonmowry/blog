module main

struct Article {
	id    int    [primary; sql: serial]
	title string
	text  string
	// Add abstract for the link
}

pub fn (app &App) find_all_articles() []Article {
	return sql app.db {
		select from Article order by id desc
	}
}

pub fn (app &App) find_latest_article() Article {
	println(app.db.last_id())
	return sql app.db {
		// select from Article where id == app.db.last_id() limit 1
		select from Article order by id desc limit 1
	}
}
