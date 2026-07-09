class IntegrityLogger
  def initialize(adapter: IntegrityLogging::PostgresAdapter.new)
    @adapter = adapter
  end

  def log(event)
    @adapter.log(event)
  end
end
