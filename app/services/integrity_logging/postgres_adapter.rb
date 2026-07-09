module IntegrityLogging
  class PostgresAdapter
    def log(event)
      IntegrityLog.create!(
        idfa: event.fetch(:idfa),
        ban_status: event.fetch(:ban_status),
        ip: event[:ip],
        rooted_device: event[:rooted_device],
        country: event[:country],
        proxy: event[:proxy],
        vpn: event[:vpn],
        created_at: Time.current
      )
    end
  end
end
