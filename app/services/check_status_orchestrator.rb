class CheckStatusOrchestrator
  RequestContext = Data.define(:idfa, :rooted_device, :country, :ip)

  def initialize(
    country_check: Checks::CountryWhitelistCheck.new,
    rooted_check: Checks::RootedDeviceCheck.new,
    vpn_check: Checks::VpnApiCheck.new,
    logger: IntegrityLogger.new
  )
    @country_check = country_check
    @rooted_check = rooted_check
    @vpn_check = vpn_check
    @logger = logger
  end

  def call(context)
    user = User.find_by(idfa: context.idfa)
    return "banned" if user&.banned?

    ban_status, metadata = run_checks(context)
    log_event(user, context, ban_status, metadata)

    if user
      user.update!(ban_status: ban_status) if user.ban_status != ban_status
    else
      User.create!(idfa: context.idfa, ban_status: ban_status)
    end

    ban_status
  end

  private

  def run_checks(context)
    metadata = {
      ip: context.ip,
      rooted_device: context.rooted_device,
      country: context.country,
      proxy: nil,
      vpn: nil
    }

    country_result = @country_check.call(country: context.country)
    metadata[:country] = country_result.metadata[:country]
    return ["banned", metadata] if country_result.banned?

    rooted_result = @rooted_check.call(rooted_device: context.rooted_device)
    return ["banned", metadata] if rooted_result.banned?

    vpn_result = @vpn_check.call(ip: context.ip)
    metadata[:proxy] = vpn_result.metadata[:proxy]
    metadata[:vpn] = vpn_result.metadata[:vpn]
    return ["banned", metadata] if vpn_result.banned?

    ["not_banned", metadata]
  end

  def log_event(user, context, ban_status, metadata)
    if user.nil?
      @logger.log(build_log_event(context, ban_status, metadata))
    elsif user.ban_status != ban_status
      @logger.log(build_log_event(context, ban_status, metadata))
    end
  end

  def build_log_event(context, ban_status, metadata)
    {
      idfa: context.idfa,
      ban_status: ban_status,
      ip: metadata[:ip],
      rooted_device: metadata[:rooted_device],
      country: metadata[:country],
      proxy: metadata[:proxy],
      vpn: metadata[:vpn]
    }
  end
end
