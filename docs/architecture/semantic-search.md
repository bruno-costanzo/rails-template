# Semantic search

`Document` (`app/models/document.rb`) carries an Action Text `content` and a `embedding` vector of `Document::EMBEDDING_DIMENSIONS` floats, declared to Neighbor with `has_neighbors`. `Document.semantic_search` embeds the query through RubyLLM and returns the nearest neighbours by cosine distance. `config/initializers/neighbor.rb` calls `Neighbor::SQLite.initialize!`, which loads the sqlite-vec extension; without it the column is just a blob.

Re-embedding is driven by an `after_save_commit` callback guarded by `embedding_source_changed?`, which asks whether the title or the rich-text body changed. Guarding on the source rather than firing on every save is what stops the loop: the job writes the embedding back with `update!`, which commits again, and an unguarded callback would enqueue itself forever.

`Document::EMBEDDING_DIMENSIONS` is tied to the embedding model. Changing `OPENAI_EMBEDDING_MODEL` to one with a different output size means a migration, which is why the variable is documented in `.env.example` and nowhere else.
