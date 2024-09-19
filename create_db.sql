-- Users table
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    password BLOB NOT NULL,
    icon TEXT NOT NULL
);

-- Templates table
DROP TABLE IF EXISTS templates;
CREATE TABLE templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    args TEXT,
    language TEXT NOT NULL,
    raw TEXT NOT NULL,
    date TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Published table
DROP TABLE IF EXISTS published;
CREATE TABLE published (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    numArgs Integer NOT NULL
);

-- Drafts table
DROP TABLE IF EXISTS drafts;
CREATE TABLE drafts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_id INTEGER NOT NULL,
    FOREIGN KEY (template_id) REFERENCES templates(id)
);

-- Versions table
DROP TABLE IF EXISTS versions;
CREATE TABLE versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_id INTEGER NOT NULL,
    creator_id INTEGER NOT NULL,
    published_id INTEGER NOT NULL,
    FOREIGN KEY (template_id) REFERENCES templates(id),
    FOREIGN KEY (creator_id) REFERENCES users(id),
    FOREIGN KEY (published_id) REFERENCES published(id)
);

-- SessionKeys table
DROP TABLE IF EXISTS sessionKeys;
CREATE TABLE sessionKeys (
    key TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
