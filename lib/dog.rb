require 'pry'

class Dog
  attr_accessor :name, :breed, :id

  # ---------- Initialize Dog Object with Hash ----------
  def initialize(id: nil, name:, breed:)
    @id = id
    @name = name
    @breed = breed
  end

  # ---------- SQL config ----------
  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      );
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
      DROP TABLE IF EXISTS dogs
    SQL
    DB[:conn].execute(sql)
  end

  # ---------- Create new Dog Instance from Query results ----------
  def self.new_from_db(row_ary)
    new_dog = self.new(id:row_ary[0], name:row_ary[1], breed:row_ary[2])
  end

  # ---------- Querying DB based on attributes ----------
  def self.find_by_name(name) # a string
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?
    SQL
    #binding.pry
    ary = DB[:conn].execute(sql, name)[0]
    self.new_from_db(ary)
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE id = ?
      LIMIT 1
    SQL
    ary = DB[:conn].execute(sql, id)[0]
    self.new_from_db(ary)
  end

  # ---------- From Dog Object, Updating / Inserting into DB ----------
  def update
    sql = <<-SQL
      UPDATE dogs SET name = ?, breed = ?
      WHERE id = ?
    SQL
    DB[:conn].execute(sql, name, breed, id)
  end

  def save
    if self.id
      self.update
    else
      sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      SQL
      DB[:conn].execute(sql, self.name, self.breed)
      self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
      self
    end
  end

  # ---------- From Dog Class, Updating / Inserting into DB ----------
  def self.create(name:, breed:)
    dog = Dog.new(name: name, breed: breed)
    dog.save
  end

  def self.find_or_create_by(name:, breed:)
    dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
    if !dog.empty?
      dog_data = dog[0]
      dog = self.new_from_db(dog_data)
    else
      dog = self.create(name: name, breed: breed)
    end
    dog
  end
end
