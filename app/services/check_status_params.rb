class CheckStatusParams
  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  attr_reader :errors, :idfa, :rooted_device

  def initialize(errors:, idfa: nil, rooted_device: nil)
    @errors = errors
    @idfa = idfa
    @rooted_device = rooted_device
  end

  def valid?
    errors.empty?
  end

  def self.from_params(params)
    errors = []
    idfa = params[:idfa]
    rooted_device = params[:rooted_device]

    errors << :missing_idfa if idfa.nil?
    errors << :missing_rooted_device unless params.key?(:rooted_device)

    errors << :invalid_idfa if idfa.present? && !UUID_REGEX.match?(idfa.to_s)

    if params.key?(:rooted_device) && ![ true, false ].include?(rooted_device)
      errors << :invalid_rooted_device
    end

    new(errors: errors, idfa: idfa, rooted_device: rooted_device)
  end
end
