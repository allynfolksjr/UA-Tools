module NetidTools
  def validate_netid(netid)
    # 8 digits or less
    # can't begin with a number
    # no special symbols
    if netid.length > 8
      nil
    elsif netid !~ /^[a-zA-Z]\w{1,7}$/
      nil
    else
      true
    end
  end
end
