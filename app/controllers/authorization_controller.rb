class AuthorizationController < WebsocketRails::BaseController

  def authorize_channels
    # The channel name will be passed inside the message Hash
    channel = WebsocketRails[message[:channel]]
    if current_user
      accept_channel current_user
    else
      deny_channel({:message => 'authorization failed!'})
    end
  end

  def authorize_message
    # The channel name and channel user_id will be passed inside the message Hash
    if message[:message_body].to_i == current_user.id
      message[:message_body] = message[:message_body] + 'user_' + current_user.id.to_s 
      authorize_peer_message
    else
      deny_peer_message
    end
  end
end