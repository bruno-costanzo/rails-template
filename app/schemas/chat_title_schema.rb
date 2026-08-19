class ChatTitleSchema < Schematist::Schema
  string :title, description: "Concise conversation title, six words maximum"
  array :tags, of: :string, description: "Up to three lowercase topic tags"
end
