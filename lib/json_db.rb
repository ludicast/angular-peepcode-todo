require 'json'

# An extremely simple key-value store for demo use only.
class JSONDb

  include Enumerable

  def members
    load_data if @@members.length == 0
    @@members
  end

  def initialize(filename)
    @filepath = File.join("tmp", filename)
    @filename = filename
    load_data
  end

  def load_data
    if File.exist? @filepath
      contents = File.open(@filepath).read
      if contents.length > 0
        @@members = JSON.parse(contents)
        return
      end
    end
    @@members = []
  end

  # Add a single document to the database.
  #
  # It will use the record's "id" property if it has one. Otherwise,
  # one will be created on the fly.
  def save_doc obj
    unless obj.has_key?('id')
      obj['id'] = [Time.now.to_i, rand(1000)].join('')
    end
    @@members << obj
    obj
  end

  # Inefficient but functional finder (by id).
  def get id
    @@members.detect {|member| member['id'] == id }
  end

  # Permanently remove a record from the set.
  def delete id
    record = get id
    @@members.delete record
  end

  def each &block
    @@members.each { |member| block.call(member) }
  end

  # Persist the database to disk.
  def save
    File.open(@filepath, 'wb') do |f|
      f.write @@members.to_json
    end
  end

  # Delete the database file and reset the data.
  def delete!
    if File.exist? @filepath
      File.delete @filepath
    end
    @@members = []
  end

end
