class SimpleCache
  def initialize(cache)
    @cache = cache
  end

  def fetch(name, options = nil)
    entry = read(name, options)

    if !entry && block_given?
    	entry = yield
    	write(name, entry)
    elsif !entry
      entry = read(name, options)
    end

    entry
  end

  def read(name, options = nil)
    entry = @cache[name]

    if entry && entry[:expiration] < Time.now
      entry = @cache[name] = nil
    end

    entry ? entry[:value] : entry
  end

  def write(name, value)
    @cache[name] = { :expiration => (Time.now + 60), :value => value }
  end
end
